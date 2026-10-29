classdef DisturbanceEvaluator < handle
    properties
        % 单纯形-格子设计
        w1 = 0.2; w2 = 0.3; w3 = 0.4; w4 = 0.1;   
%         w1 = 1; w2 = 0; w3 = 0; w4 = 0;   % 纯任务
%         w1 = 0; w2 = 1; w3 = 0; w4 = 0;   % 纯能力
%         w1 = 0; w2 = 0; w3 = 1; w4 = 0;   % 纯空间
%         w1 = 0; w2 = 0; w3 = 0; w4 = 1;   % 纯频率

%         w1 = 0.5; w2 = 0.5; w3 = 0; w4 = 0;  
%         w1 = 0.5; w2 = 0; w3 = 0.5; w4 = 0;  
%         w1 = 0.5; w2 = 0; w3 = 0; w4 = 0.5;  
%         w1 = 0; w2 = 0.5; w3 = 0.5; w4 = 0;  
%         w1 = 0; w2 = 0.5; w3 = 0; w4 = 0.5;   
%         w1 = 0; w2 = 0; w3 = 0.5; w4 = 0.5;   
        
        T_base = 10; T_min = 5; T_max = 30;        % 冷却时间参数（分钟）- 适配 10-75 分钟时间线
        buffer_max_size = 10; buffer_max_wait = 15; buffer_batch_size = 3;  % 缓冲参数
        disturbance_history = []; event_buffer = [];
        last_global_replan_time = -inf;
        time_window = 10;           % 频率计算时间窗口（分钟）- 10分钟
        freq_threshold = 3;         % 频率阈值（次/窗口）- 10分钟内3次即为高频
    end
    
    methods
        function obj = DisturbanceEvaluator(varargin)
            if nargin >= 4
                obj.w1 = varargin{1}; obj.w2 = varargin{2};
                obj.w3 = varargin{3}; obj.w4 = varargin{4};
            end
        end
        
function [DI, delta_task, delta_cap, delta_spatial, delta_freq] = ...
        computeDisturbanceIndex(obj, event, current_sol, model, agent_positions, current_time)
    % 计算四维扰动指数（任务、能力、空间、频率）
    if nargin < 6
        current_time = 0;
        if isstruct(event) && isfield(event, 'current_time')
            current_time = event.current_time;
        end
    end
    
    % ---- 1. 任务扰动维度（改进版） ----
% 统计当前未完成任务总数
total_uncompleted = 0;
for i = 1:length(current_sol.agents)
    total_uncompleted = total_uncompleted + length(current_sol.agents(i).task);
end

% 统计已完成任务总数（从agent_positions获取）
total_completed = 0;
if exist('agent_positions', 'var') && ~isempty(agent_positions)
    for i = 1:length(agent_positions)
        if isfield(agent_positions(i), 'completed_tasks')
            total_completed = total_completed + length(agent_positions(i).completed_tasks);
        end
    end
end

% 总任务数
total_tasks = total_uncompleted + total_completed;

N_new = 0;
if isstruct(event) && isfield(event, 'type') && ...
   (strcmp(event.type, 'new_tasks') || strcmp(event.type, 'both'))
    if isfield(event, 'task_ids') && ~isempty(event.task_ids)
        N_new = length(event.task_ids);
    end
end

N_reassign = 0;
if isstruct(event) && isfield(event, 'type') && ...
   (strcmp(event.type, 'failure') || strcmp(event.type, 'both'))
    failure_agent = -1;
    if isfield(event, 'failure_agent')
        failure_agent = event.failure_agent;
    end
    if failure_agent > 0 && failure_agent <= length(current_sol.agents)
        if ~isempty(current_sol.agents(failure_agent).task)
            N_reassign = length(current_sol.agents(failure_agent).task);
        end
    end
end

total_change = N_new + N_reassign;

if total_tasks == 0
    delta_task = min(1, total_change / max(1, N_new));  % 纯新增任务
elseif total_change == 0
    delta_task = 0;
else
    % 方法：基于变化量占总任务数的比例，但使用非线性映射
    ratio = total_change / max(1, total_tasks);
    
    % 指数映射（推荐）：让小变化也有明显影响
    delta_task = ratio^0.6;
    
    % 限制范围，确保至少0.05的基准扰动
    delta_task = min(1, max(0.05, delta_task));
    
end
    
 % ---- 2. 能力扰动维度（简洁版） ----
% 基于：①被影响任务的总面积 ②故障农机未执行任务个数

