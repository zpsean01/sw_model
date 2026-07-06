# 数据流水线规范

> 本规范定义了本系统（固件质量分析系统）内部的数据流与阶段转换，从固件源码/ELF输入到风险聚合输出的完整路径。

---

## 1 流水线总览

```
系统外部输入                             本系统内部流水线

[固件源码]（.c / .h 源文件）
  └─→ 构建工具（make / cmake）
         └─→ compile_commands.json + ELF
                │
                ├─→ 阶段1: 源码预处理 ──→ 预处理文件 (*.i / *.ii)
                │       └─ 1.0 加载编译数据库（compile_commands.json）
                │       └─ 1.1 宏展开 + 头文件内联（clang -E）
                │       └─ 1.2 保留行号标记（#line）
                │
                ↓
             阶段2: AST 分析 ──→ 源码级结构化知识
              │       └─ 2.1 函数提取（functions.json）
              │       └─ 2.2 调用链提取（call_graph.json）
              │       └─ 2.3 寄存器识别（registers.json）
              │       └─ 2.4 中断向量表（interrupts.json）
              │       └─ 2.5 状态机识别（state_machines.json）
              │       └─ 2.6 全局变量 + 类型（globals.json + types.json）
              │           └─ 外部输入：ELF ──→ 阶段3: ELF 分析
              │                     │        └─ 3.1 符号提取（binary_functions.json）
              │                     │        └─ 3.2 反汇编调用图（call_graph_binary.json）
              │                     │        └─ 3.3 DWARF 分析（globals/types）
              │                     │        └─ 3.4 统一图构建（call_graph_unified.json）
              │                     │
              │                     └───────────┐
              │                                 │
              └───────────┬─────────────────────┘
                          │
                    [spec_model]（外部协议知识库）
                          │
                          ▼
             阶段4: 场景模型 + 安全审计 + 协议一致性
              │       └─ 4.1 事件架构模型（event_architecture.json）
              │       └─ 4.2 安全断言审计（security_report.json）
              │       └─ 4.3 协议一致性检查（protocol_conformance/report.json）
              │
                          ▼
             阶段5: 深度受限符号执行
              │       └─ 5.1 入口点提取（entry_points.json）
              │       └─ 5.2 Hook + SimProcedure 注册（hooks.json + inspect_specs.json）
              │       └─ 5.3 路径探索 + TraceRecorder（traces/）
              │       └─ 5.4 符号执行报告（symbolic_report.json）
              │       └─ 5.5 协议一致性验证（protocol_conformance/report.json）
              │
                          ▼
             阶段6: 风险审计与聚合 ──→ risk_registry.json + residual_risks.json
                      └─ 6.1 风险归并（Stage 4 findings + Stage 5 复现状态）
                      └─ 6.2 风险分类（verified / residual）
                      └─ 6.3 输出注册表 + 遗留风险清单
                              │
                              ▼
                     [下游系统]（测试设计 / HIL / 人工分析）
```

---

## 2 阶段1：源码预处理 (Preprocessor)

C 语言源码的宏展开和头文件内联是后续结构化分析的前提。本阶段输出归一化后的中间源码，消除宏和 `#include` 对 AST 解析的干扰，同时保留原始行号以支持溯源。

### 2.1 步骤明细

| 步骤 | 输入 | 输出 | 关键路径 | 人机交互 | 说明 | 关键算法 |
|------|------|------|---------|---------|------|---------|
| **1.0** 加载编译数据库 | `compile_commands.json` | 编译单元清单（文件路径 + 编译标志） | 是 | 无 | 解析 CMake / Make 输出的编译数据库，获取每个源文件的完整编译标志集合，包括 include 路径、宏定义、优化级别 | JSON 解析 |
| **1.1** 宏展开 + 头文件内联 | 编译单元清单 | 预处理文件 `.i` / `.ii` | 是 | 无 | 调用 clang -E 对每个编译单元执行预处理，展开所有 `#define`、内联所有 `#include`，输出单个归一化文件。使用 `-fretain-comments-from-system-headers` 保留关键系统头文件的语义注释 | clang -E 预处理 |
| **1.2** 保留行号标记 | 预处理文件 | 带行号标记的归一化源码 | 否 | 无 | 确保预处理器输出中包含 `#line` 标记，使后续 AST 分析能追溯到原始源文件的行号。这是质量分析的核心要求——发现的问题必须关联到原始源码位置 | clang -P 禁用 + `#line` 保留 |

### 2.2 说明

预处理是编译器的标准功能，本阶段不做任何源码修改或变换。核心工程决策是**保留行号**——预处理默认输出不包含原始源位置（`-P` 标志），但这对质量分析是不可接受的。预处理阶段强制保留 `#line` 行号标记，使后续 AST 分析能追溯问题到原始源码文件和行号。

---

## 3 阶段2：AST 分析 (AST Analysis)

编译器只关心能否生成目标码，不会告诉我们哪些函数调用了哪些函数、哪些全局变量被哪些函数读写、哪些内存地址被当作寄存器操作。本阶段从归一化源码中提取这些语义信息，将源码文本转化为可查询的结构化数据。

