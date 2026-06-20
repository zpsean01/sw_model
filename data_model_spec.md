# 数据模型规格说明书 — Stage 4 与 Stage 5

> 本文档定义 `architecture_spec.md` 中 Stage 4（场景模型构建与安全审计）和 Stage 5（动态符号执行）所涉及的全部数据模型，包括输入、中间表示和输出产物的字段语义、类型约束和关联关系。

---

## 1. Stage 4 — 固件统一数据模型

### 1.1 统一调用图（call_graph_unified）

Stage 3 将 Stage 2（静态分析）和 Stage 3（ELF 分析）的结果合并为统一图，是 Stage 4 所有分析的基础中间表示。

**文件路径**：`data/modeling/call_graph_unified.json`

**序列化格式**：NetworkX `MultiDiGraph` 标准序列化

```jsonc
{
  "nodes": [
    {
      "id": "string",              // 节点唯一标识（函数名或寄存器变量名）
      "attributes": {
        "node_type": "function" | "register",  // 节点类型
        "kind": "CursorKind.FUNCTION_DECL" | "CursorKind.VAR_DECL",
        "file": "string",                       // 源码文件绝对路径
        "return_type": "string",                // (仅 function) 返回值类型
        "parameters": [                         // (仅 function) 参数列表
          { "name": "string", "type": "string" }
        ],
        "calls": ["string"],                    // (仅 function) 被调用函数名列表
        "type": "string",                       // (仅 register) 变量类型
        "line": 0,                              // (仅 register) 行号
        "is_root": false                        // 是否为根节点
      }
    }
  ],
  "edges": [
    {
      "source": "string",           // 调用方函数名
      "target": "string",           // 被调用方函数名
      "key": "string",              // 多重边区分键（MultiDiGraph 特性）
      "attributes": {
        "edge_type": "calls" | "contains" | "flow",  // 边类型
        "label": "string"           // 边上显示的文本
      }
    }
  ]
}
```

**关键约束**：
- 同一对 `(source, target)` 可有多条边（以 `key` 区分），例如同一调用点在不同上下文中的调用
- 节点 `node_type` 为 `"function"` 或 `"register"`，两类节点共存于同一图中
- `edges` 中 `edge_type = "contains"` 表示层级包含关系，用于前端可视化分组

---

### 1.2 函数清单（functions）

Stage 2 输出，Stage 4 进行分析时读取。

**文件路径**：`data/static/functions/functions.json`

```jsonc
[
  {
    "name": "string",              // 函数名
    "kind": "CursorKind.FUNCTION_DECL",
    "return_type": "string",       // 返回值类型
    "parameters": [
      { "name": "string", "type": "string" }
    ],
    "calls": ["string"],           // 直接调用的函数名列表
    "file": "string"               // 源码文件绝对路径
  }
]
```

---

### 1.3 中断向量表（interrupts）

Stage 2 输出，为 Stage 4 事件模型提供触发事件维度。

**文件路径**：`data/static/interrupts/interrupts.json`

```jsonc
[
  {
    "name": "string",              // ISR 函数名，如 "UART0_IRQHandler"
    "vector": 0,                   // 中断向量号
    "priority": 0,                 // 优先级（0=最高）
    "file": "string"               // 定义所在文件
  }
]
```

---

### 1.4 寄存器清单（registers）

Stage 2 输出，为 Stage 4 寄存器配置审计提供数据来源。

**文件路径**：`data/static/registers/registers.json`

```jsonc
[
  {
    "name": "string",              // 变量名，如 "g_gpio_ports"
    "type": "string",              // 类型，如 "gpio_regs_t *[2]"
    "file": "string",              // 定义文件
    "line": 0,                     // 行号
    "kind": "CursorKind.VAR_DECL"
  }
]
```

---

### 1.5 状态机（state_machines）

Stage 2 输出，识别 `enum + switch` 模式构成的状态机。

**文件路径**：`data/static/state_machines/state_machines.json`

```jsonc
[
  {
    "name": "string",              // 状态机名，如 "ddr5_init_state_t"
    "states": [
      { "name": "string" }         // 状态枚举值名称
    ],
    "transitions": [
      {
        "from": "string",          // 源状态
        "to": "string"             // 目标状态
      }
    ],
    "file": "string",
    "line": 0
  }
]
```

