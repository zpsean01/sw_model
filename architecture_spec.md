# ARM Firmware Static & Dynamic Analysis Pipeline — Architecture Specification

## 1. Overview

本项目是一个基于 Python 的 ARM 固件分析框架，采用**5 阶段流水线架构**，对已构建的 ARM 固件进行从源码到二进制、从静态到动态的深度分析。每个阶段职责明确、可独立配置和扩展。

### 1.1 前置条件

- 固件工程已完成构建（如 `make`、`cmake --build`）
- 生成 ELF 文件（如 `firmware.elf`）
- 生成 `compile_commands.json`（CMake 项目默认支持，其他项目可用 `bear` / `compiledb` 等工具生成）

### 1.2 总体数据流

```
compile_commands.json  ──→ Stage1 ──→ 预处理后的 .i / .ii 文件
                                  │
                                  ↓
                            Stage2 ──→ AST 分析结果（函数、变量、类型、中断、寄存器、状态机、接口）
                                  │       → call_graph_functions.json
                                  ↓
                            Stage3 ──→ ELF 反汇编分析结果（函数、全局变量、类型）
                                  │       → call_graph_binary.json
                                  ↓
                            Stage4 ──→ 事件驱动架构模型 → 静态安全检查
                                  │       → security_report.json
                                  ↓
                            Stage5 ──→ 动态符号执行（angr） → 路径/漏洞验证
                                          → symbolic_report.json
```

---

## 2. Stage 1 — 源码预处理 (Preprocessor)

### 2.1 作用

根据 `compile_commands.json` 中记录的每个源文件的编译参数，对源码进行预处理（展开宏、包含头文件），同时**保留行号信息**，为后续 AST 分析提供可直接解析的干净输入。

### 2.2 输入

- `compile_commands.json`
- 源码目录树

### 2.3 处理流程

1. 解析 `compile_commands.json`，提取每个源文件的 `command`（或 `arguments`）以及 `directory`
2. 从编译命令中提取预处理相关参数（`-I` 包含路径、`-D` 宏定义、`-m` 架构等）
3. 调用编译器（arm-none-eabi-gcc）执行预处理：`gcc -E -P -C` + 保留行号标志
4. 输出预处理后的 `*.i`（C）或 `*.ii`（C++）文件到指定目录

### 2.4 输出

- `preprocessed/` 目录，包含每个源文件对应的预处理文件
- `preprocessed/manifest.json`：预处理文件与原始文件的映射关系

---

## 3. Stage 2 — AST 分析 (AST Analysis)

### 3.1 作用

对预处理后的源码文件进行**抽象语法树（AST）分析**，提取高层次的程序结构信息。

### 3.2 分析工具

- **主工具**：`libclang`（通过 `clang.cindex` Python 绑定）
- **备选方案**：`tree-sitter`（C 语言 grammar）

### 3.3 提取内容

| 类别 | 说明 | 输出文件 |
|------|------|----------|
| **函数 (Functions)** | 函数签名、起始行号、结束行号、返回值类型、参数列表 | `functions.json` |
| **全局变量 (Globals)** | 变量名、类型、行号、存储类别（static/extern） | `globals.json` |
| **类型 (Types)** | struct / union / enum 定义，包含字段和行号 | `types.json` |
| **中断服务函数 (ISRs)** | 通过 `__attribute__((interrupt))` 或命名规则识别 | `interrupts.json` |
| **寄存器访问 (Registers)** | 检测 `*(volatile uintXX_t *)ADDR` 模式或 `__io` / `__REG` 宏 | `registers.json` |
| **状态机 (State Machines)** | 检测 enum + switch 模式，识别状态变量与状态表 | `state_machines.json` |
| **对外接口 (Interfaces)** | 检测 export 符号、回调注册函数、API 函数前缀 | `interfaces.json` |
| **函数调用链 (Call Graph)** | 从 AST 提取函数间的调用关系 | `call_graph_functions.json` |

### 3.4 函数调用链构建

- 遍历 AST 中每个函数定义内的 `CallExpr` 节点
- 建立 `caller → callee` 映射
- 输出有向图，支持后续进行可达性分析

---

## 4. Stage 3 — ELF 分析 (ELF Binary Analysis)

### 4.1 作用

对编译生成的 ELF 文件进行**二进制级别分析**，提取函数符号、全局变量、类型信息，并构建二进制级别的函数调用链。

### 4.2 分析工具

- **符号/段解析**：`pyelftools`
- **反汇编**：`capstone` (ARM / Thumb / Thumb-2)
- **DWARF 调试信息**：`pyelftools` + `dwarf` 模块

### 4.3 提取内容