### 3.1 步骤明细

| 步骤 | 输入 | 输出 | 关键路径 | 人机交互 | 说明 | 关键算法 |
|------|------|------|---------|---------|------|---------|
| **2.1** 函数提取 | 预处理文件 | `functions.json` | 是 | 无 | 遍历 AST 中所有 CursorKind.FUNCTION_DECL 节点，提取函数名、返回值类型、参数列表、直接调用列表、文件路径。记录 `calls[]` 列表形成调用关系 | AST 遍历 + 节点筛选 |
| **2.2** 调用链提取 | 预处理文件 + functions | `call_graph.json` | 是 | 无 | 从 AST 识别函数调用表达式（CallExpr），建立调用方→被调用方有向边。保留多重边（同一调用点在不同上下文中的多次调用） | AST 调用表达式匹配 |
| **2.3** 寄存器识别 | 预处理文件 | `registers.json` | 是 | 无 | 识别 `*(volatile uintXX_t *)ADDR` 模式的内存访问，以及 PERIPH_BASE + OFFSET 宏展开后的寄存器定义。记录变量名、类型、地址、行号 | 指针解引用模式匹配 |
| **2.4** 中断向量表提取 | 预处理文件 + ELF 符号表 | `interrupts.json` | 是 | 无 | 识别 `__attribute__((interrupt))` 标注的函数、中断向量表数组定义、NVIC 优先级配置宏。记录 ISR 函数名、向量号、优先级 | 属性标注匹配 + 向量表数组检测 |
| **2.5** 状态机识别 | 预处理文件 | `state_machines.json` | 是 | 无 | 识别 `enum + switch` 模式构成的状态机：枚举定义（状态集）+ switch-case 结构（转换表）。记录状态名、转换关系、所属文件 | enum + switch 模式检测 |
| **2.6** 全局变量 + 类型 | 预处理文件 | `globals.json` + `types.json` | 否 | 无 | 提取全局变量定义（排除 static local）和类型定义（struct/union/enum/typedef）。全局变量清单用于后续并发冲突分析 | AST 声明节点遍历 |

### 3.2 引擎选择策略

首选 **libclang**（通过 clang Python 绑定），能正确处理复杂宏展开、属性标注、内联汇编。备用 **tree-sitter**，适用于 libclang 安装不可用的环境，但 tree-sitter 不做语义分析，无法区分变量声明和函数调用。

---

## 4 阶段3：ELF 分析 (ELF Binary Analysis)

AST 分析有两个固有盲区：编译器优化会改变实际的函数调用关系（内联、尾调用优化）；间接调用（函数指针）在 AST 层面无法确定目标函数。ELF 分析从编译后的二进制出发，看到的是编译器最终生成的指令序列，不受宏和优化的干扰。

### 4.1 步骤明细

| 步骤 | 输入 | 输出 | 关键路径 | 人机交互 | 说明 | 关键算法 |
|------|------|------|---------|---------|------|---------|
| **3.1** 符号提取 | ELF 文件 | `binary_functions.json` | 是 | 无 | 从 ELF 符号表（.symtab / .dynsym）提取函数符号，包括地址、大小、绑定类型（local/global）。使用 DWARF 调试信息补充函数名和行号映射 | ELF 符号表解析 |
| **3.2** 反汇编调用图 | ELF 文件 | `call_graph_binary.json` | 是 | 无 | 通过反汇编识别分支指令（BL / BLX / BX reg），建立二进制级调用图。优先使用 angr CFGFast（支持间接跳转解析），不可用时降级到 capstone 仅识别直接调用 | 控制流分析（CFG） |
| **3.3** DWARF 分析 | ELF 文件 | `globals.json`（二进制补充）+ `types.json`（二进制补充） | 否 | 无 | 从 DWARF 调试信息提取全局变量的地址、类型、大小。与 AST 提取的全局变量交叉验证：同一变量名但地址不一致时产生告警 | DWARF 信息解析 |
| **3.4** 统一图构建 | 静态调用图 + 二进制调用图 + 寄存器清单 | `call_graph_unified.json`（MultiDiGraph） | 是 | 无 | 合并静态调用图和二进制调用图为统一图：函数节点来自两图，寄存器节点加入统一图。边类型为 `calls`（调用关系）、`contains`（层级包含）、`flow`（数据流）。同一对节点允许多条边（MultiDiGraph） | 图合并（并集）+ 寄存器节点注入 |

### 4.2 统一图的设计意图

统一图是本系统所有后续分析的基础中间表示。函数与寄存器共同构成了固件与硬件交互的完整画面——函数代表逻辑，寄存器代表物理接口。两类节点共存于同一图中，边表示调用关系或数据依赖。

调用图构建策略：

| 场景 | 策略 | 适用条件 |
|------|------|----------|
| angr 可用 | angr CFGFast —— 符号执行 + 数据流分析解析函数边界和间接跳转 | 大多数开发/分析环境 |
| angr 不可用 | capstone 反汇编 + 符号表识别 BL/BLX 指令，仅识别直接调用 | 受限环境或快速分析 |