---

## 2. Stage 4 — 协议描述模型（spec_model，外部系统提供）

本项目的定位是**协议知识库的消费者**——`spec_model` 由外部系统（如协议解析工具、人工整理）生成，Stage 4 读取并以此为基准检查固件实现的合规性。

**文件路径**：`data/spec_model_ddr5_mock.json`（概念验证 mock）

### 2.1 顶层结构

```jsonc
{
  "metadata": {
    "protocol": "string",          // 协议名称，如 "DDR5"
    "version": "string",           // 协议版本，如 "JESD79-5C"
    "description": "string",
    "status": "string"             // "concept_prototype" | "production"
  },
  "object_entities": { ... },      // 对象实体（寄存器、命令、初始化序列）
  "generalized_interfaces": { ... },  // 广义接口（总线、控制器寄存器映射）
  "behavior_constraints": { ... },    // 行为约束（时序、状态机）
  "scenarios": { ... }             // 业务场景（初始化流程等）
}
```

### 2.2 object_entities — 对象实体

定义协议中的硬件对象。

```jsonc
{
  "registers": [
    {
      "name": "string",            // 寄存器名，如 "MR6"
      "address": 0,                // 寄存器地址
      "description": "string",
      "fields": {
        "FIELD_NAME": {
          "bits": [0, 6],          // 位域范围 [高位, 低位]；或 "bit": 3
          "valid_values": [0, 127],  // 合法取值集合
          "description": "string",
          "depends_on": ["MR3.CRC_EN_WR=1"]  // 可选：依赖条件
        }
      },
      "cross_dependency": "string" // 可选：跨寄存器依赖说明
    }
  ],
  "commands": [
    {
      "name": "string",            // 命令名，如 "MRW"
      "opcode": "string",          // 操作码，如 "20"
      "description": "string"
    }
  ],
  "expected_init_sequence": [
    "string"                       // 初始化步骤列表，如 "MRW MR0"
  ]
}
```

### 2.3 generalized_interfaces — 广义接口

描述协议物理接口的抽象。

```jsonc
{
  "CA_Bus": {
    "description": "string",
    "commands": {
      "MRW": {
        "ca_pins": "string",       // CA 引脚编码
        "tMRD_min": 8             // 可选：该命令的最小时序要求
      }
    }
  },
  "MR_Interface": {
    "description": "string",
    "register_map": {
      "DDR_CTRL_MR_CMD": {
        "offset": "string",        // 相对于基址的偏移
        "access": "rw" | "ro" | "wo",
        "values": { "BUSY": "(1<<31)" }  // 可选：位域编码
      }
    }
  }
}
```

### 2.4 behavior_constraints — 行为约束

定义协议层面的时序和状态机约束。

```jsonc
{
  "timing": [
    {
      "parameter": "string",       // 参数名，如 "tMRD"
      "min_cycles": 0,            // 最小时钟周期数
      "description": "string",
      "section": "string"          // 协议章节引用
    }
  ],
  "state_machines": [
    {
      "name": "string",            // 状态机名，如 "ddr5_init"
      "description": "string",
      "protocol_states": 0,        // 协议规定的状态总数
      "expected_states": ["string"],   // 完整状态名列表
      "expected_transitions": [
        {
          "from": "string",        // "*" 表示任意状态
          "to": "string",
          "description": "string"
        }
      ],
      "error_recovery_required": true,
      "recovery_requirement": "string"
    }
  ]
}
```

### 2.5 scenarios — 业务场景

定义协议层面的典型业务场景，用于对比固件实现。

```jsonc
{
  "initialization": {
    "name": "string",
    "trigger_event": "string",
    "reference": "string",         // 协议章节引用
    "expected_path": [
      {
        "step": 0,
        "action": "string",
        "state": "string",
        "timing": "tXPR=512"       // 可选：时序要求
      }
    ],
    "timing_requirements": {
      "MRW_to_MRW": {
        "min_cycles": 0,
        "parameter": "string"
      }
    }
  }
}
```

---

## 3. Stage 4 — 分析模型（输出）

### 3.1 事件架构模型（event_architecture）

**文件路径**：`data/modeling/event_architecture.json`