| 类别 | 说明 | 输出文件 |
|------|------|----------|
| **函数 (Functions)** | 函数名、起始地址、大小、所属段 | `binary_functions.json` |
| **全局变量 (Globals)** | 符号名、地址、大小、所属段 | `binary_globals.json` |
| **类型 (Types)** | 从 DWARF 调试信息中提取类型定义 | `binary_types.json` |
| **函数调用链 (Call Graph)** | 从反汇编代码中静态分析 BL/BLX 指令 | `call_graph_binary.json` |

### 4.4 函数调用链构建

- 对每个函数的指令序列进行反汇编
- 识别 `BL` / `BLX` 等跳转链接指令
- 解析目标地址对应的符号名（通过 ELF 符号表或重定位表）
- 建立二进制级别的 `caller → callee` 有向图

---

## 5. Stage 4 — 事件驱动架构分析 (Event-Driven Architecture Analysis)

### 5.1 作用

结合 Stage 2 和 Stage 3 的结果，构建固件的事件驱动架构模型，并实施**静态安全检查**。

### 5.2 架构模型构建

1. **中断映射**：将 Stage 2 提取的中断服务函数 ISR 与中断向量表（从 ELF 中提取）进行关联
2. **事件注册表**：识别回调注册模式（如 `register_callback`、`HAL_NVIC_SetPriority` 等）
3. **状态机模型**：将 Stage 2 识别的状态机与对应的事件处理函数关联
4. **数据流图**：构建全局变量 → 读写函数 → 触发事件的完整数据流

### 5.3 静态安全检查项

| 检查项 | 说明 |
|--------|------|
| 中断优先级配置 | 检查是否存在优先级分组不一致 |
| 临界区保护 | 检测中断中访问共享资源时是否关中断/使用信号量 |
| 栈使用分析 | 根据调用链估算最大栈深度 |
| 未初始化全局变量 | 检测全局变量在中断中的使用前是否已初始化 |
| Reentrancy 分析 | 检测中断服务函数与主循环共享的变量是否存在重入风险 |
| 状态机完整性 | 检测状态机是否缺少状态转换边或存在死状态 |

### 5.4 输出

- `event_architecture.json`：事件驱动架构模型
- `security_report.json`：静态安全检查报告

---

## 6. Stage 5 — 动态符号执行 (Dynamic Symbolic Execution)

### 6.1 作用

使用 **angr** 框架对固件二进制进行**符号执行**，验证 Stage 4 中发现的可疑路径，探索潜在的漏洞路径。

### 6.2 分析工具

- **主引擎**：`angr`
- **辅助**：`cle`（加载 ELF）、`claripy`（约束求解）

### 6.3 分析内容

1. **可达性分析**：对特定目标地址（如危险函数调用）进行符号执行，验证可达性
2. **输入约束求解**：求解触发特定路径的输入约束
3. **缓冲区溢出验证**：对可疑的 `memcpy` / `sprintf` 等调用进行符号化参数分析
4. **路径爆炸缓解**：
   - 使用 Veritesting 模式
   - 设置探索深度限制
   - 使用 Lazy Initialization 策略

### 6.4 输出

- `symbolic_report.json`：符号执行报告，包含可达路径及输入约束
- `exploit_paths/`：每一条可行路径的详细记录

---

## 7. 流水线配置 (Pipeline Configuration)

流水线通过 `data_pipeline_config.json` 进行配置，支持：

- 各阶段的启用/禁用
- 阶段间依赖关系
- 各阶段的独立参数
- 输入/输出路径

详情参见 [data_pipeline_config.json](./data_pipeline_config.json)。

---

## 8. 模块结构

```
project_root/
├── main.py                          # 入口文件，按配置依次执行各阶段
├── data_pipeline_config.json        # 流水线配置文件
├── architecture_spec.md             # 本架构文档
│
├── modules/
│   ├── __init__.py
│   ├── base.py                      # Stage 基类，定义统一接口
│   ├── stage1_preprocessor.py       # 阶段1：源码预处理
│   ├── stage2_ast_analysis.py       # 阶段2：AST 分析
│   ├── stage3_elf_analysis.py       # 阶段3：ELF 分析
│   ├── stage4_event_analysis.py     # 阶段4：事件驱动架构分析
│   └── stage5_symbolic_execution.py # 阶段5：动态符号执行
│
├── preprocessed/                    # Stage1 输出（自动创建）
├── ast_output/                      # Stage2 输出（自动创建）
├── elf_output/                      # Stage3 输出（自动创建）
├── event_output/                    # Stage4 输出（自动创建）
└── symbolic_output/                 # Stage5 输出（自动创建）
```

---

## 9. 扩展性设计

- **Stage 基类** (`modules/base.py`) 定义了 `run(config, context)` 接口，新增阶段只需继承该类
- **Context 传递**：阶段的输出通过 `context` 字典向下游传递，支持按需读取
- **配置驱动**：通过 `data_pipeline_config.json` 控制阶段启停和参数，无需修改代码
- **分析器扩展**：Stage 2 支持多种 AST 引擎（libclang / tree-sitter），通过配置切换