---

## 5 阶段4：场景模型构建与安全审计 (Scenario Modeling & Security Audit)

Stage 2 和 Stage 3 产出了大量的离散信息（函数、调用链、寄存器、状态机），但未回答固件层面的核心问题：哪些场景是关键的？每个场景的行为是否符合预期？

本阶段建立固件的场景模型（中断驱动的事件架构），在此之上叠加安全断言审计和协议一致性检查——将固件实现与外部协议规范（spec_model）进行比对。

### 5.1 步骤明细

| 步骤 | 输入 | 输出 | 关键路径 | 人机交互 | 说明 | 关键算法 |
|------|------|------|---------|---------|------|---------|
| **4.1** 事件架构建模 | `interrupts.json` + `call_graph_unified.json` | `event_architecture.json` | 是 | 无 | 以 ISR 作为"触发事件"，通过调用图传播每个 ISR 可触达的函数集合，形成 `{触发事件, 调用路径}` 的二维模型。统计 ISR 总数、ISR 列表、各 ISR 可达函数集合 | 调用图 BFS 传播 |
| **4.2** 安全断言审计 | `functions.json` + `registers.json` + `state_machines.json` + `call_graph_unified.json` + `globals.json` | `security_report.json` | 是 | 无 | 在场景模型上执行 7 类断言检查：中断优先级冲突、临界区保护缺失、栈深度超阈值、未初始化全局变量、重入风险、状态机完整性、状态机完备性。每条 finding 含 type/severity/message/location | 图模式匹配 + 断言引擎 |
| **4.3** 协议一致性检查 | `security_report.json`（findings） + `spec_model`（外部） | `{protocol}_{version}/protocol_conformance/report.json` | 是 | 无 | 从 spec_model 提取协议知识（寄存器合法值、时序约束、状态机预期表），与 Stage 4 的固件分析结果比对。产出 5 类协议发现：`register_config_audit`（寄存器值范围）、`timing_constraint_audit`（时序约束）、`state_machine_completeness`（状态覆盖）、`error_handling_coverage`（错误恢复）、`cross_register_dependency`（跨寄存器依赖）。同时合并 findings 到 `security_report.json`。输出文件使用时间戳双副本（`report_YYYYMMDD_HHMMSS_fff.json` 快照 + `report.json` latest） | 协议模型比对（值范围/状态集/依赖表达式匹配） |

### 5.2 场景模型维度

| 维度 | 方法 | 输出 |
|------|------|------|
| 中断映射 | 将 ISR 符号与中断向量表地址关联，确定每个中断的触发路径 | 场景的**触发事件**维度 |
| 事件注册表 | 识别回调注册模式（如 `register_callback`、`NVIC_SetPriority`） | 场景的**调用路径**入口 |
| 状态机模型 | 将 Stage 2 识别的状态机与对应的事件处理函数关联 | 场景的**状态上下文**维度 |
| 数据流图 | 在统一图上追踪全局变量的读写函数集合 | 场景的**资源依赖**维度 |

### 5.3 协议一致性审计类型

| 审计类型 | 分析目标 | 输入数据源 | 断言逻辑 |
|---------|---------|-----------|---------|
| `register_config_audit` | 寄存器配置合法取值 | `functions.json` + `registers.json` + `spec_model.valid_values` | 断言固件写入值在 `range` 或 `enum` 范围内；无 `valid_values` 时默认 `[0, 2^bits_len - 1]` |
| `timing_constraint_audit` | 时序约束合规 | `functions.json` + `spec_model.timing[].min_cycles` | 断言固件等待循环数 ≥ `min_cycles` |
| `state_machine_completeness` | 协议状态覆盖 | `state_machines.json` + `spec_model.expected_states` | 断言固件实现了协议的全部状态 |
| `error_handling_coverage` | 错误处理路径覆盖 | `state_machines.json` + `spec_model.error_recovery_required` | 断言固件包含所需错误恢复路径 |
| `cross_register_dependency` | 跨寄存器依赖顺序 | `functions.json` + `spec_model.cross_dependency` | 解析跨寄存器依赖表达式，断言依赖条件满足 |

### 5.4 与 spec_model 的对接

> **当前状态**：sw_model 作为 spec_model 的消费者，当前消费以下子集：`registers[].fields[].valid_values`、`behavior_constraints.timing`、`behavior_constraints.state_machines`、`registers[].cross_dependency`。其余字段（operations、parameters、guards 等）为未来扩展预留。

**版本一致性**：spec_model 的 `metadata.protocol` / `metadata.version` 必须在各阶段间保持一致，并与数据目录名 `{protocol}_{version}` 匹配。不匹配时流水线应产生告警。

**数据路径**：协议版本化副本写入 `data/modeling/{protocol}_{version}/protocol_conformance/report.json`，同时保存带毫秒时间戳的快照副本。

---