```jsonc
{
  "total_isrs": 0,                     // 中断服务函数总数
  "isr_list": ["string"],              // 所有 ISR 函数名
  "isr_reachable_functions": ["string"],  // 从 ISR 可达的函数集合
  "model_type": "event_driven"         // 模型类型标识
}
```

**语义**：每个 ISR 作为"触发事件"，通过调用图传播可触达的函数集合，形成 `{触发事件, 调用路径}` 的二维模型。

---

### 3.2 安全审计报告（security_report）

**文件路径**：`data/modeling/security_report.json`

```jsonc
{
  "summary": {
    "total": 0,                        // 总发现数
    "severities": {
      "critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0
    }
  },
  "findings": [
    {
      "type": "string",                // 断言类型
      "severity": "critical" | "high" | "medium" | "low" | "info",
      "message": "string",             // 人类可读的描述
      "spec_ref": "string",            // 协议/规范引用
      "expected": "string",            // 预期行为
      "actual": "string",              // 实际行为
      "location": {
        "file": "string",              // 文件路径
        "line": 0,                     // 行号
        "function": "string"           // 函数名
      }
    }
  ]
}
```

**支持的断言类型**（`type` 字段枚举值）：

| type | 分析目标 | 输入数据源 |
|------|---------|-----------|
| `irq_priority` | 中断优先级冲突 | `interrupts.json` + 调用图 |
| `critical_section` | 临界区保护缺失 | 调用图 + 全局变量 |
| `stack_analysis` | 栈深度超阈值 | 调用图 + 函数 |
| `uninit_globals` | 未初始化全局变量 | 二进制全局变量 + 函数 |
| `reentrancy` | 重入风险 | ISR 可达函数 + 全局变量 |
| `state_machine_integrity` | 状态机完整性 | `state_machines.json` |
| `state_machine_completeness` | 协议状态覆盖 | `state_machines.json` + `spec_model` |
| `timing_constraint_audit` | 时序约束合规 | `functions.json` + `spec_model` |
| `register_config_audit` | 寄存器配置合法取值 | `functions.json` + `registers.json` + `spec_model` |
| `error_handling_coverage` | 错误处理路径覆盖 | 状态机 + `spec_model` |
| `cross_register_dependency` | 跨寄存器依赖顺序 | `functions.json` + `spec_model` |

---

### 3.3 协议一致性报告（protocol_conformance）

**文件路径**：`data/modeling/protocol_conformance.json`

```jsonc
{
  "spec_model": "string",              // 使用的 spec_model 路径
  "total_protocol_findings": 0,        // 协议类发现总数
  "findings": [
    {
      // 继承 security_report findings 全部字段，并额外包含：
      "type": "state_machine_completeness"
           | "timing_constraint_audit"
           | "register_config_audit"
           | "error_handling_coverage"
           | "cross_register_dependency",
      "severity": "string",
      "message": "string",
      "spec_ref": "string",
      "expected": "string",
      "actual": "string",
      "location": {
        "file": "string",
        "function": "string"
      }
    }
  ]
}
```

**与 security_report 的关系**：`protocol_conformance` 的 findings 是 `security_report` 的子集，由 `ProtocolConformanceAnalyzer` 独立产出后合并到 `security_report` 中。两文件分别存放，protocol_conformance 便于前端专项展示。

---

### 3.4 分析模型的数据流总结

```
                     ┌──────────────────────────────┐
                     │      spec_model (外部)        │
                     │  protocol knowledge base      │
                     └────────────┬─────────────────┘
                                  │
Stage 2 output ──┐                │
  functions      │                │
  call_graph     ├──► Stage 4 ────┼──► event_architecture.json
  interrupts     │   (分析引擎)    │
  registers      │                │
  state_machines │                ├──► security_report.json
                 │                │    (含所有 findings)
Stage 3 output ──┤                │
  call_graph     │                └──► protocol_conformance.json
  unified        │                     (协议专项 findings)
                 │
binary_globals ──┘
```

---

## 4. Stage 5 — 深度受限符号执行（Depth-Limited Symbolic Execution）

### 4.1 设计动机

实际固件不可能从 `main()` 入口进行全量符号执行——路径爆炸使得计算不可行。精化方案的核心思路：

