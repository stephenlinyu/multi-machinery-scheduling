
% Initialize some assignment
% InitAssignment 函数通常用于初始化种群中的个体，即生成初始的任务分配方案。
% 在多机器人任务分配（MRTA）问题中，这意味着为每个机器人（或代理）分配一个初始的任务集合。
% 这个初始分配是随机的，目的是为算法提供一个起点，以便算法可以通过迭代过程（如选择、交叉和变异）来改进这些方案。
% 通过随机生成任务分配方案来启动搜索过程，并在整个算法执行过程中提供新的个体以维持种群的多样性和探索能力

function pop = InitAssignment(model)  % 函数接受一个参数model，这个参数包含了智能体和任务的模型信息。函数的输出pop是一个初始化的任务分配方案
 
    %set of available tasks
    avai_tasks = [];   % 初始化一个空数组avai_tasks，用于存储所有可用的任务ID

    for i = 1:model.M
        avai_tasks = [avai_tasks, model.tasks(i).id];  % 每个任务的ID添加到avai_tasks数组中
    end

    % avai_tasks

    for i=1:(model.N-1)  % for each agent 最后一个智能体会被单独处理

        pop.agents(i).task = [];  % 初始化当前智能体i的任务列表为空
        if (length(avai_tasks) < 2)  
            continue;        % 任务少于2，跳出循环
        end
        num_tasks = randi([1 (length(avai_tasks)-1)]); % 随机生成一个整数num_tasks，表示当前智能体将被分配的任务数量

        for j = 1:num_tasks
            pr = randi([1,length(avai_tasks)]);  % 随机选择一个任务ID
            pop.agents(i).task = [pop.agents(i).task, avai_tasks(pr)];  % 将选中的任务ID添加到当前智能体的任务列表中
            avai_tasks = avai_tasks([1:pr-1, pr+1:end]);  % 从avai_tasks中移除已分配的任务ID，确保任务不会被重复分配
        end
    end

    % pop.agent[i] = task vector
    pop.agents(model.N).task = avai_tasks;  % 最后一个智能体分配剩余的所有任务

end