## 6 阶段5：深度受限符号执行 (Depth-Limited Symbolic Execution)

前四个阶段都是静态分析——不执行固件，仅从源码和二进制中推导信息。静态分析的固有缺陷是误报：分析出的危险路径可能在运行时因输入条件不满足而实际不可达。

符号执行通过将固件二进制加载到符号执行引擎（angr）中，用符号值代替具体输入，探索固件在所有可能输入下的执行路径，验证 Stage 4 的静态断言是否可复现。

### 6.1 步骤明细

| 步骤 | 输入 | 输出 | 关键路径 | 人机交互 | 说明 | 关键算法 |
|------|------|------|---------|---------|------|---------|
| **5.1** 入口点提取 | Stage 4 `security_report.json` + `call_graph_unified.json` + 配置文件 | `entry_points.json` | 是 | 无 | 从 Stage 4 报告中提取 `findings[].location.function` 作为符号执行入口函数。优先级：配置文件显式指定 > Stage 4 自动提取。通过调用图 BFS 确定每个入口点的边界函数集 | `extract_entry_points_from_report()` + 调用图 BFS |
| **5.2** Hook + Inspect 注册 | `entry_points.json` + 配置文件（hooks / inspect_specs） + `call_graph_unified.json` | `hooks.json`（HookSpec 快照）+ `inspect_specs.json`（InspectSpec 快照） | 是 | 无 | HookLibrary 根据入口点和边界函数自动生成 SimProcedure：`symbolic_return`（返回无约束符号值）、`concrete_stub`（返回范围中点具体值）、`summary`（执行预定义摘要）。InspectSpec 为每个 Hook 赋予风险语义（risk_level + risk_tags + return_range） | HookLibrary.auto_generate_hooks() + 调用图 BFS |
| **5.3** 路径探索 + TraceRecorder | ELF + hooks + inspect_specs | `traces/trace_{func}.json` + `traces/trace_{func}.md` | 是 | 无 | 对每个入口点：解析 ELF 获取入口地址 → 创建 angr Project → 注册 SimProcedure Hook → `call_state(addr)` → `simgr.run()`。TraceRecorder 同步记录事件流水（entry_start / hook_triggered / symbolic_var_created / finding / branch / entry_end），每条记录含符号变量、路径约束、寄存器快照 | angr 符号执行引擎 + 路径探索（veritesting） |
| **5.4** 符号执行报告 | `traces/` + entry_results | `symbolic_report.json` | 是 | 无 | 汇总所有入口点的执行结果：状态（completed/skipped/no_hooks/error）、InspectTrigger 记录数、风险分布统计（warning/critical/unknown）。每条 `entry_result` 独立保存为 `entry_results/{function_name}.json` | 结果汇总 + 风险统计 |
| **5.5** 协议一致性验证 | `symbolic_report.json` + `spec_model` | `{protocol}_{version}/protocol_conformance/report.json` | 是 | 无 | 将符号执行中触发的 InspectTrigger 记录与 spec_model 协议约束比对：寄存器写入值是否在合法范围内、时序参数是否满足。输出报告使用时间戳双副本（快照 + latest） | Inspect 触发值 vs spec_model 合法值 |

### 6.2 路径爆炸的应对策略

| 策略 | 方法 | 适用场景 |
|------|------|----------|
| **目标导向** | 只从 Stage 4 告警地址出发进行后向切片，缩小探索范围 | 大多数场景 |
| **深度限制** | 设置 `max_depth`（默认 3 层），超出则标记为"未验证" | 路径数量可控的场景 |
| **Veritesting** | angr 混合执行模式，在动态执行和符号执行间切换 | 路径数量中等的场景 |
| **超时保护** | 全局超时（默认 300 秒），超时标记为 "timeout" | 所有场景 |

### 6.3 架构示意

```
Stage 4 报告                   配置文件
  │                              │
  ├─ findings[].location.function──► entry_points
  │                              ├── hooks (HookSpec, 机制)
  │                              └── inspect_specs (InspectSpec, 语义)
  └──────────────────────────────┤
                                 │
  call_graph_unified.json ──────► HookLibrary  ──► auto_generate_hooks()
                                 │                      │
                                 ▼                      ▼
                          boundary functions set
                                 │
                                 ▼
  ┌─────────────────────────────────────────┐
  │  per entry_point:                       │
  │    1. resolve entry address (ELF sym)   │
  │    2. apply hooks (HookSpec → SimProc)  │
  │    3. record trace (TraceRecorder)      │
  │    4. call_state(entry_addr) → simgr    │
  │    5. collect InspectTrigger records    │
  └─────────────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────────┐
  │  InspectTrigger[]                       │
  │  + traces/ (结构化事件流 + 复现日志)      │
  └─────────────────────────────────────────┘
           │
           ├──► symbolic_report.json              (汇总)
           ├──► entry_results/{func}.json          (逐入口点详情)
           ├──► hooks.json + inspect_specs.json    (配置快照)
           ├──► entry_points.json                  (入口点配置)
           └──► {protocol}_{version}/protocol_conformance/report.json
```

