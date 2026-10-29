

function available_tasks = findTasksInOtherAgents(individual, exclude_agent, mode)
    % 智能查找其他机器中的任务
    % mode: 'add'--为目标农机增加任务; 'reduce'--为其他农机减少任务
    
    N = length(individual.agents);
    
    % 计算所有农机的负载
    loads = zeros(1, N);
    for i = 1:N
        loads(i) = length(individual.agents(i).task);
    end
    
    target_load = loads(exclude_agent);
    available_tasks = [];
    
    for i = 1:N
        if i ~= exclude_agent
            current_tasks = individual.agents(i).task;
            current_load = loads(i);
            
            % 根据模式智能选择任务
            if nargin < 3 || isempty(mode)
                % 默认模式：收集所有任务（向后兼容）
                available_tasks = [available_tasks, current_tasks];
            elseif strcmp(mode, 'add') && current_load > target_load
                % 增加模式：只从负载较高的农机中选择
                available_tasks = [available_tasks, current_tasks];
            elseif strcmp(mode, 'reduce') && current_load < target_load
                % 减少模式：只从负载较低的农机中选择
                available_tasks = [available_tasks, current_tasks];
            end
        end
    end
    
    available_tasks = unique(available_tasks);
end