"""测试公共构造器：生成算法所需的农机 / 农田 / model 结构。"""


def machine(mid, x=0.0, y=0.0, h=300.0, nom_vel=4.0, fuel=0.06, fueltask=2.0, w=7000.0, depot_id=1):
    return {
        'id': mid,
        'x': float(x),
        'y': float(y),
        'h': float(h),
        'nom_vel': float(nom_vel),
        'fuel': float(fuel),
        'fueltask': float(fueltask),
        'w': float(w),
        'depot_id': int(depot_id),
    }


def field(fid, x=0.0, y=0.0, h=300.0, S=7000.0):
    return {
        'id': fid,
        'x': float(x),
        'y': float(y),
        'h': float(h),
        'S': float(S),
    }


def build_model(agents, tasks, mu_u=20, mu_d=4, v_max=30):
    """按 solver.py 的方式组装 model，供 cost_function 直接测试。"""
    if len(agents) >= 2:
        depots = [{'h': agents[0].get('h', 300)}, {'h': agents[-1].get('h', 300)}]
    else:
        depots = [{'h': agents[0].get('h', 300)}, {'h': agents[0].get('h', 310)}]
    return {
        'N': len(agents),
        'M': len(tasks),
        'mu_u': mu_u,
        'mu_d': mu_d,
        'v_max': v_max,
        'agents': agents,
        'tasks': tasks,
        'depots': depots,
    }