---

## 7 阶段6：风险审计与聚合 (Risk Audit & Aggregation)

风险的消除方向：**静态识别（Stage 4）→ 符号执行验证（Stage 5）→ 风险聚合输出（Stage 6）→ 下游动态测试设计**。

Stage 6 **不做测试用例生成**——测试用例设计是下游系统的职责。Stage 6 只做聚合记录、风险分类和如实输出。

### 7.1 步骤明细

| 步骤 | 输入 | 输出 | 关键路径 | 人机交互 | 说明 | 关键算法 |
|------|------|------|---------|---------|------|---------|
| **6.1** 风险归并 | Stage 4 `protocol_conformance/report.json` + Stage 4 `security_report.json` + Stage 5 `symbolic_report.json` | 初步风险清单 | 是 | 无 | 加载 Stage 4 协议一致性发现作为初始风险清单，补充 security_report 中的安全/质量类风险。每条风险记录其 source（stage4/stage5）、finding_ref、risk_type、severity、location | 多源数据合并 + finding 去重 |
| **6.2** 风险分类 | 初步风险清单 + Stage 5 `symbolic_report.json` + `traces/` | 分类后的风险清单（verified vs residual） | 是 | 无 | 将 Stage 5 的 InspectTrigger 记录按 `entry_function` 与 Stage 4 findings 的 `location.function` 匹配。匹配成功 → verified（含 verification.trace_file/constraints/register_snapshot）；匹配失败 → residual（含 residual_reason: no_entry_point / symbolic_timeout / path_not_reproduced / static_only） | 函数名匹配 + 路径复现判定 |
| **6.3** 输出风险注册表 | 分类后的风险清单 | `risk_registry.json` + `residual_risks.json` | 是 | 无 | 输出两份文件：`risk_registry.json`（完整风险注册表，含 summary.total_risks/verified/residual/severity_distribution）`residual_risks.json`（仅 status="residual" 的条目，含 residual_reason）。均使用时间戳双副本（快照 + latest） | 筛选 + 排序 + 序列化 |

### 7.2 风险验证匹配逻辑

```
for each Stage 4 finding f:
  func = f.location.function

  if func in Stage 5 verified_functions:
    status = "verified"
    verification = {
      entry_function, trace_file,
      constraints, register_snapshot
    }

  elif func in Stage 5 entry_functions (但无 triggers):
    status = "residual"
    residual_reason = "path_not_reproduced"

  else:
    status = "residual"
    residual_reason = "no_entry_point" | "static_only"
```

### 7.3 输出与下游消费约定

| 产出 | 消费方 | 消费方式 | 说明 |
|------|-------|---------|------|
| `risk_registry.json` | 动态测试设计工具 | 按 severity/status 优先级排序，自行设计测试序列 | verified 风险有 trace 可复现上下文；residual 风险需额外探索 |
| `residual_risks.json` | HIL 测试平台 | 读取 `register_config_audit` 类风险，转化为硬件引脚驱动序列 | 关注寄存器越界写入等可硬件验证的风险 |
| `risk_registry.json` + `traces/` | 人工测试分析 | 完整证据链，测试人员据此编写测试用例 | trace 中的 symbolic vars 和 constraints 可直接指导输入设计 |

> **与 arm_agi_cpu（下游测试设计系统）的关系**：arm_agi_cpu 以**行为空间图**为核心输入，在图上做路径枚举和覆盖分析。sw_model 的 `risk_registry.json` 可作为 arm_agi_cpu 覆盖分析的参考输入（标记哪些操作/约束值得优先覆盖），但需要定义转换层将 flat risk list 映射为行为空间图上的节点/边权重。详见对齐分析报告。

---

## 8 数据依赖总表

