function assignment = InitAssignment(model)
    % 获取agent和task的数量
    N = model.N; % agent数量
    M = model.M; % task数量
    
    % 初始化assignment结构体
    assignment = struct('agents', repmat(struct('task', []), 1, N));
    
    % 用于标记已经被分配的task
    allocatedTasks = false(1, M);
    
    % 第一步：为每个agent分配一个最近的task
    for i = 1:N
        % 获取当前agent的起始位置
        agentX = model.agents(i).x;
        agentY = model.agents(i).y;
        
        % 初始化最小距离为无穷大
        minDist = inf;
        closestTask = -1;
        
        % 遍历所有task，找到最近的未分配task
        for j = 1:M
            if ~allocatedTasks(j) % 检查task是否已被分配
                % 计算当前task到agent的距离
                taskX = model.tasks(j).x;
                taskY = model.tasks(j).y;
                dist = Distance(agentX, agentY, taskX, taskY);
                
                % 如果当前task更近，则更新最近task
                if dist < minDist
                    minDist = dist;
                    closestTask = j;
                end
            end
        end
        
        % 如果找到了最近的task，则分配给当前agent
        if closestTask ~= -1
            assignment.agents(i).task = closestTask;
            allocatedTasks(closestTask) = true; % 标记task为已分配
        end
    end
    
    % 第二步：将剩余的task随机分配给agent，优先分配给任务较少的agent
    remainingTasks = find(~allocatedTasks); % 找到所有未分配的task
    
    while ~isempty(remainingTasks)
        % 找到当前任务最少的agent
        taskCounts = arrayfun(@(x) length(x.task), assignment.agents); % 每个agent的任务数量
        minTaskAgents = find(taskCounts == min(taskCounts)); % 找到任务最少的agent
        
        % 随机选择一个任务最少的agent
        selectedAgent = minTaskAgents(randi(length(minTaskAgents)));
        
        % 随机选择一个剩余的task
        selectedTask = remainingTasks(randi(length(remainingTasks)));
        
        % 将task分配给选中的agent
        assignment.agents(selectedAgent).task = [assignment.agents(selectedAgent).task, selectedTask];
        
        % 从剩余task列表中移除已分配的task
        remainingTasks = setdiff(remainingTasks, selectedTask);
    end
end