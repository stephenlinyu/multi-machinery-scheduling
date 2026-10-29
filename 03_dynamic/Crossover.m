

function y1 = Crossover(x1, x2, model)
    m = model.M; % 任务总数
    n = length(x1.agents); % 智能体数量

    % 初始化子代
    y1 = struct('agents', repmat(struct('task', []), 1, n));
    
%     for o=1:n
%     disp(['O1Agent ', num2str(o), ' tasks: ', num2str(x1.agents(o).task)]);
%     end  % for text
%     for o=1:n
%     disp(['O2Agent ', num2str(o), ' tasks: ', num2str(x2.agents(o).task)]);
%     end  % for text
    
    % 初始化已分配任务列表
    allocatedTasks = false(1, m);

    % 循环 n 次，为每个智能体执行交叉操作
    for k = 1:n
        % 根据概率选择父代
        Rr = rand;
        if Rr < 0.5
            selectedAgent = x1.agents(k);
        else
            selectedAgent = x2.agents(k);
        end

        % 将选中的父代智能体片段内的任务复制给子代的第 k 个智能体
        y1.agents(k).task = selectedAgent.task;

        % 标记已分配的任务
        allocatedTasks(selectedAgent.task) = true;
        % 从两个父代中删除已分配的任务
    for i = 1:2
        for j = 1:n
            if i == 1
                x1.agents(j).task = setdiff(x1.agents(j).task, find(allocatedTasks));
            else
                x2.agents(j).task = setdiff(x2.agents(j).task, find(allocatedTasks));
            end
        end
    end
    
    end

%     for o=1:n
%     disp(['O1Agent ', num2str(o), ' tasks: ', num2str(x1.agents(o).task)]);
%     end  % for text
%     for o=1:n
%     disp(['O2Agent ', num2str(o), ' tasks: ', num2str(x2.agents(o).task)]);
%     end  % for text
%     for o=1:n
%     disp(['yAgent ', num2str(o), ' tasks: ', num2str(y1.agents(o).task)]);
%     end  % for text
    
    % 找出两个父代中剩余的任务
    remainingTasks = find(~allocatedTasks);

     for i = 1:n
        if isempty(y1.agents(i).task)
            % 如果智能体没有任务，随机分配一个剩余的任务
            if ~isempty(remainingTasks)
                task = remainingTasks(randi(length(remainingTasks)));
                y1.agents(i).task = task;
                allocatedTasks(task) = true; % 标记为已分配
                remainingTasks = setdiff(remainingTasks, task); % 更新剩余任务列表
            end
        end
     end
    
    % 将剩余的任务随机地插入到子代的任务中
    for task = remainingTasks
        agentIndex = randi(n);
        while ismember(task, y1.agents(agentIndex).task)
            agentIndex = randi(n); % 确保选择的智能体没有这个任务
        end
        insertPosition = randi([1, length(y1.agents(agentIndex).task) + 1]);
        y1.agents(agentIndex).task = insertTaskAtIndex(y1.agents(agentIndex).task, task, insertPosition);
    end
    
%     for o=1:n
%     disp(['O1Agent ', num2str(o), ' tasks: ', num2str(x1.agents(o).task)]);
%     end  % for text
%     for o=1:n
%     disp(['O2Agent ', num2str(o), ' tasks: ', num2str(x2.agents(o).task)]);
%     end  % for text
%     for o=1:n
%     disp(['yAgent ', num2str(o), ' tasks: ', num2str(y1.agents(o).task)]);
%     end  % for text

%     for k = 1:n
%         disp(['Agent ', num2str(k), ' tasks: ', num2str(y1.agents(k).task)]);
%     end
end


