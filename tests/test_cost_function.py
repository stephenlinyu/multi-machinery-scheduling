import pytest

from helpers import build_model, machine, field
from ga_solver.cost_function import cost_function


def test_single_task_coincident():
    """农机与农田重合：无转移距离，只有作业时间与能耗。"""
    model = build_model([machine('M1')], [field('F1')])
    cost, _, _, energy, times = cost_function({'agents': [{'task': [1]}]}, model)

    # 作业 7000/7000 = 1h，能耗 2L → cost = 0.42*0 + 0.56*2 + 0.42*60
    assert cost == pytest.approx(0.56 * 2 + 0.42 * 60, abs=1e-6)
    assert times[0] == pytest.approx(1.0, abs=1e-9)
    assert energy == pytest.approx(0.06 * 2, abs=1e-9)


def test_transfer_flat():
    """1km 平路往返：去 + 回各 1km，T=0.5h 转移 + 1h 作业。"""
    model = build_model([machine('M1', 0, 0, 300)], [field('F1', 1, 0, 300)])
    cost, _, _, _, times = cost_function({'agents': [{'task': [1]}]}, model)

    # S=2, E=0.12；作业 1h/2L → T=1.5h, E=2.12
    assert cost == pytest.approx(0.42 * 2 + 0.56 * 2.12 + 0.42 * 90, abs=1e-6)
    assert times[0] == pytest.approx(1.5, abs=1e-9)


def test_transfer_downhill():
    """去程下坡、回程上坡：坡度影响能耗率与速度。"""
    model = build_model([machine('M1', 0, 0, 400)], [field('F1', 1, 0, 300)])
    cost, _, _, _, times = cost_function({'agents': [{'task': [1]}]}, model)

    eps_down = 0.06 * (1 + 4 * -0.1)          # 0.036 L/km
    v_down = min(30, 0.06 * 4 / eps_down)     # 6.6667 km/h
    eps_up = 0.06 * (1 + 20 * 0.1)            # 0.18 L/km
    v_up = min(30, 0.06 * 4 / eps_up)         # 1.3333 km/h
    t_transfer = 1 / v_down + 1 / v_up
    t_total = t_transfer + 1.0
    e_total = eps_down + eps_up + 2.0
    expected = 0.42 * 2 + 0.56 * e_total + 0.42 * 60 * t_total

    assert cost == pytest.approx(expected, abs=1e-6)
    assert times[0] == pytest.approx(t_total, abs=1e-9)


def test_empty_assignment():
    model = build_model([machine('M1')], [field('F1')])
    cost, _, _, _, times = cost_function({'agents': [{'task': []}]}, model)
    assert cost == 0
    assert times == [0.0]


def test_agent_times_length():
    model = build_model(
        [machine('M1', 0, 0), machine('M2', 2, 0)],
        [field('F1', 1, 0), field('F2', 3, 0)],
    )
    _, _, _, _, times = cost_function({'agents': [{'task': [1]}, {'task': [2]}]}, model)
    assert len(times) == 2
    assert all(t >= 0 for t in times)


def test_zero_area():
    model = build_model([machine('M1')], [field('F1', S=0)])
    cost, _, _, _, times = cost_function({'agents': [{'task': [1]}]}, model)
    assert times[0] == pytest.approx(0.0)
    assert cost == pytest.approx(0.0)