| 数据项 | 产生阶段 | 消费阶段 | 置信度 |
|--------|---------|---------|--------|
| `compile_commands.json` | 外部（构建工具） | 阶段1 | 高：构建系统直接产出 |
| ELF 文件 | 外部（构建工具） | 阶段3, 阶段5 | 高：构建系统直接产出 |
| `spec_model` | 外部（协议知识系统） | 阶段4, 阶段5 | 中-高：精度依赖外部知识库质量 |
| 预处理文件 `.i` / `.ii` | 阶段1 | 阶段2 | 高：编译器直接产出 |
| `functions.json` | 阶段2 | 阶段4 | 高：AST 直接映射 |
| `call_graph.json`（静态） | 阶段2 | 阶段3（统一图） | 中：无法覆盖间接调用 |
| `registers.json` | 阶段2 | 阶段4 | 中：模式匹配存在遗漏风险 |
| `interrupts.json` | 阶段2 | 阶段4 | 中：依赖中断属性标注完整性 |
| `state_machines.json` | 阶段2 | 阶段4 | 中：enum+switch 模式检测有限 |
| `globals.json` | 阶段2（+阶段3补充） | 阶段4 | 中：AST+ELF 交叉验证提高可信度 |
| `call_graph_binary.json` | 阶段3 | 阶段3（统一图） | 高：二进制 CFG 反映实际执行 |
| `call_graph_unified.json` | 阶段3 | 阶段4, 阶段5 | 高：双源合并交叉验证 |
| `event_architecture.json` | 阶段4 | 前端可视化 | 中：依赖中断映射的完整性 |
| `security_report.json` | 阶段4 | 阶段5（入口点提取）, 阶段6 | 中：静态断言有误报可能 |
| `protocol_conformance/report.json`（modeling） | 阶段4 | 阶段6 | 中：静态比对无法覆盖运行时行为 |
| `entry_points.json` | 阶段5 | 阶段5 | 高：从报告确定性提取 |
| `hooks.json` / `inspect_specs.json` | 阶段5 | 阶段5（快照）, 审计 | 高：配置文件的确定性快照 |
| `traces/*.json` | 阶段5 | 阶段6（验证详情） | 高：符号执行运行时记录 |
| `symbolic_report.json` | 阶段5 | 阶段6 | 中：符号执行受深度/超时限制 |
| `protocol_conformance/report.json`（sym_execution） | 阶段5 | 阶段6 | 中：受 Hook 覆盖度影响 |
| `risk_registry.json` | 阶段6 | 下游系统 | 中：聚合多阶段置信度衰减 |
| `residual_risks.json` | 阶段6 | 下游系统 | 中-低：需要下游额外验证 |

---

## 9 文件命名规则

| 文件 | 命名格式 | 示例 |
|------|---------|------|
| 编译数据库 | `compile_commands.json` | `compile_commands.json` |
| 预处理文件 | `{source_name}.i` / `.ii` | `ddr_init.i` |
| 函数清单 | `functions.json` | `data/static/functions.json` |
| 调用图 | `call_graph.json` / `call_graph_binary.json` | `data/static/call_graph/call_graph.json` |
| 调用图（统一） | `call_graph_unified.json` | `data/modeling/call_graph_unified.json` |
| 寄存器清单 | `registers.json` | `data/static/registers/registers.json` |
| 中断向量表 | `interrupts.json` | `data/static/interrupts/interrupts.json` |
| 状态机 | `state_machines.json` | `data/static/state_machines/state_machines.json` |
| 全局变量 | `globals.json` | `data/static/globals/globals.json` |
| 事件架构模型 | `event_architecture.json` | `data/modeling/event_architecture.json` |
| 安全审计报告 | `security_report.json` | `data/modeling/security_report.json` |
| 协议一致性报告 | `report.json` / `report_YYYYMMDD_HHMMSS_fff.json` | `data/modeling/DDR5_JESD79-5C/protocol_conformance/report_20260622_221338_522.json` |
| 入口点配置 | `entry_points.json` | `data/sym_execution/entry_points.json` |
| Hook 快照 | `hooks.json` | `data/sym_execution/hooks.json` |
| Inspect 快照 | `inspect_specs.json` | `data/sym_execution/inspect_specs.json` |
| 符号执行报告 | `symbolic_report.json` | `data/sym_execution/symbolic_report.json` |
| 逐入口点详情 | `{function_name}.json` | `data/sym_execution/entry_results/_state_vref_train.json` |
| Trace（JSON） | `trace_{function_name}.json` | `data/sym_execution/traces/trace_ddr5_train_vref_dq.json` |
| Trace（MD） | `trace_{function_name}.md` | `data/sym_execution/traces/trace_ddr5_train_vref_dq.md` |
| 风险注册表 | `risk_registry.json` / `risk_registry_YYYYMMDD_HHMMSS_fff.json` | `data/risks/DDR5_JESD79-5C/protocol_conformance/risk_registry_20260622_221338_522.json` |
| 遗留风险清单 | `residual_risks.json` / `residual_risks_YYYYMMDD_HHMMSS_fff.json` | `data/risks/DDR5_JESD79-5C/protocol_conformance/residual_risks_20260622_221338_522.json` |
| 数据流水线配置 | `data_pipeline_config.json` | `data_pipeline_config.json` |

---

## 10 遗漏问题与上下游对齐差距

> 本节记录当前流水线设计与上游 spec_model（协议知识提取系统）、下游 arm_agi_cpu（测试设计系统）之间的已知对齐差距。按 P0~P3 标注优先级，并映射到具体的阶段和步骤，作为后续完善的入口。

### 10.1 P0 — spec_model 消费深度严重不足

**描述**：当前流水线的阶段4（§5.1 步骤 4.3 协议一致性检查）只消费了 spec_model 的 4 个子集（`valid_values`、`timing`、`state_machines`、`cross_dependency`），而 spec_model Stage 2.3 实际产出了丰富的泛接口操作、参数范围、守卫条件、约束分类和 LLM 推断链等信息。

**影响路径**：阶段4（§5）→ 阶段6（§7）→ 下游系统，消费不足导致协议一致性审计停留在表层。

**映射到本流水线**：

