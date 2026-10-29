function cost = CostFunction(asg, model)
% Cost function for task allocation
% asg: assignment structure with agents tasks
% model: model structure with agents and tasks parameters

    N = length(asg.agents);
    vel = [model.agents(:).nom_vel];
    
    % F1 total travel distance
    F1 = 0;
    d_agent = zeros(1, N);
    d_agentback = zeros(1, N);
    
    for i = 1:N
        ntask = length(asg.agents(i).task);

        if ntask == 0
            d_agent(i) = 0;
            F1 = F1 + d_agent(i);
            continue;
        end

        vtask = asg.agents(i).task;
        taskID = vtask(1);
        d_agent(i) = 0;
        
        % 从车库到第一个任务
        d_agent(i) = d_agent(i) + Distance(model.agents(i).x, model.agents(i).y, ...
                                     model.tasks(taskID).x, model.tasks(taskID).y);
        
        % 任务间路程
        for j = 1:ntask
            prePos = taskID;
            taskID = vtask(j);
            if j > 1  % 不是第一个任务才计算任务间距离
                dis = Distance(model.tasks(prePos).x, model.tasks(prePos).y, ...
                               model.tasks(taskID).x, model.tasks(taskID).y);
                d_agent(i) = d_agent(i) + dis;
            end
        end
        
        % 最后一个任务返回车库
        d_agentback(i) = Distance(model.tasks(taskID).x, model.tasks(taskID).y, ...
                                   model.agents(i).x, model.agents(i).y);
        
        F1 = F1 + d_agent(i) + d_agentback(i);
    end

    % F2 time traveling
    times = zeros(1, N);
    
    for i = 1:N
        ntask = length(asg.agents(i).task);
        ttime = 0;
        
        % 纯作业时间（分钟）
        for j = 1:ntask
            taskid = asg.agents(i).task(j);
            % 作业时间 = 面积 / 作业能力，转换为分钟
            work_time_minutes = (model.tasks(taskid).S / model.agents(i).w) * 60;
            ttime = ttime + work_time_minutes;
        end

        % 路上时间（分钟） + 作业时间
        travel_time_minutes = (60 * d_agent(i) / vel(i)) + (60 * d_agentback(i) / vel(i));
        times(i) = travel_time_minutes + ttime;
    end
    
    F2 = max(times);  % 机群作业时间 = 用时最长农机的作业时间（分钟）
    
    % 总代价：归一化处理
    cost = 0.1 * F1 + 0.1 * F2;

end