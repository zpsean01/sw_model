# Scenario-0001: 差分检测有效性验证

## 设计意图

验证 sw_model 流水线能否通过差分检测区分"正确代码"与"含已知 Bug 的代码"。
如果流水线对两组代码的输出不同，则证明框架对代码变动有响应能力（敏感性）；
如果输出相同，则说明存在检测盲区。

## 靶标

ARM Trusted Firmware GIC-700 驱动（精简版）。

- 正确版本：`fw_samples/tf_a/`
- Bug 版本：`fw_samples/tf_a_with_bugs/`（从正确版本复制后注入 3 个 Bug）

## Bug 设计

| ID | 文件 | 改动 | 违反 | 预期检测层 |
|---|---|---|---|---|
| B1 | `gicv3_main.c:gicd_set_ctlr` | 删除 `gicd_wait_for_pending_write(base)` 调用 | GIC 协议：写 GICD_CTLR 后必须轮询 RWP | Stage 3 CFG → Stage 5 触发 → Stage 6 风险 |
| B2 | `gicv3_private.h:gicd_read_ctlr` | 返回 0 而非调用 `mmio_read_32(base + GICD_CTLR)` | 寄存器读操作被破坏，下游配置基于错误的返回值 | Stage 3 CFG（边消失） |
| B3 | `gicv3_main.c:gicv3_distif_init` | 新增 `mmio_write_32(gicd_base+0x0000, 0xFFFFFFFF)` | 绕过协议直接 MMIO 写 GICD_CTLR | Stage 3 CFG（边新增） |

## 流水线配置

两组代码各自使用独立的数据路径，避免输出相互覆盖。

| 配置项 | 正确版本 | Bug 版本 |
|---|---|---|
| 预处理输出 | `data/preprocessing/..._r4p0/` | `data/preprocessing/..._r4p0_with_bugs/` |
| 静态输出 | `data/static/..._r4p0/` | `data/static/..._r4p0_with_bugs/` |
| 二进制输出 | `data/binary/..._r4p0/` | `data/binary/..._r4p0_with_bugs/` |
| 建模输出 | `data/modeling/..._r4p0/` | `data/modeling_with_bugs/..._r4p0/` |
| 符号执行 | `data/sym_execution/..._r4p0/` | `data/sym_execution/..._r4p0_with_bugs/` |
| 风险聚合 | `data/risks/..._r4p0/` | `data/risks/..._r4p0_with_bugs/` |
| 配置文件 | `data_pipeline_config_tf_a.json` | `data_pipeline_config_tf_a_with_bugs.json` |

关键配置要素：
- `inspect_specs`：为 `gicd_read_ctlr`（info）、`gicd_write_ctlr`（warning）、`gicd_wait_for_pending_write`（critical）标注风险等级
- `hooks.__assert_fail`：concrete_stub，防止路径因 assert 失败而终止
- `global_strategy.default_max_depth`：2

## 执行

```bash
# 正确版本
python main.py -c data_pipeline_config_tf_a.json

# Bug 版本
python main.py -c data_pipeline_config_tf_a_with_bugs.json
```

## 结果对比

### Stage 3 — Binary Call Graph

| 指标 | 正确 | Bug | 差异 |
|---|---|---|---|
| 节点数 | 22 | 22 | 0 |
| 边数 | 39 | 38 | -1 |
| 共享边 | — | — | 26 |

```
移除边: gicd_read_ctlr→mmio_read_32      ← B2 检测到
         gicd_set_ctlr→gicd_wait_for_pending_write  ← B1 检测到
新增边: gicv3_distif_init→mmio_write_32  ← B3 检测到
```

### Stage 5 — Symbolic Execution

| Entry | 正确触发 | Bug 触发 | 差异 |
|---|---|---|---|
| gicv3_distif_init | 24 | 22 | -2（B1 导致 RWP poll 路径减少） |
| gicv3_driver_init | 1 | 1 | 0 |
| gicv3_rdistif_init | 20 | 20 | 0 |

### Stage 6 — Risk Registry

| 指标 | 正确 | Bug | 差异 |
|---|---|---|---|
| 总风险 | 19 | 15 | -4 |
| verified | 18 | 14 | -4 |
| residual | 1 | 1 | 0 |

差异来源：B1 导致 `gicd_wait_for_pending_write`（risk_level=critical）的触发次数在 gicv3_distif_init 中减少，
映射为 Stage 6 的 verified 风险计数减少 4。

## 结论

### 框架有效性

| 检测层 | 敏感性 | 检出 |
|---|---|---|
| Stage 3 调用图 | 对调用关系变化最敏感 | 3/3 Bug |
| Stage 5 符号执行 | 对控制流变化敏感，需配合 inspect_specs | B1 |
| Stage 6 风险聚合 | 依赖 inspect_specs 配置，反映触发计数差异 | B1 |

### 盲区

- B2（寄存器读损坏）仅在调用图层面可检出，未向上传递到风险聚合层。
- B3（非法直接 MMIO 写）同理。
- 要让 B2/B3 穿透到 Stage 6，需在 `inspect_specs` 中为 `mmio_read_32` / `mmio_write_32` 标注非 `safe` 风险等级。

### 设计资产意义

本场景作为 sw_model 的回归基线。未来任何对 modules/ 或 rules/ 的改动，
都应在此场景上运行差分验证，确保：
1. 正确版本输出不变（无回归）
2. Bug 版本输出仍能被区分（敏感性维持）