| 缺失的 spec_model 能力 | 影响阶段 | 影响步骤 | 影响程度 |
|------------------------|---------|---------|---------|
| `generalized_interfaces[].operations[].parameters[].range` | 阶段4 | §5.1 步骤 4.3 | 无法验证命令参数合法性 |
| `behavior_constraints.constraints[].discovery_method` | 阶段4 → 阶段6 | §5.1 步骤 4.3 → §7.1 步骤 6.2 | 无法区分确定性约束与 LLM 推断约束的置信度 |
| `behavior_constraints.constraints[].guards[]`（条件守卫） | 阶段4 | §5.1 步骤 4.3 | 条件约束（如"自刷新态tRFC变为2.2µs"）无法验证 |
| `behavior_constraints.constraints[].inference_chain` | 阶段6 | §7.1 步骤 6.3 | 风险注册表无法追溯约束的原始推理证据链 |
| `generalized_interfaces[].signals[]` | 阶段4 | §5.1 步骤 4.1 事件架构建模 | 无法将物理信号与中断/寄存器关联 |
| `state_machines[].expected_transitions[].triggered_operation` + `implied_constraints` | 阶段4 | §5.1 步骤 4.3 | 状态机完备性审计缺少触发操作和关联约束的比对基准 |
| `state_machines[].constraint_refs` | 阶段4 | §5.1 步骤 4.3 | 状态机→约束双向链接丢失 |

**修复方向**：
- `data_model_spec.md` §2 扩展消费子集定义
- 阶段4 `protocol_conformance` 分析器（§5.1 步骤 4.3）增加 operations/parameters/guards 的消费逻辑

---

### 10.2 P1 — Stage 6 输出与 arm_agi_cpu 输入模型不匹配

**描述**：arm_agi_cpu 的核心输入是**行为空间图 G = (V, E, S)**（节点=泛接口操作，边=约束），而本流水线的阶段6（§7）产出的是 flat risk list（`risk_registry.json`），两者抽象层不同。当前 §7.3 的消费约定标注了此 gap，但未定义桥接机制。

**影响路径**：阶段6（§7）→ 下游 arm_agi_cpu，没有语义兼容的接口。

**映射到本流水线**：

| 差距维度 | arm_agi_cpu 输入要求 | 本流水线输出现状 | 影响阶段 | 影响步骤 |
|---------|-------------------|----------------|---------|---------|
| 核心数据结构 | 行为空间图（节点=操作，边=约束，起点集 S） | flat findings 列表 | 阶段6 | §7.1 步骤 6.3 |
| 图遍历入口 | 起点集 S（状态机初始态可执行操作/无入边节点） | 无起点概念 | 阶段6 | §7.1 步骤 6.2 |
| 覆盖分析 | 路径枚举 + 覆盖减法 + 风险评分 | 不适用 | 无对应阶段 | — |
| 用例生成 | 四维用例（序列/数据空间/并发上下文/约束引用） `TcXxx.py` | 不生成 | 无对应阶段 | — |

**修复方向**：
- 新增 **Stage 7（行为空间图转换）**：将 risk_registry + spec_model 映射为 `behavior_space_graph.json`，或
- 增强阶段6，使其输出包含图结构的风险视图

---

### 10.3 P2 — state_machines 模型缺少协议级字段

**描述**：阶段2（§3.1 步骤 2.5 `state_machines.json`）提取固件源码中的 `enum + switch` 状态机，但数据模型缺少协议级语义字段——spec_model 的状态机包含 `triggered_operation`、`implied_constraints`、`constraint_refs`，而本流水线的状态机模型只有 `states` 和 `transitions`。

**影响路径**：阶段2（§3）→ 阶段4（§5 步骤 4.3 状态机完备性审计），比对固件状态机与协议预期状态机时缺少基准字段。

**映射到本流水线**：

| 缺失字段 | 用途 | 影响阶段 | 影响步骤 |
|---------|------|---------|---------|
| `transitions[].trigger` | 触发转移的操作名称 | 阶段4 | §5.1 步骤 4.3 state_machine_completeness |
| `transitions[].triggered_operation` | 触发操作的泛接口引用 | 阶段4 | §5.1 步骤 4.3 |
| `transitions[].implied_constraints` | 转移隐含的约束 ID 列表 | 阶段4 → 阶段5 | §5.1 步骤 4.3 → §6.1 步骤 5.1 入口点提取 |
| `constraint_refs` | 状态机关联的约束 ID 列表 | 阶段4 → 阶段6 | §5.1 步骤 4.3 → §7.1 步骤 6.1 风险归并 |

**修复方向**：
- `data_model_spec.md` §1.5 扩展 `state_machines` 结构，增加 `triggered_operation`、`implied_constraints`、`constraint_refs`
- 阶段2 AST 分析（§3.1 步骤 2.5）增加对这些字段的提取逻辑

---

### 10.4 P2 — 约束模型缺乏 guards（条件守卫）支持

**描述**：spec_model Stage 2.3 定义了完整的守卫边模型（`guards[]` = 条件分支 + `timing_override`），支持 `and` / `or` 复合条件。本流水线的时序约束审计（§5.1 步骤 4.3 `timing_constraint_audit`）只有简单的 `min_cycles` 断言，遇到条件约束时只能跳过或误报。