1. **自定义函数入口**：从 Stage 4 发现的具体函数开始，而非从 main 入口
2. **深度受限遍历**：在调用树中探索到 `max_depth` 层即停止
3. **边界 Hook + Inspect（分离）**：
   - **Hook**（机制层）：在深度边界处拦截调用，用 SimProcedure 替换被调用函数
   - **Inspect**（语义层）：为边界跨越赋予风险含义（risk_level, risk_tags, return_range）
4. **TraceRecorder**：每次 Hook 触发时记录完整的符号变量、寄存器快照、路径约束，确保每个 finding 可复现
5. **数据驱动**：入口点和 Hook/Inspect 定义均可从配置文件显式指定，也可从 Stage 4 报告自动提取

**架构示意**：

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
  ┌──────────────────────────────┘                      ▼
  │                                           boundary functions set
  ▼
  ┌─────────────────────────────────────────┐
  │  per entry_point:                       │
  │    1. resolve entry address (ELF sym)   │
  │    2. apply hooks (HookSpec → SimProc)  │←── 机制层：怎么拦截
  │    3. record trace (TraceRecorder)      │←── 语义层：风险表征
  │    4. call_state(entry_addr) → simgr    │
  │    5. collect InspectTrigger records    │
  └─────────────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────────┐
  │  traces/                                │
  │  ├── trace_{func}.json (结构化事件流)    │
  │  └── trace_{func}.md  (可读复现日志)     │
  └─────────────────────────────────────────┘
```

---

### 4.2 输入模型

#### 4.2.1 入口点定义（EntryPointSpec）

入口点决定了符号执行从哪个函数开始、探索多深。

```jsonc
{
  "function": "string",              // 入口函数名，如 "_state_vref_train"
  "max_depth": 3,                    // 向下探索的调用层级数
  "context": "string",               // 选择此入口点的原因（引用 Stage 4 finding）
  "inspect_default": "symbolic_return",  // 边界函数的默认 Hook 类型
  "entry_args": []                   // 可选：传给入口函数的具体参数
}
```

**入口点获取策略**（优先级从高到低）：

```
1. 配置文件 params.entry_points 显式指定
2. 从 Stage 4 security_report.json 自动提取：
   - findings[].location.function → 入口函数名
   - severity 映射到 max_depth: critical→1, high→2, medium→3, low→4, info→5
