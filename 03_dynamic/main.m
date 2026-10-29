clc;
clear;
close all;
% 清空所有 persistent 变量
clear functions;
%% Problem Definition
model = CreateModel();
for i = 1:length(model.agents)
    model.agents(i).available = 1;
end

CostFunc = @(x) CostFunction(x, model);

%% ========== 加载静态分配结果（固定结果）==========
% 如果存在保存的结果文件，直接加载；否则运行GA优化
if exist('static_result.mat', 'file')
    load('static_result.mat');
    fprintf('已加载静态分配结果，最优代价: %.4f\n', BestSol.Cost);
else
    error('未找到 static_result.mat，请先运行 SaveStaticResult.m 生成静态分配结果');
end

static_sol = BestSol.Position;
static_cost = BestSol.Cost;

fprintf('\n========== 静态分配结果 ==========\n');
fprintf('最优代价: %.4f\n\n', static_cost);
fprintf('静态分配农机任务详情:\n');
for i = 1:model.N
    if ~isempty(static_sol.agents(i).task)
        tasks = static_sol.agents(i).task;
        fprintf('  农机 %2d: 任务 %s\n', i, num2str(tasks));
    else
        fprintf('  农机 %2d: 无任务\n', i);
    end
end

%% ========== 动态场景定义（完整时间线）==========
% 事件结构：{time, type, failure_agent, task_list}
% 其中 task_list 为 [x, y, S] 的行矩阵，每行一个任务

events = {};
% 记录每个事件的 DI 值
event_di_values = [];
event_times = [];
event_types = {};
% ----- 低频轻微扰动期 -----
events{end+1} = struct('time', 10,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [3.2, 0.8, 850]);
events{end+1} = struct('time', 17,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [7.0, 0.5, 920]);
events{end+1} = struct('time', 23,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [9.0, 1.2, 780]);
events{end+1} = struct('time', 30,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [2.5, 2.8, 1100]);

% % ----- 高频连续扰动期 -----
events{end+1} = struct('time', 40,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [7.8, 2.5, 950; 9.2, 3.0, 1050]);
events{end+1} = struct('time', 42,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [ 1.2, 5.5, 2500]);
events{end+1} = struct('time', 43,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [3.8, 6.5, 1150; 6.5, 9.0, 890]); 
events{end+1} = struct('time', 45,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [5.0, 7.2, 720; 1.8, 0.2, 680]); 
events{end+1} = struct('time', 46,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [2.0, 8.5, 2380]);
events{end+1} = struct('time', 48,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [0.2 1.5 1250; 0.8, 8.2, 940]);
events{end+1} = struct('time', 50,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [3 2 825; 0.5 10 1400]); % 两个
% events{end+1} = struct('time', 75,  'type', 'failure',      'failure_agent', 4,  'task_list', []);   % 小型故障

% ----- 严重扰动爆发期 -----
events{end+1} = struct('time', 60,  'type', 'both', 'failure_agent', 1, 'task_list', ...
    [2.8 7.5 1430; 5.5 10 1800; 7.5 7.5 1020; 9.5 9.5 972; 9.7 5 1140; 10 0.1 800; 8.2 1.5 900 ]); % 7个大任务+农机1故障

% ----- 恢复平稳期 -----
events{end+1} = struct('time', 70,  'type', 'new_tasks', 'failure_agent', [], 'task_list', [9.8, 8.0, 830]);
events{end+1} = struct('time', 75, 'type', 'new_tasks', 'failure_agent', [], 'task_list', [4.2, 9.5, 760]);

% 按时间排序
[~, idx] = sort(cellfun(@(e)e.time, events));
events = events(idx);

%% 动态模拟
tic;
dynamic_model = model;          % 深拷贝模型（任务和农机可修改）
current_sol = static_sol;      % 从静态分配开始
total_comm = 0;
total_di_vals = [];

% 记录每个农机已完成的任务（初始为空）
completed_per_agent = cell(1, dynamic_model.N);

% 记录新增任务ID映射
next_task_id = dynamic_model.M + 1;

% 存储每个事件的详细信息用于绘图
event_records = struct('time', {}, 'type', {}, 'failed_agent', {}, 'new_task_ids', {}, ...
                       'agent_positions', {}, 'failure_position', {});

