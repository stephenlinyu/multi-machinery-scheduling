"""生成回归基线：固定种子跑一次小规模调度，结果存入 baseline_small.json。

首次生成后作为回归基准提交；改动算法导致结果漂移时，测试会失败。
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / 'tests'))

from helpers import machine, field  # noqa: E402
from ga_solver import solve_schedule  # noqa: E402

MACHINES = [machine('M1', 0, 0), machine('M2', 2, 0)]
FIELDS = [field('F1', 1, 0), field('F2', 3, 0), field('F3', 1, 2)]

res = solve_schedule(MACHINES, FIELDS, seed=42, max_iter=100)

data = {
    'seed': 42,
    'max_iter': 100,
    'total_cost': res['total_cost'],
    'agents': res['agents'],
}

out = Path(__file__).parent / 'baseline_small.json'
out.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
print('wrote', out)
print('total_cost =', res['total_cost'])
