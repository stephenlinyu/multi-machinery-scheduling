# 丘陵山地多农机调度算法

针对丘陵山地地形，研究多农机任务分配（MRTA）问题，覆盖静态与动态两类场景。项目以开源 **GA_MRTA**（MIT）为基础，加入坡度能耗模型、自适应遗传算子与动态调度策略，并通过对比实验与等价性测试验证改进效果。

> 本项目为个人研究与论文配套代码，实验数据文件未随仓库分发。

## 算法模块

| 目录 | 内容 |
| --- | --- |
| `01_static` | 基础遗传算法（MRTA 基线，含论文对比实验） |
| `02_energy_aware_ga` | 坡度能耗建模 + 自适应突变权重 + 地形距离 |
| `03_dynamic` | 改进合同网（CNP）+ 变邻域禁忌搜索（VNS）动态重调度 |
| `ga_solver` | MATLAB→Python 迁移版调度器，可脱离 MATLAB 运行 |

## 关键技术

- **坡度能耗模型**：把地形坡度纳入转移代价，`TerrainDistance.m` / `CostFunction.m`
- **自适应遗传算法**：按种群多样性调整突变权重（`adaptMutationWeights.m`、`TeachingMutate_*.m`）
- **动态调度**：任务扰动后，用改进合同网做快速重分配，VNS + 禁忌搜索做局部优化（`ImprovedCNP_WithPosition.m`、`VNS_TabuSearch.m`）
- **对比实验**：收敛速度、解质量、稳定性三维度对比基线

## 运行

**MATLAB（原始算法）**：R2020b 及以上，进入对应目录运行 `main.m`。

**Python（迁移版，无需 MATLAB）**：

```python
from ga_solver import solve_schedule

result = solve_schedule(machines, fields)
print(result['total_cost'])
```

详见 [ga_solver/README.md](ga_solver/README.md)。

## 说明

- 基线代码来自 **GA_MRTA**，Copyright (c) 2024 Thi Thuy Ngan Duong，MIT License，见 `01_static/LICENSE`。
- 论文实验数据（`.xlsx`）与结果文件未包含在仓库中。
- Python 迁移版与等价性回归测试见配套仓库 [hilly-farm-scheduler](https://github.com/stephenlinyu/hilly-farm-scheduler) 的 `ga_solver`。
