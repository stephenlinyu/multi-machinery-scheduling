function [best_sol, best_cost] = VNS_TabuSearch(initial_sol, warm_start_sol, model, costFunc, DI, max_iterations)
% 变邻域禁忌搜索算法 - 论文算法3和第3.2节
% 包含：热启动策略、动态邻域破坏修复、多邻域结构、禁忌搜索协同

    fprintf('\n========== 变邻域禁忌搜索算法 ==========\n');
    fprintf('扰动指数 DI = %.4f\n', DI);
    
    % 步骤1：热启动初始化（论文3.2.2节）
    if ~isempty(warm_start_sol)
        fprintf('步骤1: 热启动 - 融合上一时刻最优解\n');
        sol = mergeSolutions(warm_start_sol, initial_sol, model);
    else
        fprintf('步骤1: 无热启动解，使用初始解\n');
        sol = initial_sol;
    end
    
    best_sol = sol;
    best_cost = costFunc(sol);
    
    % 步骤2：参数自适应设置（论文3.2.6节）
    if DI >= 0.6  
        K_max = max_iterations;
        L_tabu = 30;
        destroy_ratio = 0.8;
        neighbor_set = {'N1', 'N2', 'N3', 'N4', 'N5', 'N6'};
        use_destroy_repair = true;
        fprintf('参数设置: EMERGENCY - 迭代数=%d, 禁忌步长=%d, 破坏比例=%.1f\n', K_max, L_tabu, destroy_ratio);
    else 
        K_max = max_iterations;
        L_tabu = 20;
        destroy_ratio = 0.6;
        neighbor_set = {'N1', 'N2', 'N3', 'N4'};
        use_destroy_repair = false;
        fprintf('参数设置: SEVERE - 迭代数=%d, 禁忌步长=%d, 破坏比例=%.1f\n', K_max, L_tabu, destroy_ratio);
    end
    
    % 步骤3：初始化禁忌表
    tabu_list = containers.Map('KeyType', 'char', 'ValueType', 'double');
    no_improve_count = 0;
    iter = 1;
    neighbor_idx = 1;
    
    fprintf('\n步骤4: 开始主循环搜索\n');
    
    while iter <= K_max
        current_sol = sol;
        
        % 破坏-修复（仅L3及以上执行，论文3.2.3节）
        if use_destroy_repair && no_improve_count > L_tabu/2
            [current_sol, destroyed_tasks] = destroyRepair(current_sol, destroy_ratio, model);
        end
        
        % 在当前邻域内搜索最佳邻居
        current_neighbor = neighbor_set{neighbor_idx};
        [neighbor_sol, neighbor_cost] = searchBestNeighbor(current_sol, model, costFunc, current_neighbor, tabu_list);
        
        % 接受准则（论文3.2.5节）
        if neighbor_cost < best_cost  % 全局改进
            fprintf('  迭代 %d: 全局改进! 代价 %.4f -> %.4f\n', iter, best_cost, neighbor_cost);
            best_sol = neighbor_sol;
            best_cost = neighbor_cost;
            sol = neighbor_sol;
            neighbor_idx = 1;
            no_improve_count = 0;
            updateTabuList(tabu_list, neighbor_sol, L_tabu);
            
        elseif neighbor_cost < costFunc(sol)  % 局部改进
            fprintf('  迭代 %d: 局部改进 -> 代价 %.4f\n', iter, neighbor_cost);
            sol = neighbor_sol;
            neighbor_idx = 1;
            no_improve_count = 0;
            updateTabuList(tabu_list, neighbor_sol, L_tabu);
            
        else  % 无改进
            neighbor_idx = neighbor_idx + 1;
            no_improve_count = no_improve_count + 1;
            
            if neighbor_idx > length(neighbor_set)
                neighbor_idx = 1;
            end
        end
        
        % 强制破禁（论文3.2.5节）
        if no_improve_count > L_tabu
            fprintf('  迭代 %d: 强制破禁 - 清空禁忌表\n', iter);
            tabu_list = containers.Map('KeyType', 'char', 'ValueType', 'double');
            no_improve_count = 0;
        end
        
        iter = iter + 1;
    end
    
    fprintf('\nVNS-Tabu搜索完成，最优代价: %.4f\n', best_cost);
end

function merged_sol = mergeSolutions(warm_sol, current_sol, model)
    % 融合热启动解与当前解（论文3.2.2节）
    
    merged_sol = current_sol;
    n_agents = length(current_sol.agents);
    
    % 随机选择部分结构从热启动解继承
    for i = 1:n_agents
        if rand() < 0.5 && ~isempty(warm_sol.agents(i).task)
            merged_sol.agents(i).task = warm_sol.agents(i).task;
        end
    end
    
    % 确保所有任务都被分配
    all_tasks = 1:model.M;
    assigned_tasks = [];
    for i = 1:n_agents
        assigned_tasks = [assigned_tasks, merged_sol.agents(i).task];
    end
    unassigned = setdiff(all_tasks, assigned_tasks);
    
    % 随机分配未分配的任务
    for task_id = unassigned
        agent_id = randi(n_agents);
        merged_sol = insertTaskToAgentSimple(merged_sol, agent_id, task_id);
    end
