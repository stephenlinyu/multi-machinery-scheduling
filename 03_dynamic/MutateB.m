
% function y = MutateB(x, mu, m)  % x：一个个体（或称为染色体）,是当前的任务分配方案 mu：变异率  m：任务的总数  
% 
%     y = x;
%  
%     nagent = length(x.agents);
% 
% 
%         a = randi([1 nagent]);
%         b = randi([1 nagent]);
%         % disp('A: '+ a+ 'B: '+b);
% 
%         len_a = length(x.agents(a).task);
%         len_b = length(x.agents(b).task);
%         % disp("LengthA =  "+len_a+ " lengthB =  "+len_b);
% 
%         if(len_a < 2 && len_b >= 2)
%             % disp("len_b: "+len_b);
% 
%             pos = randi([1 len_b]); % 从代理 b 的任务列表中随机选择一个任务,pos代表被选中的任务索引
%             % disp("pos: "+pos);
%             
%             % add or change new task for agent a
%             y.agents(a).task = x.agents(b).task(pos); % 将代理 b 中随机选中的任务（由 pos 索引）赋值给代理 a 的任务列表
% 
%             % modify task for agent b 
%             if pos == len_b   % 判断pos 是否为任务列表中的最后一个元素的索引
%                 y.agents(b).task = [x.agents(b).task(1:(pos-1)), x.agents(a).task];
%             elseif pos == 1
%                 y.agents(b).task = [x.agents(a).task, x.agents(b).task((pos+1):end)];
%             else
%                 y.agents(b).task = [x.agents(b).task(1:(pos-1)), x.agents(a).task, x.agents(b).task((pos+1):end)];
%             end  % 变异操作有助于探索新的可能解，增加种群的多样性
%             
%         elseif(len_b < 2 && len_a >= 2)
%             % disp("len_a: "+len_a);
% 
%             pos = randi([1 len_a]);
%             % disp("pos: "+pos);
%             
%             % add or change new task for agent b
%             y.agents(b).task = x.agents(a).task(pos);
% 
%             % modify task for agent a
%             if pos == len_a
%                 y.agents(a).task = [x.agents(a).task(1:(pos-1)), x.agents(b).task];
%             elseif pos == 1
%                 y.agents(a).task = [x.agents(b).task, x.agents(a).task((pos+1):end)];
%             else
%                 y.agents(a).task = [x.agents(a).task(1:(pos-1)), x.agents(b).task, x.agents(a).task((pos+1):end)];
%             end
%             
%         elseif(len_a < 2 && len_b < 2)
% 
%             y.agents(a).task = x.agents(b).task;
%             y.agents(b).task = x.agents(a).task;
%         
%         else
%     
%             pos1 = randi([1 len_a]);
%             pos2 = randi([1 len_b]);
%             % disp("Pos1 = "+pos1+" pos2 = "+pos2);
%     
%             y.agents(a).task(pos1) = x.agents(b).task(pos2);
%             y.agents(b).task(pos2) = x.agents(a).task(pos1);
%         end
%     
% end
function y = MutateB(x,~)
    % 获取代理数量
    nagent = length(x.agents);
    y = x; % 初始化变异后的个体

    % 随机选择两个不同的代理
    a = randi([1 nagent]);
    b = randi([1 nagent]);
    while a == b
        b = randi([1 nagent]); % 确保 a 和 b 不相同
    end

    % 获取两个代理的任务列表长度
    len_a = length(x.agents(a).task);
    len_b = length(x.agents(b).task);

    % 如果两个代理的任务列表都不为空，则进行任务交换
    if len_a > 0 && len_b > 0
        % 随机选择两个代理中的任务
        pos_a = randi([1 len_a]);
        pos_b = randi([1 len_b]);

        % 交换两个代理的任务
        temp = y.agents(a).task(pos_a);
        y.agents(a).task(pos_a) = y.agents(b).task(pos_b);
        y.agents(b).task(pos_b) = temp;
    end
end