% 统计所有任务的总面积
total_area = 0;
for i = 1:length(model.tasks)
    if isfield(model.tasks(i), 'S')
        total_area = total_area + model.tasks(i).S;
    end
end

if total_area == 0
    delta_cap = 0;
    return;
end

% 收集受影响的面积和任务数量
affected_area = 0;
affected_task_count = 0;

% 处理故障事件
if isstruct(event) && isfield(event, 'type') && ...
   (strcmp(event.type, 'failure') || strcmp(event.type, 'both'))
    failure_agent = event.failure_agent;
    if failure_agent > 0 && failure_agent <= length(current_sol.agents)
        uncompleted_tasks = current_sol.agents(failure_agent).task;
        for tid = uncompleted_tasks
            if tid <= length(model.tasks) && isfield(model.tasks(tid), 'S')
                affected_area = affected_area + model.tasks(tid).S;
                affected_task_count = affected_task_count + 1;
            end
        end
    end
end

% 处理新增任务
if isstruct(event) && isfield(event, 'type') && ...
   (strcmp(event.type, 'new_tasks') || strcmp(event.type, 'both'))
    if isfield(event, 'task_ids')
        for tid = event.task_ids
            if tid <= length(model.tasks) && isfield(model.tasks(tid), 'S')
                affected_area = affected_area + model.tasks(tid).S;
                affected_task_count = affected_task_count + 1;
            end
        end
    end
end

% 计算能力扰动
if affected_area == 0
    delta_cap = 0;
else
    % 面积占比 + 数量占比，各占50%
    area_ratio = affected_area / total_area;
    task_ratio = affected_task_count / max(1, length(model.tasks));
    delta_cap = 2 * area_ratio + 2 * task_ratio;
    delta_cap = min(1, max(0, delta_cap));
end
    
    % ---- 3. 空间扰动维度 ----
    all_tasks = [];
    if isstruct(event) && isfield(event, 'type')
        if (strcmp(event.type, 'new_tasks') || strcmp(event.type, 'both')) && isfield(event, 'task_ids')
            all_tasks = [all_tasks, event.task_ids];
        end
        if (strcmp(event.type, 'failure') || strcmp(event.type, 'both')) && isfield(event, 'failure_agent')
            fa = event.failure_agent;
            if fa > 0 && fa <= length(current_sol.agents) && ~isempty(current_sol.agents(fa).task)
                all_tasks = [all_tasks, current_sol.agents(fa).task];
            end
        end
    end
    all_tasks = unique(all_tasks);
    all_tasks = all_tasks(all_tasks <= length(model.tasks));
    
    if isempty(all_tasks)
        delta_spatial = 0;
    else
        total_dist = 0;
        valid_cnt = 0;
        for tid = all_tasks
            if tid > length(model.tasks), continue; end
            min_d = inf;
            for i = 1:length(agent_positions)
                if isfield(model.agents(i), 'available') && model.agents(i).available == 0
                    continue;
                end
                d = Distance(agent_positions(i).x, agent_positions(i).y, ...
                            model.tasks(tid).x, model.tasks(tid).y);
                if d < min_d, min_d = d; end
            end
            if isfinite(min_d)
                total_dist = total_dist + min_d;
                valid_cnt = valid_cnt + 1;
            end
        end
        if valid_cnt == 0
            delta_spatial = 0;
        else
            avg_dist = total_dist / valid_cnt;
            d_max = sqrt((model.XMAX - model.XMIN)^2 + (model.YMAX - model.YMIN)^2);
            if d_max == 0, delta_spatial = 0;
            else delta_spatial = avg_dist / d_max; end
            delta_spatial = min(1, max(0, delta_spatial));
        end
    end
    
% ---- 4. 频率扰动维度 ----
% 使用独立持久变量存储历史，避免对象属性干扰
persistent freq_history
if isempty(freq_history)
    freq_history = [];  % 两列：[时间, 新增任务数]
end

% 获取当前事件新增任务数
current_new = 0;
if isfield(event, 'type') && ismember(event.type, {'new_tasks', 'both'})
    if isfield(event, 'task_ids')
        current_new = length(event.task_ids);
    end
end

% 添加当前记录
freq_history = [freq_history; current_time, current_new];

% 清理60分钟前的记录（避免无限增长）
freq_history = freq_history(freq_history(:,1) >= current_time - 60, :);

% 计算10分钟窗口内新增任务总数
window_start = current_time - 5;  % 固定5分钟窗口
window_data = freq_history(freq_history(:,1) >= window_start, :);
total_new_tasks = sum(window_data(:,2));  % 第二列求和