```

#### 4.2.2 HookSpec — 边界拦截机制定义

Hook 是纯机制层，只定义"怎么拦截"，不携带风险语义。

**源码**：`modules/stage5/hook.py` → `HookSpec`

```jsonc
{
  "function_name": "string",         // 被 Hook 的函数名
  "hook_type": "symbolic_return"     // SimProcedure 类型
             | "concrete_stub"
             | "summary"
}
```

**Hook 类型语义**：

| hook_type | SimProcedure 行为 | 适用场景 |
|-----------|------------------|---------|
| `symbolic_return` | 返回完全无约束的符号值 | 外部函数行为未知，但返回值参与后续逻辑 |
| `concrete_stub` | 返回 `return_range` 中点的具体值 | 已知函数返回范围，可用中点近似 |
| `summary` | 执行预定义的完整摘要（修改寄存器/内存） | 函数行为已知且有详细摘要定义 |

#### 4.2.3 InspectSpec — 风险语义定义

Inspect 是纯语义层，为边界跨越赋予风险含义。与 HookSpec 按 `function_name` 配对使用。

**源码**：`modules/stage5/inspect.py` → `InspectSpec`

```jsonc
{
  "function_name": "string",         // 对应的函数名（与 HookSpec 配对）
  "risk_level": "safe"               // 风险等级
              | "warning"
              | "critical"
              | "unknown",
  "risk_tags": [                     // 风险标签（可多个）
    "register_write",                //   修改寄存器
    "timing_critical",               //   时序敏感
    "value_range_overflow",          //   返回值可能越界
    "input_dependent",               //   行为依赖外部输入
    "auto_generated"                 //   自动生成（非人工定义）
  ],
  "return_range": [0, 255],         // 可选：返回值范围 [min, max]（仅 concrete_stub 使用）
  "modified_registers": ["r0", "r1"],  // 可选：此函数预期修改的寄存器
  "description": "string"            // 人类可读的风险描述，写入 InspectTrigger.trace_detail
}
```

#### 4.2.4 全局策略（global_strategy）

```jsonc
{
  "call_graph_path": "data/modeling/call_graph_unified.json",  // 调用图数据源
  "default_max_depth": 3,           // 默认探索深度
  "default_hook_type": "symbolic_return",  // 自动生成 Hook 时的默认类型
  "timeout": 300,                   // 超时（秒）
  "veritesting": true               // 是否启用 Veritesting 混合执行
}
```

#### 4.2.5 配置示例

```jsonc
{
  "id": "stage5",
  "params": {
    "elf_file": "fw_samples/build/bin/firmware_tfm.elf",
    "output_dir": "data/sym_execution",

    "entry_points": [],              // 空 = 从 Stage 4 自动提取

    "global_strategy": {
      "call_graph_path": "data/modeling/call_graph_unified.json",
      "default_max_depth": 3,
      "default_hook_type": "symbolic_return",
      "timeout": 300,
      "veritesting": true
    },

    "hooks": {                        // 机制：只定义 hook_type
      "ddr5_train_vref_dq": {
        "hook_type": "symbolic_return"
      },
      "ddr5_train_vref_ca": {
        "hook_type": "symbolic_return"
      },
      "ddr5_write_reg": {
        "hook_type": "symbolic_return"
      }
    },

    "inspect_specs": {                // 语义：为 hooks 提供风险注解
      "ddr5_train_vref_dq": {
        "risk_level": "warning",
        "risk_tags": ["register_write", "value_range_overflow"],
        "return_range": [0, 255],
        "description": "Writes MR6 VREF_DQ_VAL. Returns 0-255 but spec limits to 0-127."
      },
      "ddr5_write_reg": {
        "risk_level": "warning",
        "risk_tags": ["register_write", "timing_critical"],
        "description": "Writes a mode register. tMRD timing must be observed."
      }
    }
  }
}
```

---

### 4.3 输出模型

#### 4.3.1 符号执行报告（symbolic_report）

**文件路径**：`data/sym_execution/symbolic_report.json`

```jsonc
{
  "binary": "string",                    // 分析的目标 ELF 文件路径
  "entry_count": 0,                      // 分析的入口点总数
  "entry_results": [
    {
      "entry_function": "string",        // 入口函数名
      "entry_address": "string",         // 入口函数地址（十六进制），如 "0x8001234"
      "max_depth": 3,                    // 此入口点的探索深度
      "context": "string",               // 选择此入口点的原因
      "status": "completed"              // 执行状态
              | "skipped"                //   (函数未在 ELF 中找到)
              | "no_hooks"               //   (无边界函数可 Hook)
              | "error",                 //   (执行出错)
      "boundary_hooks_applied": 0,       // 实际应用的 Hook 数量
      "boundary_functions": ["string"],  // 边界函数列表
      "active_paths": 0,                 // 探索结束时的活跃路径数
      "deadended_paths": 0,              // 死路径数
      "inspect_triggers": [              // 被触发的 Inspect 记录
        {
          "entry_function": "string",    // 哪个入口点触发了此 Hook
          "called_function": "string",   // 被 Hook 调用的函数名
          "call_depth": 3,               // 触发时的调用深度
          "hook_type": "symbolic_return",
          "risk_level": "warning",
          "risk_tags": ["register_write"],
          "description": "string"
        }
      ],
      "errors": ["string"]               // 此入口点的错误信息
    }
  ],
  "summary": {
    "total_entry_points": 0,
    "completed": 0,
    "errors": 0,
    "total_inspect_triggers": 0,         // 所有入口点触发的 Hook 总数
    "risk_distribution": {               // 风险等级分布统计
      "warning": 0,
      "critical": 0,
      "unknown": 0
    },
    "paths_found": 0
  },
  "errors": ["string"]                   // 全局错误（如 angr 不可用）
}
```

#### 4.3.2 逐入口点详情（entry_results）

**文件路径**：`data/sym_execution/entry_results/{function_name}.json`

每个入口点单独保存一份完整结果，字段与 `entry_results[]` 中的元素一致。便于按函数查询分析结果。

#### 4.3.3 TraceRecorder 输出（traces/）

**说明**：每个入口点执行时，`TraceRecorder` 记录完整的事件流水，同步输出为 JSON 和 Markdown 两种格式。

**文件路径**：`data/sym_execution/traces/trace_{function_name}.json`

结构化 JSON 事件流，每个事件包含：类型、函数名、深度、符号变量、路径约束、寄存器快照。

```jsonc
{
  "entry_function": "_state_vref_train",
  "max_depth": 3,
  "event_count": 5,
  "finding_count": 2,
  "events": [
    {
      "event_type": "entry_start",           // 入口点开始执行
      "function": "_state_vref_train",
      "depth": 0,
      "details": { "address": "0x8001000", "max_depth": 3 }
    },
    {
      "event_type": "hook_triggered",        // 边界 Hook 被触发
      "function": "ddr5_train_vref_dq",
      "depth": 3,
      "symbolic_vars": [{                   // 创建的符号变量
        "name": "inspect_ddr5_train_vref_dq_ret",
        "bits": 32,
        "description": "Writes MR6 VREF_DQ_VAL..."
      }],
      "constraints": ["<Bool True>"],       // 当前路径约束
      "details": {
        "hook_type": "symbolic_return",
        "registers": {                       // 寄存器快照
          "r0": "<BV32 0x40>",
          "r1": "<BV32 0x6>",
          "pc": "<BV32 0x8001300>"
        }
      }
    },
    {
      "event_type": "finding",               // 风险发现
      "function": "ddr5_train_vref_dq",
      "depth": 3,
      "finding_id": "F-ddr5_train_vref_dq-3",
      "details": {
        "message": "Training value written to 7-bit register field",
        "risk_level": "warning",
        "risk_tags": ["register_write", "value_range_overflow"]
      }
    },
    {
      "event_type": "entry_end",             // 入口点执行完成
      "function": "_state_vref_train",
      "depth": 0,
      "details": { "status": "completed", "active_paths": 2 }
    }
  ],
  "findings": [                             // findings 汇总
    {
      "finding_id": "F-ddr5_train_vref_dq-3",
      "function": "ddr5_train_vref_dq",
      "message": "Training value written to 7-bit register field",
      "symbolic_vars": [...],
      "constraints": [...]
    }
  ]
}
```

**事件类型枚举**：

| event_type | 含义 | 捕获的信息 |
|------------|------|-----------|
| `entry_start` | 入口点开始 | 地址、参数、max_depth |
| `hook_triggered` | 边界 Hook 在符号执行中被触发 | 符号变量名/位宽、寄存器 r0-r3/sp/lr/pc、路径约束 |
| `symbolic_var_created` | SimProcedure 创建符号变量 | 变量名、位宽、描述 |
| `memory_write` | 对敏感地址的写入 | 目标地址、值描述、是否符号值 |
| `finding` | 风险发现（risk_level=warning/critical 自动触发） | risk_level、risk_tags、symbolic_vars、constraints |
| `branch` | 分支决策 | 条件表达式、选择方向 |
| `entry_end` | 入口点完成 | 状态、活跃路径数 |

**文件路径**：`data/sym_execution/traces/trace_{function_name}.md`

Markdown 格式包含：

```
# Symbolic Execution Trace: `ddr5_train_vref_dq`