end

function sol = insertTaskToAgentSimple(sol, agent_id, task_id)
    % 简单版本：将任务添加到农机任务序列末尾
    current_tasks = sol.agents(agent_id).task;
    sol.agents(agent_id).task = [current_tasks, task_id];
end

function [new_sol, destroyed_tasks] = destroyRepair(sol, destroy_ratio, model)
    % 论文3.2.3节：破坏-修复算子
    
    new_sol = sol;
    destroyed_tasks = [];
    
    % 收集所有已分配任务
    all_tasks = [];
    for i = 1:length(sol.agents)
        all_tasks = [all_tasks, sol.agents(i).task];
    end
    
    if isempty(all_tasks)
        return;
    end
    
    % 选择要破坏的任务
    n_destroy = max(1, round(length(all_tasks) * destroy_ratio));
    n_destroy = min(n_destroy, length(all_tasks));
    destroy_idx = randperm(length(all_tasks), n_destroy);
    destroyed_tasks = all_tasks(destroy_idx);
    
    % 从方案中移除破坏的任务
    for i = 1:length(sol.agents)
        tasks = new_sol.agents(i).task;
        if ~isempty(tasks)
            [~, keep_idx] = setdiff(tasks, destroyed_tasks);
            new_sol.agents(i).task = tasks(sort(keep_idx));
        end
    end
    
    % 使用贪心修复策略重新插入
    new_sol = greedyRepair(new_sol, destroyed_tasks, model);
end

function sol = greedyRepair(sol, tasks_to_repair, model)
    % 贪心修复策略
    
    unassigned = tasks_to_repair;
    
    while ~isempty(unassigned)
        best_delta = inf;
        best_agent = -1;
        best_task = -1;
        
        % 找到最佳插入任务和位置
        for ti = 1:length(unassigned)
            task_id = unassigned(ti);
            for agent_id = 1:length(sol.agents)
                delta = computeSimpleDelta(sol, agent_id, task_id, model);
                if delta < best_delta
                    best_delta = delta;
                    best_agent = agent_id;
                    best_task = task_id;
                end
            end
        end
        
        % 插入任务
        if best_agent > 0
            sol = insertTaskToAgentSimple(sol, best_agent, best_task);
        end
        
        % 从待分配列表中移除
        unassigned = setdiff(unassigned, best_task);
    end
end

function delta = computeSimpleDelta(sol, agent_id, task_id, model)
    % 计算简单代价增量
    
    current_tasks = sol.agents(agent_id).task;
    task_x = model.tasks(task_id).x;
    task_y = model.tasks(task_id).y;
    
    if isempty(current_tasks)
        % 从车库到任务，再返回车库
        agent_x = model.agents(agent_id).x;
        agent_y = model.agents(agent_id).y;
        dist_to_task = Distance(agent_x, agent_y, task_x, task_y);
        dist_back = Distance(task_x, task_y, agent_x, agent_y);
        delta = dist_to_task + dist_back;
    else
        % 添加到末尾
        last_task = current_tasks(end);
        last_x = model.tasks(last_task).x;
        last_y = model.tasks(last_task).y;
        agent_x = model.agents(agent_id).x;
        agent_y = model.agents(agent_id).y;
        
        % 原路径：从最后任务返回车库
        old_dist = Distance(last_x, last_y, agent_x, agent_y);
        % 新路径：从最后任务到新任务，再返回车库
        new_dist = Distance(last_x, last_y, task_x, task_y) + Distance(task_x, task_y, agent_x, agent_y);
        delta = new_dist - old_dist;
    end
    
    delta = max(0, delta);
end