**影响路径**：阶段4（§5.1 步骤 4.3 协议一致性检查）→ 阶段5（§6.1 步骤 5.5 符号执行验证）→ 阶段6（§7.1 步骤 6.2 风险分类），条件约束的处理能力缺失在整个风险链条上传播。

**映射到本流水线**：

| 缺失能力 | spec_model 提供 | 本流水线当前限制 | 影响阶段 | 影响步骤 |
|---------|---------------|----------------|---------|---------|
| 条件时序约束 | `guards[].condition + timing_override` | 仅支持无条件固定值 | 阶段4 | §5.1 步骤 4.3 timing_constraint_audit |
| 复合条件 | `and` / `or` 嵌套组合 | 不支持 | 阶段4 | §5.1 步骤 4.3 |
| 能力前提约束 | `guards[].condition.type = state_condition` | 不支持 | 阶段4 | §5.1 步骤 4.3 |
| 守卫覆盖验证 | 遍历行为空间图时需要检查守卫可达性 | 不适用 | 无对应阶段 | — |

**修复方向**：
- `data_model_spec.md` §2.4 `behavior_constraints` 增加 `guards[]` 条件守卫结构（含 `condition.type/operator/value`、`timing_override`）
- 阶段4 协议一致性分析器增加 guards 条件的解析和断言逻辑

---

### 10.5 P3 — 固件要素 ↔ 协议要素无显式映射

**描述**：阶段4（§5.1 步骤 4.3）的协议一致性检查隐式假设"固件函数名 ↔ 协议操作名"通过 finding 的 `location.function` + `type` 关联，但 SDK 封装层、函数名差异、编译优化（内联）均可能打断此映射。当前没有运行时显式映射表。

**影响路径**：阶段4（§5）→ 阶段5（§6 入口点提取）→ 阶段6（§7 风险匹配）。映射断裂时，Stage 5 找不到正确的入口函数，Stage 6 的风险匹配失效。

**映射到本流水线**：

| 场景 | 固件侧 | 协议侧 | 映射方式 | 影响阶段 | 影响步骤 |
|------|-------|-------|---------|---------|---------|
| register_config_audit | `registers.json` 变量名（如 `g_ddr_regs`） | `object_entities.registers[].name`（如 `MR6`） | 隐式：通过 finding location + type 推断 | 阶段4 | §5.1 步骤 4.3 |
| timing_constraint_audit | 固件函数中的等待循环 | `behavior_constraints.timing[].parameter`（如 `tMRD`） | 隐式：无字段级映射 | 阶段4 | §5.1 步骤 4.3 |
| state_machine_completeness | `state_machines.json` 固件状态名 | `expected_states` 协议状态名 | 隐式：通过字符串比对 | 阶段4 | §5.1 步骤 4.3 |
| Stage 5 入口函数 | `findings[].location.function`（如 `_state_vref_train`） | `scenarios[].expected_path[].function` | 隐式：字符串匹配 | 阶段5 | §6.1 步骤 5.1 |

**修复方向**：
- `data_model_spec.md` 新增 `fw_to_protocol_mapping.json` 桥接模型定义，包含 `fw_function → protocol_operation`、`fw_register → protocol_register_field`、`fw_state → protocol_state` 映射表
- 阶段4 增加映射加载和验证步骤

---

### 10.6 P3 — 缺乏行为空间概念

**描述**：arm_agi_cpu 以**行为空间图 G = (V, E, S)** 为核心概念驱动覆盖分析；spec_model 的阶段3 以行为空间图构建和场景模板推导为核心产出。本流水线目前没有"行为空间"的概念——阶段4 的事件架构模型是"中断驱动的调用图传播"，阶段5 的符号执行是"二进制路径探索"，都不是在行为空间图上做遍历。

**影响路径**：本流水线 → 下游 arm_agi_cpu，缺少作为桥接的行为空间图（`behavior_space_graph.json`）。

**映射到本流水线**：

| arm_agi_cpu 概念 | 本流水线对应概念 | 差距 | 可能的完善位置 |
|-----------------|----------------|------|-------------|
| V = 泛接口操作 | 固件函数 + 寄存器（`call_graph_unified` 节点） | 未按协议操作语义组织 | 阶段4 或新阶段 |
| E = 约束边 | 固件调用边 + 数据流边 | 未按协议约束分类 | 阶段4 或新阶段 |
| S = 起点集 | 无对应概念 | 未定义 | 新阶段 |
| 场景提取 = 图路径枚举 | 安全断言审计（finding 清单） | 方法论不同 | 新阶段 |
| 覆盖分析 = 路径覆盖度量 | 无对应概念 | 不适用 | 无 |

**修复方向**：
- 新增阶段或增强阶段4，输出 `behavior_space_graph.json`（从 spec_model 的 generalized_interfaces + behavior_constraints 映射），使本流水线产出的行为空间图可被 arm_agi_cpu 直接消费
