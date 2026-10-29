function PlotAssignmentsWithComparison(model, sol, figureID, failed_agent, new_task_ids, agent_positions, failure_position, completed_per_agent)
% 绘制任务分配路径图（完整路径：车库 -> 已完成任务 -> 未完成任务 -> 车库/故障点）
% 输入：
%   model: 模型数据
%   sol: 当前任务分配方案（只包含未完成任务）
%   figureID: 图形窗口编号
%   failed_agent: 故障农机编号（传入-1表示无故障）
%   new_task_ids: 新增任务ID数组（传入[]表示无新增任务）
%   agent_positions: 农机位置信息结构体（包含当前位置和状态）
%   failure_position: 故障位置 [x, y]（可选）
%   completed_per_agent: 每个农机已完成的任务ID列表（cell数组，按完成顺序）

% 设置默认参数
if nargin < 8 || isempty(completed_per_agent)
    completed_per_agent = cell(1, length(model.agents));
end
if nargin < 4 || isempty(failed_agent)
    failed_agent = -1;
end
if nargin < 5 || isempty(new_task_ids)
    new_task_ids = [];
end
if nargin < 6 || isempty(agent_positions)
    agent_positions = [];
end
if nargin < 7 || isempty(failure_position)
    failure_position = [];
end

% Set plotting parameters
figure(figureID);
clf;
hold on;

offset = (model.XMAX - model.XMIN)/100;
Cmap = colormap(lines(100));
linS = {'-', '-.', '--', ':'};

% 获取故障农机的未完成任务（用于图例）
failed_uncompleted_tasks = [];
if failed_agent > 0 && ~isempty(agent_positions) && failed_agent <= length(agent_positions)
    if isfield(agent_positions(failed_agent), 'uncompleted_tasks')
        failed_uncompleted_tasks = agent_positions(failed_agent).uncompleted_tasks;
    end
end

% ========== 1. 绘制车库位置（用金色五角星）==========
garage_positions = [];
for n = 1:length(model.agents)
    garage_x = model.agents(n).x;
    garage_y = model.agents(n).y;
    
    is_unique = true;
    for i = 1:size(garage_positions, 1)
        if abs(garage_positions(i,1) - garage_x) < 0.01 && abs(garage_positions(i,2) - garage_y) < 0.01
            is_unique = false;
            break;
        end
    end
    
    if is_unique
        garage_positions = [garage_positions; garage_x, garage_y];
    end
end

for i = 1:size(garage_positions, 1)
    plot(garage_positions(i,1), garage_positions(i,2), 'p', ...
         'Color', [1 0.8 0], ...
         'MarkerSize', 15, ...
         'MarkerFaceColor', [1 0.8 0], ...
         'LineWidth', 2);
    text(garage_positions(i,1) + offset, garage_positions(i,2) + offset, ...
         '车库', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.8 0.6 0]);
end

% ========== 2. 绘制所有任务点（区分已完成/未完成/新增/故障未完成）==========
for m = 1:length(model.tasks)
    % 判断任务是否已完成（属于某个农机的 completed_per_agent）
    is_completed = false;
    for a = 1:length(completed_per_agent)
        if ismember(m, completed_per_agent{a})
            is_completed = true;
            break;
        end
    end
    
    is_new_task = ismember(m, new_task_ids);
    is_failed_uncompleted = ismember(m, failed_uncompleted_tasks);
    
    if is_completed
        % 已完成任务：绿色圆点，带勾标记
        plot(model.tasks(m).x, model.tasks(m).y, 'o', ...
             'Color', [0 0.6 0], ...
             'MarkerSize', 8, ...
             'MarkerFaceColor', [0.6 0.9 0.6], ...
             'LineWidth', 1.5);
        text(model.tasks(m).x + offset, model.tasks(m).y + offset, ...
             num2str(m), 'FontSize', 9, 'Color', [0 0.5 0], 'FontWeight', 'bold');
        % 添加一个勾号标记
        text(model.tasks(m).x - offset*0.8, model.tasks(m).y - offset*0.8, ...
             '?', 'FontSize', 10, 'Color', [0 0.5 0], 'FontWeight', 'bold');
    elseif is_new_task
        % 新增任务：红色方块
        plot(model.tasks(m).x, model.tasks(m).y, 's', ...
             'Color', [1 0 0], ...
             'MarkerSize', 8, ...
             'MarkerFaceColor', [1 0.3 0.3], ...
             'LineWidth', 2);
        text(model.tasks(m).x + offset, model.tasks(m).y + offset, ...
             num2str(m), 'FontSize', 9, 'Color', [1 0 0], 'FontWeight', 'bold');
    elseif is_failed_uncompleted
        % 故障农机的未完成任务：红色菱形
        plot(model.tasks(m).x, model.tasks(m).y, 'd', ...
             'Color', [1 0 0], ...
             'MarkerSize', 8, ...
             'MarkerFaceColor', [1 0.5 0.5], ...
             'LineWidth', 2);
        text(model.tasks(m).x + offset, model.tasks(m).y + offset, ...
             num2str(m), 'FontSize', 9, 'Color', [1 0 0], 'FontWeight', 'bold');
    else
        % 普通未完成任务：灰色方块
        plot(model.tasks(m).x, model.tasks(m).y, 's', ...
             'Color', [0.5 0.5 0.5], ...
             'MarkerSize', 8, ...
             'MarkerFaceColor', [0.5 0.5 0.5]);
        text(model.tasks(m).x + offset, model.tasks(m).y + offset, ...
             num2str(m), 'FontSize', 8, 'Color', 'black');
    end
