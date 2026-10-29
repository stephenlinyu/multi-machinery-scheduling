% calculate terrain-weighted distance (comprehensive transfer cost)
% 输入: 两点坐标(km)、海拔(m)，地形权重系数
% 输出: 综合转移成本(km)
function dis = TerrainDistance(x1, y1, h1, x2, y2, h2, beta_up, beta_down)
    
    % 平面欧氏距离 (km)
    d_plane = sqrt((x2 - x1)^2 + (y2 - y1)^2);
    
    % 高程差：转换为 km (m → km)
    delta_h = (h2 - h1) / 1000;
    
    % 地形加权距离（综合转移成本）
    if delta_h > 0
        % 上坡
        dis = d_plane + beta_up * delta_h;
    elseif delta_h < 0
        % 下坡
        dis = d_plane + beta_down * abs(delta_h);
    else
        % 平路
        dis = d_plane;
    end
    
end