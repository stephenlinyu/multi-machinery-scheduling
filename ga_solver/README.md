# ga_solver — Python 版遗传算法调度器

MATLAB 调度算法（`RunGA.m` / `CostFunction.m` 等）的 Python 迁移实现，供 Flask 后端直接调用，**不需要安装 MATLAB**。

## 与 MATLAB 的对应关系

| Python 模块 | MATLAB 源文件 | 作用 |
| --- | --- | --- |
| `ga_main.py` | `RunGA.m` | GA 主循环（选择 / 交叉 / 变异 / 精英保留 / 停滞终止） |
| `cost_function.py` | `CostFunction.m` | 适应度：行驶距离 + 能耗 + 作业时间 |
| `init_assignment.py` | `InitAssignment.m` | 初始任务分配 |
| `selection.py` | `RouletteWheelSelection.m` | 轮盘赌选择 |
| `crossover.py` / `crossover_b.py` | `Crossover.m` / `CrossoverB.m` | 两种交叉算子 |
| `mutate.py` | `Tubian.m` / `MutateB.m` / `MutateC.m` | 三种变异算子 |
| `solver.py` | `run_scheduler.m` | 对外入口：组装 model 并返回调度结果 |

## 用法

```python
from ga_solver import solve_schedule

machines = [
    {
        'id': 'R-001', 'x': 0.0, 'y': 0.0, 'h': 300,
        'nom_vel': 4.0, 'fuel': 0.06, 'fueltask': 2.0, 'w': 7000,
    },
]
fields = [
    {'id': 'F-001', 'x': 1.2, 'y': 0.8, 'h': 320, 'S': 500},
]

result = solve_schedule(machines, fields)
print(result['total_cost'])
print(result['agents'][0]['task_sequence'])
```

## 输入字段

- **农机**：`id`、`x` / `y`（本地公里坐标）、`h`（海拔 m）、`nom_vel`（平路速度 km/h）、`fuel`（油耗 L/km）、`fueltask`（作业能耗 L/h）、`w`（作业能力 m²/h）
- **农田**：`id`、`x` / `y`、`h`（海拔 m）、`S`（面积 m²）

## 输出

```python
{
    'status': 'success',
    'total_cost': float,
    'timestamp': 'YYYY-mm-dd HH:MM:SS',
    'agents': [
        {'machine_id': 'R-001', 'task_sequence': [...], 'total_time': float},
    ]
}
```

## 说明

- **纯标准库实现**（`random` / `math` / `time` / `datetime`），无第三方依赖，便于部署到无 MATLAB 的服务器。
- 成本模型考虑坡度导致的上下坡速度差异、能耗与作业时间，参数（`mu_u` / `mu_d` / `v_max`）见 `solver.py` 的 model 构建部分。
- 迁移后通过固定随机种子 + 数值容差做等价性回归，保证与 MATLAB 版本结果一致。
- 本目录为论文配套代码，默认参数针对 50 台农机 / 150 块农田场景，可按实际规模调整 `model`。