% 逐个处理事件
for evt_idx = 1:length(events)
    evt = events{evt_idx};
    current_time = evt.time;
    
    fprintf('\n========== 事件 %d (时间: %.1f 分钟) ==========\n', evt_idx, current_time);
    
    % 1. 获取当前时刻的农机位置和任务状态（不覆盖 current_sol）
    [~, ~, agent_positions, ~] = getRemainingTasksWithPosition(current_sol, dynamic_model, current_time);
    
    % 2. 更新已完成任务记录
    for i = 1:dynamic_model.N
        if ~isempty(agent_positions(i).completed_tasks)
            % 追加新完成的任务（去重）
            new_completed = setdiff(agent_positions(i).completed_tasks, completed_per_agent{i});
            completed_per_agent{i} = [completed_per_agent{i}, new_completed];
        end
    end
    
    % 3. 处理故障：标记农机不可用
    failed_agent_this = -1;
    failure_position_this = [];
    if strcmp(evt.type, 'failure') || strcmp(evt.type, 'both')
        fa = evt.failure_agent;
        if fa > 0 && fa <= length(dynamic_model.agents)
            dynamic_model.agents(fa).available = 0;
            failed_agent_this = fa;
            fprintf('  农机 %d 已标记为不可用\n', fa);
            
            % 记录故障位置（如果有）
            if fa <= length(agent_positions) && isfield(agent_positions(fa), 'failure_position')
                failure_position_this = agent_positions(fa).failure_position;
            end
        end
    end
    
    % 4. 处理新增任务：添加到 model.tasks
    new_task_ids_this = [];
    if strcmp(evt.type, 'new_tasks') || strcmp(evt.type, 'both')
        task_list = evt.task_list;
        if ~isempty(task_list)
            num_new = size(task_list, 1);
            new_task_ids_this = next_task_id : (next_task_id + num_new - 1);
            for t = 1:num_new
                new_task = struct();
                new_task.id = new_task_ids_this(t);
                new_task.kuan = 0;
                new_task.chang = 0;
                new_task.S = task_list(t, 3);
                new_task.duration = 0;
                new_task.x = task_list(t, 1);
                new_task.y = task_list(t, 2);
                new_task.status = 'pending';
                new_task.type = 1;
                dynamic_model.tasks(end+1) = new_task;
            end
            dynamic_model.M = length(dynamic_model.tasks);
            next_task_id = dynamic_model.M + 1;
            fprintf('  新增 %d 个任务: %s\n', num_new, mat2str(new_task_ids_this));
        end
    end
    
    % 5. 构造事件结构（用于动态分配）
    event_struct.type = evt.type;
    event_struct.current_time = current_time;
    event_struct.failure_agent = evt.failure_agent;
    event_struct.task_ids = new_task_ids_this;
    
    % 6. 调用动态分配
    DynamicCostFunc = @(x) CostFunction(x, dynamic_model);
    try
        [new_sol, comm, details, strategy, DI] = DynamicTaskAllocationWithResponse(...
            current_sol, dynamic_model, event_struct, DynamicCostFunc);
        current_sol = new_sol;
        total_comm = total_comm + comm;
        total_di_vals(end+1) = DI;
            % ===== 新增：记录 DI 值 =====
    event_di_values = [event_di_values, DI];
    event_times = [event_times, current_time];
    event_types{end+1} = evt.type;
        fprintf('  事件完成: 策略=%s, DI=%.4f, 通信=%d\n', strategy, DI, comm);
    catch ME
        fprintf('  动态分配出错: %s\n', ME.message);
        fprintf('  错误堆栈: %s\n', ME.getReport);
            % 即使出错也记录 DI=0
    event_di_values = [event_di_values, 0];
    event_times = [event_times, current_time];
    event_types{end+1} = [evt.type, '(error)'];
    end
    
    % 记录事件信息用于最终绘图
    event_records(evt_idx).time = current_time;
    event_records(evt_idx).type = evt.type;
    event_records(evt_idx).failed_agent = failed_agent_this;
    event_records(evt_idx).new_task_ids = new_task_ids_this;
    event_records(evt_idx).agent_positions = agent_positions;
    event_records(evt_idx).failure_position = failure_position_this;
end
elapsedTime = toc;
%% 最终结果展示
%% 最终结果展示
% 构建完整任务分配方案（已完成 + 未完成）
full_sol = struct('agents', struct('task', cell(1, dynamic_model.N)));
for i = 1:dynamic_model.N
    full_sol.agents(i).task = [completed_per_agent{i}, current_sol.agents(i).task];
end

% 使用完整方案计算最终代价
FinalCostFunc = @(x) CostFunction(x, dynamic_model);
dynamic_cost_complete = FinalCostFunc(full_sol);

fprintf('\n========== 动态模拟最终结果 ==========\n');
fprintf('总事件数: %d\n', length(events));
fprintf('总通信次数: %d\n', total_comm);
fprintf('静态分配代价: %.4f\n', static_cost);
fprintf('动态分配最终代价（基于完整任务序列）: %.4f\n', dynamic_cost_complete);
fprintf('动态分配时间: %.4f 秒\n', elapsedTime );
fprintf('代价变化: %.4f (%.2f%%)\n', dynamic_cost_complete - static_cost, ...
        (dynamic_cost_complete - static_cost) / static_cost * 100);

