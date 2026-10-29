function resolved = resolveConflicts(individual, model)
    % 解析任务分配冲突（确保每个任务只分配一次）
    resolved = individual;
    task_count = zeros(1, model.M);
    
    % 统计每个任务出现的次数
    for i = 1:length(resolved.agents)
        tasks = resolved.agents(i).task;
        for j = 1:length(tasks)
            task_id = tasks(j);
            if task_id >= 1 && task_id <= model.M
                task_count(task_id) = task_count(task_id) + 1;
            end
        end
    end
    
    % 处理重复分配的任务
    duplicate_tasks = find(task_count > 1);
    for task = duplicate_tasks
        % 保留第一个出现的分配，移除其他重复分配
        found_first = false;
        for i = 1:length(resolved.agents)
            if ismember(task, resolved.agents(i).task)
                if found_first
                    resolved.agents(i).task = ...
                        setdiff(resolved.agents(i).task, task);
                else
                    found_first = true;
                end
            end
        end
    end
    
    % 处理未分配的任务
    missing_tasks = find(task_count == 0);
    for task = missing_tasks
        % 随机分配给一个机器
        agent_idx = randi(length(resolved.agents));
        resolved.agents(agent_idx).task = ...
            sort([resolved.agents(agent_idx).task, task]);
    end
    
    % 移除空任务和无效任务
    for i = 1:length(resolved.agents)
        valid_tasks = resolved.agents(i).task;
        valid_tasks = valid_tasks(valid_tasks >= 1 & valid_tasks <= model.M);
        resolved.agents(i).task = unique(valid_tasks);
    end
end