end

% ========== 3. 绘制农机和路径（使用完整任务序列）==========
for n = 1:length(model.agents)
    is_failed = (failed_agent > 0 && n == failed_agent);
    
    % 农机车库位置
    garage_x = model.agents(n).x;
    garage_y = model.agents(n).y;
    
    % 绘制农机标记
    if is_failed
        plot(garage_x, garage_y, 'x', ...
             'Color', [1 0 0], ...
             'MarkerSize', 15, ...
             'LineWidth', 3);
        text(garage_x + offset, garage_y + offset, ...
             [num2str(n) '(故障)'], 'FontSize', 11, 'FontWeight', 'bold', 'Color', [1 0 0]);
    else
        plot(garage_x, garage_y, 'o', ...
             'Color', Cmap(mod(n, size(Cmap,1)) + 1, :), ...
             'MarkerSize', 10, ...
             'MarkerFaceColor', Cmap(mod(n, size(Cmap,1)) + 1, :));
        text(garage_x + offset, garage_y + offset, ...
             num2str(n), 'FontSize', 10, 'FontWeight', 'bold');
    end
    
    % 获取该农机的完整任务序列：已完成（按完成顺序） + 未完成（按 sol 中的顺序）
    completed = completed_per_agent{n};
    unfinished = sol.agents(n).task;
    full_tasks = [completed, unfinished];
    
    if isempty(full_tasks)
        continue;
    end
    
    % 过滤有效任务
    valid_tasks = full_tasks(full_tasks <= length(model.tasks));
    if isempty(valid_tasks)
        continue;
    end
    
    % 构建路径点（从车库出发）
    path_x = [garage_x];
    path_y = [garage_y];
    for j = 1:length(valid_tasks)
        task_id = valid_tasks(j);
        path_x = [path_x, model.tasks(task_id).x];
        path_y = [path_y, model.tasks(task_id).y];
    end
    
    if is_failed
        % 故障农机：不返回车库，终点停在故障位置
        if ~isempty(failure_position) && length(failure_position) == 2
            path_x = [path_x, failure_position(1)];
            path_y = [path_y, failure_position(2)];
        elseif ~isempty(agent_positions) && n <= length(agent_positions) && isfield(agent_positions(n), 'x')
            path_x = [path_x, agent_positions(n).x];
            path_y = [path_y, agent_positions(n).y];
        end
    else
        % 正常农机：返回车库
        path_x = [path_x, garage_x];
        path_y = [path_y, garage_y];
    end
    
    % 绘制路径
    if is_failed
        plot(path_x, path_y, 'r--', 'LineWidth', 1.5);
        plot(path_x(end), path_y(end), 'x', 'Color', 'r', 'MarkerSize', 12, 'LineWidth', 1.5);
    else
        plot(path_x, path_y, 'linestyle', linS{mod(n-1, length(linS)) + 1}, ...
             'color', Cmap(mod(n, size(Cmap,1)) + 1, :), ...
             'LineWidth', 1.5);
    end
    
    % 在路径上添加方向箭头（仅对非故障农机的路径段，或故障农机到故障点前的段）
    for j = 1:length(path_x)-1
        mid_x = (path_x(j) + path_x(j+1)) / 2;
        mid_y = (path_y(j) + path_y(j+1)) / 2;
        dx = path_x(j+1) - path_x(j);
        dy = path_y(j+1) - path_y(j);
        angle = atan2(dy, dx);
        
        if norm([dx, dy]) > 0.1
            if ~is_failed
                arrow_tip_x = mid_x + 0.15 * cos(angle);
                arrow_tip_y = mid_y + 0.15 * sin(angle);
                arrow_angle = pi/6;
                arrow_left_x = arrow_tip_x - 0.08 * cos(angle + arrow_angle);
                arrow_left_y = arrow_tip_y - 0.08 * sin(angle + arrow_angle);
                arrow_right_x = arrow_tip_x - 0.08 * cos(angle - arrow_angle);
                arrow_right_y = arrow_tip_y - 0.08 * sin(angle - arrow_angle);
                
                fill([arrow_tip_x, arrow_left_x, arrow_right_x], ...
                     [arrow_tip_y, arrow_left_y, arrow_right_y], ...
                     Cmap(mod(n, size(Cmap,1)) + 1, :), 'EdgeColor', 'none');
            elseif is_failed && j < length(path_x)-1
                arrow_tip_x = mid_x + 0.15 * cos(angle);
                arrow_tip_y = mid_y + 0.15 * sin(angle);
                arrow_angle = pi/6;
                arrow_left_x = arrow_tip_x - 0.08 * cos(angle + arrow_angle);
                arrow_left_y = arrow_tip_y - 0.08 * sin(angle + arrow_angle);
                arrow_right_x = arrow_tip_x - 0.08 * cos(angle - arrow_angle);
                arrow_right_y = arrow_tip_y - 0.08 * sin(angle - arrow_angle);
                
                fill([arrow_tip_x, arrow_left_x, arrow_right_x], ...
                     [arrow_tip_y, arrow_left_y, arrow_right_y], ...
                     [1 0.3 0.3], 'EdgeColor', 'none');
            end
        end
    end
