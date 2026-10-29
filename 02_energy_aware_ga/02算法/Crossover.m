
% 教学式交叉（基于多片段知识块保留）
function y1 = Crossover(x1, x2, model, elite_teachers)
    N = length(x1.agents);  % 农机的数量
    M = model.M;            % 任务总数

    % 概率使用改进的教学模式，概率使用传统交叉模式
    if ~isempty(elite_teachers) && rand() < 0.5
        % === 改进的教学模式 ===
        teacher = elite_teachers{randi(length(elite_teachers))};
        student = x1; % 选择x1作为学生
        
        % 直接使用CostFunction计算教师的机器成本
        [~, teacher_agent_costs] = CostFunction(teacher, model);
        
        % 选择知识块：排除成本最高30%和最低30%，保留中间40%的片段
        non_zero_costs = teacher_agent_costs(teacher_agent_costs > 0);
        if ~isempty(non_zero_costs)
            [sorted_costs, sort_idx] = sort(non_zero_costs);
            valid_N = length(non_zero_costs);
            
            % 计算分段索引
            low_threshold_idx = max(1, ceil(valid_N * 0.3));    % 前30%边界
            high_threshold_idx = min(valid_N, floor(valid_N * 0.7));  % 后30%边界
            
            % 选择中间40%的片段作为知识块
            if low_threshold_idx <= high_threshold_idx
                middle_segment_relative = sort_idx(low_threshold_idx:high_threshold_idx);
                
                % 映射回原始索引
                original_indices = find(teacher_agent_costs > 0);
                middle_segment_idx = original_indices(middle_segment_relative);
            else
                middle_segment_idx = find(teacher_agent_costs > 0); % 如果分段无效，使用所有非零成本片段
            end
        else
            middle_segment_idx = find(teacher_agent_costs > 0); % 如果没有非零成本，使用空数组
        end
        
        knowledge_blocks = cell(1, length(middle_segment_idx));
        for i = 1:length(middle_segment_idx)
            machine_idx = middle_segment_idx(i);
            knowledge_blocks{i} = struct(...
                'machine', machine_idx, ...
                'tasks', teacher.agents(machine_idx).task);
        end
        
    else
        % === 传统交叉模式 ===
        y1 = TraditionalCrossover(x1, x2, model);
        return;
    end

    % 初始化子代
    y1 = struct('agents', repmat(struct('task', []), 1, N));
    allocatedTasks = false(1, M);

    % === 步骤1: 传授多片段知识块 ===
    knowledge_tasks = [];
    for i = 1:length(knowledge_blocks)
        machine_idx = knowledge_blocks{i}.machine;
        tasks = knowledge_blocks{i}.tasks;
        
        if ~isempty(tasks)
            y1.agents(machine_idx).task = tasks;
            allocatedTasks(tasks) = true;
            knowledge_tasks = union(knowledge_tasks, tasks);
        end
    end
    
    % === 步骤2: 从学生继承剩余任务 ===
    student_tasks = arrayfun(@(a) a.task, student.agents, 'UniformOutput', false);
    for i = 1:N
        student_tasks{i} = setdiff(student_tasks{i}, knowledge_tasks);
    end

    for agentIdx = 1:N
        if ismember(agentIdx, middle_segment_idx)
            continue;
        end
        
        student_agent_tasks = student_tasks{agentIdx};
        student_agent_tasks = setdiff(student_agent_tasks, find(allocatedTasks));
        
        y1.agents(agentIdx).task = student_agent_tasks;
        allocatedTasks(student_agent_tasks) = true;
        
        student_tasks{agentIdx} = [];
    end

    % === 步骤3: 处理剩余未分配的任务 ===
    remainingTasks = find(~allocatedTasks);
    for task = remainingTasks
        % 选择当前负载最轻的机器
        agent_loads = zeros(1, N);
        for i = 1:N
            agent_loads(i) = length(y1.agents(i).task);
        end
        
        [~, best_agent] = min(agent_loads);
        y1.agents(best_agent).task = sort([y1.agents(best_agent).task, task]);
        allocatedTasks(task) = true;
    end
    
    % 确保解的有效性
    y1 = resolveConflicts(y1, model);
end

% === 传统交叉函数 ===
function offspring = TraditionalCrossover(parent1, parent2, model)
    N = length(parent1.agents);
    M = model.M;
    
    offspring = struct('agents', repmat(struct('task', []), 1, N));
    allocated = false(1, M);
    
    % 均匀交叉
    for task = 1:M
        agent1 = findAgentWithTask(parent1, task);
        agent2 = findAgentWithTask(parent2, task);
        
        if rand() < 0.5
            target_agent = agent1;
        else
            target_agent = agent2;
        end
        
        offspring.agents(target_agent).task = ...
            sort([offspring.agents(target_agent).task, task]);
    end
    
    offspring = resolveConflicts(offspring, model);
end
