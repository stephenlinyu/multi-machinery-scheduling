function mutated = TeachingMutate_Adaptive(individual, teacher, model, iteration, max_iterations)
    % 简化的农机片段基因交换变异
    
    mutated = individual;
    N = length(mutated.agents);
    
    % 根据迭代次数确定变异片段数量
    if iteration < max_iterations * 0.3
        num_segments = max(2, round(N * 0.5));  % 早期：50%
    elseif iteration < max_iterations * 0.7
        num_segments = max(2, round(N * 0.3));  % 中期：30%
    else
        num_segments = max(2, round(N * 0.2));  % 后期：20%
    end
    
    num_segments = min(num_segments, N);
    
    if N < 2 || num_segments < 2
        return; % 农机数量不足，不进行变异
    end
    
    % 随机选择农机片段
    agents_to_mutate = randperm(N, num_segments);
    
    % 收集每个农机的一个随机任务
    tasks_to_swap = [];
    original_assignments = [];
    
    for i = 1:num_segments
        agent_idx = agents_to_mutate(i);
        tasks = mutated.agents(agent_idx).task;
        
        if ~isempty(tasks)
            % 随机选择一个任务
            task_idx = randi(length(tasks));
            selected_task = tasks(task_idx);
            
            tasks_to_swap = [tasks_to_swap, selected_task];
            original_assignments = [original_assignments, agent_idx];
            
            % 从原农机移除该任务
            mutated.agents(agent_idx).task(task_idx) = [];
        end
    end
    
    % 如果收集到足够多的任务进行交换
    if length(tasks_to_swap) >= 2
        % 随机重排任务顺序
        new_order = randperm(length(tasks_to_swap));
        shuffled_tasks = tasks_to_swap(new_order);
        
        % 将重排后的任务分配回农机
        for i = 1:length(original_assignments)
            agent_idx = original_assignments(i);
            if i <= length(shuffled_tasks)
                mutated.agents(agent_idx).task = sort([mutated.agents(agent_idx).task, shuffled_tasks(i)]);
            end
        end
    end
end