import json
import random
from pathlib import Path

import pytest

from helpers import build_model, machine, field
from ga_solver import solve_schedule
from ga_solver.cost_function import cost_function
from ga_solver.init_assignment import init_assignment

DATA = Path(__file__).parent / 'data'

SMALL_MACHINES = [machine('M1', 0, 0), machine('M2', 2, 0)]
SMALL_FIELDS = [field('F1', 1, 0), field('F2', 3, 0), field('F3', 1, 2)]


def test_deterministic_seed():
    """同一随机种子下两次求解结果完全一致。"""
    a = solve_schedule(SMALL_MACHINES, SMALL_FIELDS, seed=42, max_iter=100)
    b = solve_schedule(SMALL_MACHINES, SMALL_FIELDS, seed=42, max_iter=100)
    assert a['total_cost'] == pytest.approx(b['total_cost'], abs=1e-9)
    assert [x['task_sequence'] for x in a['agents']] == [x['task_sequence'] for x in b['agents']]


def test_baseline():
    """与固定种子回归基线比对，防止代码改动导致结果漂移。"""
    baseline = json.loads((DATA / 'baseline_small.json').read_text(encoding='utf-8'))
    res = solve_schedule(
        SMALL_MACHINES, SMALL_FIELDS,
        seed=baseline['seed'], max_iter=baseline['max_iter'],
    )
    assert res['total_cost'] == pytest.approx(baseline['total_cost'], abs=1e-6)


def test_seed_stability():
    """不同种子下成本波动不超过 5%。"""
    costs = [
        solve_schedule(SMALL_MACHINES, SMALL_FIELDS, seed=s, max_iter=100)['total_cost']
        for s in (1, 2, 3)
    ]
    spread = (max(costs) - min(costs)) / min(costs)
    assert spread <= 0.05


def test_small_bruteforce():
    """2 台农机 3 块农田：穷举 8 种分配，GA 结果不应差于最差方案，且接近最优。"""
    model = build_model(SMALL_MACHINES, SMALL_FIELDS)
    best = float('inf')
    worst = float('-inf')
    for mask in range(1 << 3):
        agents = [{'task': []}, {'task': []}]
        for j in range(3):
            agents[(mask >> j) & 1]['task'].append(j + 1)
        cost = cost_function({'agents': agents}, model)[0]
        best = min(best, cost)
        worst = max(worst, cost)

    res = solve_schedule(SMALL_MACHINES, SMALL_FIELDS, seed=42, max_iter=100)
    assert res['total_cost'] <= worst
    assert res['total_cost'] <= best * 1.2


def test_convergence_vs_initial():
    """GA 最优成本不应高于随机初始分配的成本。"""
    model = build_model(SMALL_MACHINES, SMALL_FIELDS)
    random.seed(42)
    init = init_assignment(model)
    init_cost = cost_function(init, model)[0]

    res = solve_schedule(SMALL_MACHINES, SMALL_FIELDS, seed=42, max_iter=100)
    assert res['total_cost'] <= init_cost
