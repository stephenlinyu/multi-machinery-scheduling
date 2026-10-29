import pathlib
import sys

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[1]
TESTS = pathlib.Path(__file__).resolve().parent
for p in (str(ROOT), str(TESTS)):
    if p not in sys.path:
        sys.path.insert(0, p)

from helpers import build_model, machine, field  # noqa: E402


@pytest.fixture
def single_model():
    return build_model([machine('M1')], [field('F1')])


@pytest.fixture
def two_by_two():
    return build_model(
        [machine('M1', 0, 0), machine('M2', 2, 0)],
        [field('F1', 1, 0), field('F2', 3, 0)],
    )


@pytest.fixture
def three_by_five():
    return build_model(
        [machine('M1', 0, 0), machine('M2', 2, 0), machine('M3', 4, 0)],
        [
            field('F1', 1, 0), field('F2', 3, 0), field('F3', 5, 0),
            field('F4', 1, 2), field('F5', 3, 2),
        ],
    )