function [best_sol, best_cost] = searchBestNeighbor(sol, model, costFunc, neighbor_type, tabu_list)
    % 在指定邻域内搜索最佳邻居
    
    best_sol = sol;
    best_cost = costFunc(sol);
    
    switch neighbor_type
        case 'N1'  % 同农机交换
            for agent_id = 1:length(sol.agents)
                tasks = sol.agents(agent_id).task;
                if length(tasks) < 2
                    continue;
                end
                for i = 1:length(tasks)-1
                    for j = i+1:length(tasks)
                        neighbor = sol;
                        neighbor.agents(agent_id).task = tasks;
                        neighbor.agents(agent_id).task([i,j]) = neighbor.agents(agent_id).task([j,i]);
                        
                        if ~isTabu(neighbor, tabu_list)
                            neighbor_cost = costFunc(neighbor);
                            if neighbor_cost < best_cost
                                best_cost = neighbor_cost;
                                best_sol = neighbor;
                            end
                        end
                    end
                end
            end
            
        case 'N2'  % 农机间交换
            for i = 1:length(sol.agents)-1
                for j = i+1:length(sol.agents)
                    tasks_i = sol.agents(i).task;
                    tasks_j = sol.agents(j).task;
                    if isempty(tasks_i) || isempty(tasks_j)
                        continue;
                    end
                    for ti = 1:length(tasks_i)
                        for tj = 1:length(tasks_j)
                            neighbor = sol;
                            new_tasks_i = tasks_i;
                            new_tasks_i(ti) = tasks_j(tj);
                            new_tasks_j = tasks_j;
                            new_tasks_j(tj) = tasks_i(ti);
                            neighbor.agents(i).task = new_tasks_i;
                            neighbor.agents(j).task = new_tasks_j;
                            
                            if ~isTabu(neighbor, tabu_list)
                                neighbor_cost = costFunc(neighbor);
                                if neighbor_cost < best_cost
                                    best_cost = neighbor_cost;
                                    best_sol = neighbor;
                                end
                            end
                        end
                    end
                end
            end
            
        case 'N3'  % 任务重定位
            for i = 1:length(sol.agents)
                for j = 1:length(sol.agents)
                    if i == j
                        continue;
                    end
                    tasks_i = sol.agents(i).task;
                    if isempty(tasks_i)
                        continue;
                    end
                    for ti = 1:length(tasks_i)
                        neighbor = sol;
                        task_to_move = tasks_i(ti);
                        neighbor.agents(i).task(ti) = [];
                        neighbor = insertTaskToAgentSimple(neighbor, j, task_to_move);
                        
                        if ~isTabu(neighbor, tabu_list)
                            neighbor_cost = costFunc(neighbor);
                            if neighbor_cost < best_cost
                                best_cost = neighbor_cost;
                                best_sol = neighbor;
                            end
                        end
                    end
                end
            end
            
        case 'N4'  % 2-opt
            for agent_id = 1:length(sol.agents)
                tasks = sol.agents(agent_id).task;
                if length(tasks) < 3
                    continue;
                end
                for i = 1:length(tasks)-1
                    for j = i+1:length(tasks)
                        neighbor = sol;
                        neighbor.agents(agent_id).task = [tasks(1:i-1), tasks(j:-1:i), tasks(j+1:end)];
                        
                        if ~isTabu(neighbor, tabu_list)
                            neighbor_cost = costFunc(neighbor);
                            if neighbor_cost < best_cost
                                best_cost = neighbor_cost;
                                best_sol = neighbor;
                            end
                        end
                    end
                end
            end
            
        case 'N5'  % 路径交叉
            for i = 1:length(sol.agents)-1
                for j = i+1:length(sol.agents)
                    tasks_i = sol.agents(i).task;
                    tasks_j = sol.agents(j).task;
                    if length(tasks_i) < 2 || length(tasks_j) < 2
                        continue;
                    end
                    cross_point_i = randi([1, length(tasks_i)-1]);
                    cross_point_j = randi([1, length(tasks_j)-1]);
                    
                    neighbor = sol;
                    neighbor.agents(i).task = [tasks_i(1:cross_point_i), tasks_j(cross_point_j+1:end)];
                    neighbor.agents(j).task = [tasks_j(1:cross_point_j), tasks_i(cross_point_i+1:end)];
                    
                    if ~isTabu(neighbor, tabu_list)
                        neighbor_cost = costFunc(neighbor);
                        if neighbor_cost < best_cost
                            best_cost = neighbor_cost;
                            best_sol = neighbor;
                        end
                    end
                end
            end
            
        case 'N6'  % 双桥移动
            for agent_id = 1:length(sol.agents)
                tasks = sol.agents(agent_id).task;
                if length(tasks) < 4
                    continue;
                end
                pos1 = randi([1, length(tasks)-3]);
                pos2 = randi([pos1+2, length(tasks)-1]);
                
                neighbor = sol;
                neighbor.agents(agent_id).task = tasks;
                neighbor.agents(agent_id).task([pos1, pos2]) = neighbor.agents(agent_id).task([pos2, pos1]);
                
                if ~isTabu(neighbor, tabu_list)
                    neighbor_cost = costFunc(neighbor);
                    if neighbor_cost < best_cost
                        best_cost = neighbor_cost;
                        best_sol = neighbor;
                    end
                end
            end
    end
end

function is_tabu_flag = isTabu(sol, tabu_list)
    % 检查解是否在禁忌表中
    key = getSolutionHash(sol);
    is_tabu_flag = tabu_list.isKey(key) && tabu_list(key) > 0;
end

function updateTabuList(tabu_list, sol, tabu_tenure)
    % 更新禁忌表
    key = getSolutionHash(sol);
    
    % 递减所有禁忌计数
    keys_to_remove = {};
    for k = keys(tabu_list)
        if tabu_list(k{1}) <= 1
            keys_to_remove{end+1} = k{1};
        else
            tabu_list(k{1}) = tabu_list(k{1}) - 1;
        end
    end
    for i = 1:length(keys_to_remove)
        tabu_list.remove(keys_to_remove{i});
    end
    
    % 添加新解
    tabu_list(key) = tabu_tenure;
end

function hash = getSolutionHash(sol)
    % 生成解的哈希值
    hash_str = '';
    for i = 1:length(sol.agents)
        if ~isempty(sol.agents(i).task)
            hash_str = [hash_str, num2str(sol.agents(i).task)];
        end
    end
    if isempty(hash_str)
        hash = '0';
    else
        hash = num2str(sum(double(hash_str)));
    end
end