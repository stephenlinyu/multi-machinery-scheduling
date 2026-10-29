
function y = Mutate(x, ~)  % x：当前的任务分配方案, mu：变异率, m：任务的总数
    nagent = length(x.agents); % 获取农机的数量
    y = x; % 初始化变异后的方案为原始方案

    % 确保至少有两个农机有任务
    if nagent < 2  
        return; % 如果农机数量小于2或者所有农机都没有任务，则不进行变异
    end

    % 随机选择两个农机组，确保不选择同一个农机两次
    selected_agents = randperm(nagent, 2);
    donor_agent = selected_agents(1); % 转出组
    recipient_agent = selected_agents(2); % 转入组
%     for k=1:nagent
%     disp(['Agent ', num2str(k), ' tasks: ', num2str(y.agents(k).task)]);
%     end  % for text

    % 从转出组中随机选择一个任务
    if ~isempty(y.agents(donor_agent).task)
        task_to_transfer = y.agents(donor_agent).task(randi([1 length(y.agents(donor_agent).task)]));
    else
        return; % 如果转出组没有任务，则不进行变异
    end

    % 确保转入组至少有一个任务，以便有一个位置可以插入转出基因
    if isempty(y.agents(recipient_agent).task)
        return; % 如果转入组没有任务，则不进行变异
    end

    % 在转入组中随机选择一个位置插入转出基因
    insert_position = randi([1 length(y.agents(recipient_agent).task+1) ]);

    % 构建转入组的新任务列表
    new_task_list = [y.agents(recipient_agent).task(1:insert_position-1), task_to_transfer, y.agents(recipient_agent).task(insert_position:end)];

    % 更新转入组的任务列表
    y.agents(recipient_agent).task = new_task_list;

    % 从转出组中删除转出基因
    y.agents(donor_agent).task = y.agents(donor_agent).task(y.agents(donor_agent).task ~= task_to_transfer);

%     for k=1:nagent
%     disp(['Agent ', num2str(k), ' tasks: ', num2str(y.agents(k).task)]);
%     end  % for text
%     % 检查 taskID 是否为正整数
%     if ~isnumeric(task_to_transfer) || task_to_transfer <= 0 || mod(task_to_transfer, 1) ~= 0
%         error('taskID must be a positive integer.');
%     end
end