- Max depth: 3
- Events: 5
- Findings: 2

## Event Log

| # | Type | Function | Depth | Details |
|---|------|----------|-------|---------|
| 0 | entry_start | _state_vref_train | 0 | address=0x8001000; max_depth=3 |

## Findings

### Finding: F-ddr5_train_vref_dq-3
- Function: `ddr5_train_vref_dq` (depth=3)
- Message: Training value written to 7-bit register field...
- Symbolic var: `inspect_ddr5_train_vref_dq_ret` (32 bit)
- Constraint: `<Bool True>`
```

**复现价值**：Markdown 文件可以直接作为 Bug Report 的复现步骤附件。JSON 文件携带完整上下文（symbolic vars + constraints + register snapshot），开发者可据此重新生成相同的符号执行状态。**每个 finding 在 trace 中都有完整的 symbolic var 定义和路径约束记录，确保可复现。**

#### 4.3.4 Hook 库快照（hooks.json）

**文件路径**：`data/sym_execution/hooks.json`

保存本次执行中实际注册的所有 `HookSpec`（含配置指定的和自动生成的），用于结果可复现。

```jsonc
{
  "ddr5_train_vref_dq": {
    "function_name": "ddr5_train_vref_dq",
    "hook_type": "symbolic_return"
  }
}
```

#### 4.3.5 InspectSpec 快照（inspect_specs.json）

**文件路径**：`data/sym_execution/inspect_specs.json`

保存本次执行的 `InspectSpec` 风险语义定义。

```jsonc
{
  "ddr5_train_vref_dq": {
    "function_name": "ddr5_train_vref_dq",
    "risk_level": "warning",
    "risk_tags": ["register_write", "value_range_overflow"],
    "return_range": [0, 255],
    "modified_registers": [],
    "description": "Writes MR6 VREF_DQ_VAL..."
  }
}
```

#### 4.3.6 入口点配置快照（entry_points.json）

**文件路径**：`data/sym_execution/entry_points.json`

保存本次执行使用的入口点配置（当从 Stage 4 自动提取时尤为重要——记录提取结果以便审计）。

```jsonc
[
  {
    "function": "_state_vref_train",
    "max_depth": 3,
    "context": "Stage 4: register_config_audit — ...",
    "entry_args": []
  }
]
```

---

### 4.4 符号执行数据流

```
  ┌─────────────────────────────────────┐
  │  Stage 4 — security_report.json     │
  │  findings[].location.function       │──► extract_entry_points_from_report()
  └─────────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────┐
  │  EntryPointSpec[]                   │
  │  {function, max_depth, context}     │
  └─────────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────┐
  │  HookLibrary                        │
  │  + call_graph_unified.json (BFS)    │
  │  + hooks + inspect_specs config   │
  └─────────────────────────────────────┘
           │
           ├──► auto_generate_hooks() → boundary functions set
           │
           ▼
  ┌─────────────────────────────────────┐
  │  per entry_point:                   │
  │    resolve entry address (ELF sym)  │
  │    proj.hook(boundary_func, simproc)│
  │    proj.factory.call_state(addr)    │
  │    simgr.run()                      │
  └─────────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────┐
  │  InspectTrigger[] (runtime records) │
  │  {called_func, depth, risk_level}   │
  └─────────────────────────────────────┘
           │
           ├──► symbolic_report.json              (汇总)
           ├──► entry_results/{func}.json          (逐入口点详情)
           ├──► hooks.json                        (HookSpec 快照)
           ├──► inspect_specs.json                (InspectSpec 快照)
           └──► entry_points.json                  (入口点配置快照)