end

% ========== 4. 添加图例 ==========
legend_handles = [];
legend_str = {};

h_garage = plot(NaN, NaN, 'p', 'Color', [1 0.8 0], 'MarkerFaceColor', [1 0.8 0], 'MarkerSize', 12);
legend_handles = [legend_handles, h_garage];
legend_str{end+1} = '车库';

h_completed = plot(NaN, NaN, 'o', 'Color', [0 0.6 0], 'MarkerFaceColor', [0.6 0.9 0.6]);
legend_handles = [legend_handles, h_completed];
legend_str{end+1} = '已完成任务';

h_unfinished = plot(NaN, NaN, 's', 'Color', [0.5 0.5 0.5], 'MarkerFaceColor', [0.5 0.5 0.5]);
legend_handles = [legend_handles, h_unfinished];
legend_str{end+1} = '未完成任务';

if ~isempty(new_task_ids)
    h_new_task = plot(NaN, NaN, 's', 'Color', [1 0 0], 'MarkerFaceColor', [1 0.3 0.3], 'MarkerSize', 12);
    legend_handles = [legend_handles, h_new_task];
    legend_str{end+1} = '新增任务';
end

if ~isempty(failed_uncompleted_tasks)
    h_failed_task = plot(NaN, NaN, 'd', 'Color', [1 0 0], 'MarkerFaceColor', [1 0.5 0.5], 'MarkerSize', 12);
    legend_handles = [legend_handles, h_failed_task];
    legend_str{end+1} = '故障农机未完成任务';
end

for n = 1:min(8, length(model.agents))
    if failed_agent > 0 && n == failed_agent
        h_failed = plot(NaN, NaN, 'x', 'Color', [1 0 0], 'MarkerSize', 12, 'LineWidth', 2);
        legend_handles = [legend_handles, h_failed];
        legend_str{end+1} = ['农机 ' num2str(n) ' (故障)'];
        
        h_failed_path = plot(NaN, NaN, 'r--', 'LineWidth', 2);
        legend_handles = [legend_handles, h_failed_path];
        legend_str{end+1} = ['农机 ' num2str(n) ' 路径(故障中断)'];
    else
        h_agent = plot(NaN, NaN, 'o', 'Color', Cmap(mod(n, size(Cmap,1)) + 1, :), ...
                       'MarkerFaceColor', Cmap(mod(n, size(Cmap,1)) + 1, :));
        legend_handles = [legend_handles, h_agent];
        legend_str{end+1} = ['农机 ' num2str(n)];
        
        h_line = plot(NaN, NaN, 'linestyle', linS{mod(n-1, length(linS)) + 1}, ...
                      'color', Cmap(mod(n, size(Cmap,1)) + 1, :), 'LineWidth', 2);
        legend_handles = [legend_handles, h_line];
        legend_str{end+1} = ['农机 ' num2str(n) ' 路径'];
    end
end

if ~isempty(legend_handles)
    legend(legend_handles, legend_str, 'Location', 'best', 'FontSize', 8);
end

% ========== 5. 设置图形属性 ==========
hold off;
xlabel('X 坐标 (km)');
ylabel('Y 坐标 (km)');
grid on;
axis equal;
xlim([model.XMIN - 0.5, model.XMAX + 0.5]);
ylim([model.YMIN - 0.5, model.YMAX + 0.5]);

info_text = sprintf('农机数: %d | 任务数: %d', length(model.agents), length(model.tasks));
if failed_agent > 0
    info_text = [info_text sprintf('\n故障农机: %d', failed_agent)];
    if ~isempty(failure_position)
        info_text = [info_text sprintf(' 故障位置(%.2f,%.2f)', failure_position(1), failure_position(2))];
    end
end
if ~isempty(new_task_ids)
    info_text = [info_text sprintf('\n新增任务: %s', num2str(new_task_ids))];
end
if ~isempty(failed_uncompleted_tasks)
    info_text = [info_text sprintf('\n未完成任务: %s', num2str(failed_uncompleted_tasks))];
end
text(model.XMIN, model.YMAX + 0.8, info_text, 'FontSize', 9, 'BackgroundColor', 'white');

end