% Cost function 

function [cost,gongxian] = CostFunction(asg, model) % asg表示任务分配方案，model表示模型参数

    N = length(asg.agents);   % 获取 asg 结构体中 agents 数组的长度
    % vel = 0.5*ones([1 N]); % velocity of the robots m/s
    vel = [model.agents(:).nom_vel];  % 访问model对象中的agents属性，获取每个agents的nom_vel(名义速度)(:)表所有
%     taskvel =[model.agents(:).vel_task]; % 每个任务所用的时间
%     agentw = [model.agents(:).wide]; % 每个机器的作业宽度
     % 确保 vel 数组的长度与 N 相匹配
     agentCosts=zeros(1, N);
    gongxian= zeros(1, N); % 存储每个个体中agent的贡献
    % F1 total travel distance
    F1 = 0;
    d_agent = zeros([1 N]);  % d_agent 是一个1行N列的数组，用于存储每个agent的行程距离，初始值为0   
    d_agentback = zeros([1 N]);
    for i = 1:N
        % Calculate traveling distance for each agent
        ntask = length(asg.agents(i).task);   % 访问asg对象中第i个agent的task属性,计算每个代理的行程距离,ntask 存储当前代理承担的任务数量。

        if(ntask == 0) % if no task assigned for that agent
            d_agent(i) = 0;
            F1 = F1 +d_agent(i);
            continue;
        end

        vtask = asg.agents(i).task; % get the task vector，行
        
        taskID = vtask(1);  %获取当前代理的任务列表，并记录第一个任务的 ID

        d_agent(i) = 0; % fitness function
        d_agentback(i) = 0;
%         disp(['taskID: ', num2str(taskID)]);
        d_agent(i) = d_agent(i) + Distance(model.agents(i).x, model.agents(i).y, ...  % ...用来连接两行的代码
                                     model.tasks(taskID).x, model.tasks(taskID).y); % from robot position to task 1;
        for j = 1: ntask  %遍历所有任务
            prePos = taskID;  %保留当前任务ID
            taskID = vtask(j);  % 更新当前任务ID
            % 检查 taskID 是否为正整数
            
% disp(['taskID: ', num2str(taskID)]);
            dis = Distance(model.tasks(prePos).x, model.tasks(prePos).y,  ...
                           model.tasks(taskID).x, model.tasks(taskID).y ); % distance from task to task
            d_agent(i) = d_agent(i) + dis;
        end
        d_agentback(i)=Distance(model.tasks(taskID).x, model.tasks(taskID).y, ...
                                model.agents(i).x, model.agents(i).y );
%         f1(i)=d_agent(i)+d_agentback(i);  %每个agent的行驶距离
        agentCosts(i) =  0.1 * (d_agent(i) + d_agentback(i));
        F1 = F1 +d_agent(i)+d_agentback(i);
%             F1 = F1 +d_agent(i);
    end

    % F2 time traveling
    F2 = 0;
    times  = zeros([1 N]);
%     % 定义任务面积的最小值和最大值
%       minArea = 1000; % 最小任务面积
%       maxArea = 1000; % 最大任务面积
    for i = 1:N
        ntask  = length(asg.agents(i).task);
        ttime = 0;
        % 纯作业时间
        for j = 1:ntask   %遍历任务
        taskid = asg.agents(i).task(j);  %分配给第i个agent的任务列表
%         tasks(m).S = randi([minArea, maxArea], 1, 1); % 随机生成任务面积
%         model.tasks(taskid).S = rand * (maxArea - minArea) + minArea;  
        model.tasks(taskid).duration = 60*(model.tasks(taskid).S / model.agents(i).w); % duration = S / w
        ttime = ttime + model.tasks(taskid).duration; % 每个农机的纯作业时间
        end

 % disp(['Length of d_agentback: ', num2str(length(d_agentback))]); % 测试

        times(i) = (60*d_agent(i)/vel(i)) + ttime + (60*d_agentback(i)/vel(i));
%         f2(i)=times(i);  %每个agent的时间
        agentCosts(i) = agentCosts(i) + 0.1 * times(i);
    end
    F2 = max(times);
    
     cost  = 0.1*F1 +0.1* F2 ;

         gongxian = agentCosts / cost;  %个体中每个agent的贡献
%          disp([ ' - Agent Contributions: ', num2str(gongxian)]);
%         disp([ ' - AgentCosts: ', num2str(agentCosts)]);
%         disp([ ' - Costs: ', num2str(cost)]);
end