```

---

## 5. 附录：数据目录总览

```
data/
├── preprocessing/                  # Stage 1 输出
├── static/                         # Stage 2 输出
│   ├── functions/functions.json
│   ├── call_graph/call_graph.json
│   ├── registers/registers.json
│   ├── interrupts/interrupts.json
│   ├── state_machines/state_machines.json
│   ├── globals/globals.json
│   └── types/types.json
├── binary/                         # Stage 3 输出
│   ├── functions/binary_functions.json
│   ├── call_graph/call_graph_binary.json
│   ├── globals/binary_globals.json
│   └── types/binary_types.json
├── modeling/                       # Stage 4 写入
│   ├── call_graph_unified.json     # (Stage 3 写入，Stage 4 作为输入)
│   ├── event_architecture.json
│   ├── security_report.json
│   └── protocol_conformance.json
├── sym_execution/                  # Stage 5 输出
│   ├── symbolic_report.json
│   ├── hooks.json                   # HookSpec 快照（可复现）
│   ├── inspect_specs.json           # InspectSpec 快照
│   ├── entry_points.json            # 入口点配置快照
│   ├── entry_results/              # 逐入口点详情
│   │   └── {function_name}.json
│   └── traces/                     # TraceRecorder 输出
│       ├── trace_{function_name}.json
│       └── trace_{function_name}.md
└── spec_model_ddr5_mock.json       # 外部协议知识库
```

### 文件依赖关系

```
Stage 1 ──► Stage 2 ──┐
                       ├──► Stage 4 ──► Stage 5
Stage 3 ───────────────┘        │
                                │
spec_model (外部) ──────────────┘
```

- **Stage 4 输入**：Stage 2 全部输出 + Stage 3 部分输出 + `call_graph_unified.json` + `spec_model`
- **Stage 4 输出**：`event_architecture.json` + `security_report.json` + `protocol_conformance.json`
- **Stage 5 输入**：ELF 文件 + `security_report.json`（提取目标地址）+ 探索策略
- **Stage 5 输出**：`symbolic_report.json` + `exploit_paths/path_*.json`