% 输出完整历史（已完成+未完成）
fprintf('\n最终农机任务分配（[]内为已完成任务）:\n');
for i = 1:dynamic_model.N
    completed_str = '';
    if ~isempty(completed_per_agent{i})
        completed_str = ['[' num2str(completed_per_agent{i}) ']'];
    end
    unfinished = current_sol.agents(i).task;
    unfinished_str = '';
    if ~isempty(unfinished)
        unfinished_str = num2str(unfinished);
    end
    if dynamic_model.agents(i).available == 0
        fprintf('  农机 %2d: (故障) 任务 %s %s\n', i, completed_str, unfinished_str);
    else
        fprintf('  农机 %2d: 任务 %s %s\n', i, completed_str, unfinished_str);
    end
end
%% ========== 输出所有 DI 值 ==========
fprintf('\n所有事件 DI 值: [');
for i = 1:length(event_di_values)
    if i < length(event_di_values)
        fprintf('%.4f, ', event_di_values(i));
    else
        fprintf('%.4f', event_di_values(i));
    end
end
fprintf(']\n');
%% ========== 绘图 ==========

% % 图1：静态任务分配迭代收敛曲线
% figure(1);
% plot(1:MaxIt, BestCost, 'b-', 'LineWidth', 2);
% xlabel('迭代次数');
% ylabel('最优代价');
% title('静态任务分配迭代收敛曲线');
% grid on;
% set(gca, 'FontSize', 10);
% 
% % 图2：静态任务分配路径图（故障前的分配）
% figure(2);
% PlotAssignmentsWithComparison(model, static_sol, 2, -1, [], [], []);
% title('静态任务分配路径图 (初始分配)');

% 图3：动态任务分配最终路径图
% 获取最后一次事件的信息用于绘图
last_event = event_records(end);
final_failed_agent = last_event.failed_agent;
final_new_task_ids = last_event.new_task_ids;
final_agent_positions = last_event.agent_positions;
final_failure_position = last_event.failure_position;

% 如果最后一个事件不是故障，但有之前的故障农机，需要找到最后一个故障的农机
if final_failed_agent == -1
    for i = length(event_records):-1:1
        if event_records(i).failed_agent > 0
            final_failed_agent = event_records(i).failed_agent;
            final_failure_position = event_records(i).failure_position;
            final_agent_positions = event_records(i).agent_positions;
            break;
        end
    end
end

% 收集所有新增任务ID
all_new_task_ids = [];
for i = 1:length(event_records)
    all_new_task_ids = [all_new_task_ids, event_records(i).new_task_ids];
end
all_new_task_ids = unique(all_new_task_ids);

figure(3);
PlotAssignmentsWithComparison(dynamic_model, current_sol, 3, ...
    final_failed_agent, all_new_task_ids, final_agent_positions, final_failure_position, completed_per_agent);
title('动态任务分配最终路径图 (含故障中断，已完成任务绿色标记)');

%% ========== DI 值变化曲线图 ==========
figure(4);
plot(event_times, event_di_values, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
hold on;

% 添加策略分界线（使用 line 替代 yline）
% 获取当前坐标轴范围
xlims = xlim;
ylims = ylim;

% 绘制水平线：EMERGENCY 阈值 0.6
line([xlims(1), xlims(2)], [0.6, 0.6], 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);
text(xlims(2) * 0.98, 0.62, 'EMERGENCY (0.6)', 'Color', 'r', 'FontSize', 9, 'HorizontalAlignment', 'right');

% 绘制水平线：SEVERE 阈值 0.4
line([xlims(1), xlims(2)], [0.4, 0.4], 'Color', 'g', 'LineStyle', '--', 'LineWidth', 1.5);
text(xlims(2) * 0.98, 0.42, 'SEVERE (0.4)', 'Color', 'g', 'FontSize', 9, 'HorizontalAlignment', 'right');

% 绘制水平线：MODERATE 阈值 0.2
line([xlims(1), xlims(2)], [0.2, 0.2], 'Color', 'm', 'LineStyle', '--', 'LineWidth', 1.5);
text(xlims(2) * 0.98, 0.22, 'MODERATE (0.2)', 'Color', 'm', 'FontSize', 9, 'HorizontalAlignment', 'right');

% 标记每个点
for i = 1:length(event_times)
    text(event_times(i), event_di_values(i) + 0.02, sprintf('E%d', i), ...
        'FontSize', 8, 'HorizontalAlignment', 'center');
end

xlabel('时间 (分钟)', 'FontSize', 12);
ylabel('扰动指数 (DI)', 'FontSize', 12);
title('DI 值随时间变化曲线', 'FontSize', 14);
grid on;
legend('DI值', 'EMERGENCY (0.6)', 'SEVERE (0.4)', 'MODERATE (0.2)', 'Location', 'best');
hold off;