% 调试输出
% fprintf('频率调试: 当前时间=%.1f, 窗口[%.1f, %.1f], 窗口内新增任务总数=%d\n', ...
%     current_time, window_start, current_time, total_new_tasks);
% fprintf('历史记录(时间,新增数):\n');
% disp(freq_history);

% 对数映射
if total_new_tasks == 0
    delta_freq = 0;
else
    alpha = 0.1;
    max_tasks = 15;
    delta_freq = log(1 + alpha * total_new_tasks) / log(1 + alpha * max_tasks);
    delta_freq = min(1, delta_freq);
end

% fprintf('delta_freq = %.4f\n', delta_freq);

    % ---- 综合扰动指数 ----
    DI = obj.w1 * delta_task + obj.w2 * delta_cap + obj.w3 * delta_spatial + obj.w4 * delta_freq;
    DI = min(1, max(0, DI));
end        

function [strategy, use_buffer, DI] = selectStrategy(obj, event, current_sol, model, agent_positions, current_time)
            if nargin < 6
                current_time = 0;
                if isstruct(event) && isfield(event, 'current_time')
                    current_time = event.current_time;
                end
            end
            
            % 计算扰动指数（传入当前时间）
            [DI, ~, ~, ~, ~] = obj.computeDisturbanceIndex(event, current_sol, model, agent_positions, current_time);
            
            % 紧急任务判断
            is_emergency = false;
            if isstruct(event) && isfield(event, 'type')
                if strcmp(event.type, 'new_tasks') && isfield(event, 'task_ids')
                    for task_id = event.task_ids
                        if task_id <= length(model.tasks)
                            if isfield(model.tasks(task_id), 'S') && model.tasks(task_id).S > 2000
                                is_emergency = true;
                            end
                        end
                    end
                elseif (strcmp(event.type, 'failure') || strcmp(event.type, 'both')) && DI >= 0.6
                    is_emergency = true;
                end
            end
            
            % 冷却时间检查
            use_buffer = false;
            time_since_last = current_time - obj.last_global_replan_time;
            % 自适应冷却时间（可根据扰动密度调整）
            D = obj.calcDisturbanceDensity(current_time);
            beta_D = min(2.0, D * 10);
            T_cd = obj.T_base * (1 + beta_D);
            T_cd = max(obj.T_min, min(obj.T_max, T_cd));
            
            if time_since_last < T_cd && time_since_last >= 0 && ~is_emergency
                use_buffer = true;
                obj.event_buffer = [obj.event_buffer, event];
                if obj.shouldFlushBuffer(current_time)
                    obj.last_global_replan_time = current_time;
                    use_buffer = false;
                end
            else
                obj.last_global_replan_time = current_time;
            end
            
            % 分级响应（基于DI和紧急标志）
            if is_emergency || DI >= 0.6
                strategy = 'EMERGENCY';
            elseif DI >= 0.4 
                strategy = 'SEVERE';
            elseif DI >= 0.2
                strategy = 'MODERATE';
            else
                strategy = 'LIGHT';
            end
           
end
        
        function density = calcDisturbanceDensity(obj, current_time)
            if isempty(obj.disturbance_history)
                density = 0; return;
            end
            time_window = 30; % 过去30分钟
            count = sum(current_time - obj.disturbance_history <= time_window);
            density = count / time_window;
        end
        
        function should_flush = shouldFlushBuffer(obj, current_time)
            should_flush = false;
            if ~isempty(obj.event_buffer)
                first_event = obj.event_buffer(1);
                if isstruct(first_event) && isfield(first_event, 'current_time')
                    if current_time - first_event.current_time >= obj.buffer_max_wait
                        should_flush = true;
                        return;
                    end
                end
            end
            total_tasks = 0;
            for i = 1:length(obj.event_buffer)
                evt = obj.event_buffer(i);
                if isstruct(evt) && isfield(evt, 'type')
                    if strcmp(evt.type, 'new_tasks') && isfield(evt, 'task_ids')
                        total_tasks = total_tasks + length(evt.task_ids);
                    elseif strcmp(evt.type, 'failure')
                        total_tasks = total_tasks + 1;
                    end
                end
            end
            if total_tasks >= obj.buffer_batch_size
                should_flush = true;
            end
        end
        
        function [buffered_events, obj] = flushBuffer(obj)
            buffered_events = obj.event_buffer;
            obj.event_buffer = [];
        end
        
        function obj = reset(obj)
            obj.disturbance_history = [];
            obj.event_buffer = [];
            obj.last_global_replan_time = -inf;
        end
    end
end