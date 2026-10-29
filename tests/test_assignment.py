import random

from helpers import build_model, machine, field
from ga_solver.init_assignment import init_assignment


def _all_ids(asg):
    return sorted(t for a in asg['agents'] for t in a['task'])


def test_covers_all_tasks():
    random.seed(0)
    model = build_model(
        [machine(f'M{i}') for i in range(3)],
        [field(f'F{j}', j, 0) for j in range(10)],
    )
    asg = init_assignment(model)
    assert _all_ids(asg) == list(range(1, 11))


def test_task_ids_in_range():
    random.seed(0)
    model = build_model(
        [machine(f'M{i}') for i in range(3)],
        [field(f'F{j}', j, 0) for j in range(7)],
    )
    asg = init_assignment(model)
    for a in asg['agents']:
        for t in a['task']:
            assert 1 <= t <= 7


def test_single_agent_gets_all():
    random.seed(0)
    model = build_model([machine('M1')], [field(f'F{j}', j, 0) for j in range(5)])
    asg = init_assignment(model)
    assert sorted(asg['agents'][0]['task']) == [1, 2, 3, 4, 5]


def test_more_agents_than_tasks():
    random.seed(0)
    model = build_model(
        [machine(f'M{i}') for i in range(5)],
        [field('F1', 0, 0), field('F2', 1, 0)],
    )
    asg = init_assignment(model)
    assert len(asg['agents']) == 5
    assert _all_ids(asg) == [1, 2]
