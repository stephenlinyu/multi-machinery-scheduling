function [new_sol, communication_count, assignment_details, strategy, DI] = ...
    DynamicTaskAllocationWithResponse(current_sol, model, event, costFunc)

    persistent evaluator
    if isempty(evaluator)
        evaluator = DisturbanceEvaluator();
    end
    
    communication_count = 0;
    assignment_details = {};
    if ~isfield(event, 'current_time')
        event.current_time = 0;
    end
    
    % ========== 关键修改：获取当前时刻的剩余任务方案 ==========
    [remaining_sol, ~, agent_positions, ~] = getRemainingTasksWithPosition(current_sol, model, event.current_time);
    % 将 current_sol 更新为只包含未完成任务的方案
    current_sol = remaining_sol;
    
    % 复制当前方案（未完成任务）
    new_sol = struct('agents', struct('task', cell(1, length(current_sol.agents))));
    for i = 1:length(current_sol.agents)
        new_sol.agents(i).task = current_sol.agents(i).task;
    end
    
    % 处理故障和新增任务
    tasks_to_reassign = [];
    failed_agent = -1;
    if isstruct(event) && isfield(event,'type') && ischar(event.type)
        is_failure = strcmp(event.type,'failure');
        is_new = strcmp(event.type,'new_tasks');
        is_both = strcmp(event.type,'both');
    else
        is_failure = false; is_new = false; is_both = false;
    end
    
    if is_failure || is_both
        failed_agent = event.failure_agent;
        if failed_agent>0 && failed_agent<=length(model.agents)
            % 从 agent_positions 获取该农机已完成和未完成的任务
            completed = agent_positions(failed_agent).completed_tasks;
            uncompleted = agent_positions(failed_agent).uncompleted_tasks;
            fprintf('\n【故障处理】农机 %d 时间 %.1f 分钟\n', failed_agent, event.current_time);
            fprintf('  已完成: %s\n', num2str(completed));
            fprintf('  未完成需重分配: %s\n', num2str(uncompleted));
            % 将该农机的任务更新为已完成（不再参与分配）
            new_sol.agents(failed_agent).task = completed;
            if ~isempty(uncompleted)
                tasks_to_reassign = [tasks_to_reassign, uncompleted];
            end
            model.agents(failed_agent).available = 0;
        end
    end
    
    if is_new || is_both
        if isfield(event,'task_ids') && ~isempty(event.task_ids)
            new_tasks = event.task_ids;
            tasks_to_reassign = [tasks_to_reassign, new_tasks];
            fprintf('\n【新增任务】%s\n', mat2str(new_tasks));
            for tid = new_tasks
                if tid<=length(model.tasks)
                    fprintf('  任务 %d: (%.1f,%.1f) 面积%.0f\n', tid, model.tasks(tid).x, model.tasks(tid).y, model.tasks(tid).S);
                end
            end
        end
    end
    
    if isempty(tasks_to_reassign)
        fprintf('无任务需分配\n');
        strategy = 'NONE'; DI = 0; return;
    end
    
    tasks_to_reassign = unique(tasks_to_reassign(tasks_to_reassign>0 & tasks_to_reassign<=length(model.tasks)));
    fprintf('\n【待分配任务】: %s\n', num2str(tasks_to_reassign));
    
    % 显示分配前各农机未完成任务
    fprintf('\n【分配前各农机未完成任务】\n');
    for i = 1:length(new_sol.agents)
        if i==failed_agent && failed_agent>0
            fprintf('  农机 %d: (故障) 已完成 %s\n', i, num2str(new_sol.agents(i).task));
        else
            fprintf('  农机 %d: %s\n', i, num2str(new_sol.agents(i).task));
        end
    end
    
    % 获取可用农机（排除故障）
    active_agents = find([model.agents(:).available]==1);
    if failed_agent>0 && any(active_agents==failed_agent)
        active_agents(active_agents==failed_agent) = [];
    end
    if isempty(active_agents)
        error('无可用农机分配任务！');
    end
    
    % 计算扰动指数
    try
        [strategy, use_buffer, DI] = evaluator.selectStrategy(event, new_sol, model, agent_positions, event.current_time);
    catch
        strategy = 'DEFAULT'; DI = 0.5;
    end
    fprintf('\n========== 动态分配 ==========\n时间=%.1f, DI=%.4f, 策略=%s\n', event.current_time, DI, strategy);
    
    % ========== 四级分配策略 ==========
    if DI >= 0.6
    % EMERGENCY: 完整合同网 + 强化VNS-Tabu（更大搜索空间）
    fprintf('\n【EMERGENCY】DI≥0.6，执行完整合同网 + 强化VNS-Tabu（大搜索）\n');
    
    % 步骤1：先执行完整合同网，获得高质量初始解
    [temp_sol, comm1, details1] = ImprovedCNP_WithPosition(...
        new_sol, model, tasks_to_reassign, active_agents, agent_positions, costFunc, event.current_time);
    communication_count = communication_count + comm1;
    assignment_details = details1;
    
    % 步骤2：使用强化VNS-Tabu进一步优化（更大迭代次数）
    try
        % EMERGENCY模式使用更大迭代次数和更激进的参数
        [optimized, ~] = VNS_TabuSearch(temp_sol, new_sol, model, costFunc, DI, 200);  
        if costFunc(optimized) < costFunc(temp_sol)
            new_sol = optimized;
        else
            new_sol = temp_sol;
        end
    catch ME
        fprintf('强化VNS-Tabu失败: %s\n', ME.message);
        new_sol = temp_sol;
    end
    communication_count = communication_count + 1;  % VNS的通信开销
        
    elseif DI >= 0.4
        % SEVERE: 完整合同网 + 完整VNS-Tabu
        fprintf('\n【SEVERE】0.4≤DI<0.6，执行完整合同网 + 完整VNS-Tabu\n');
        [temp_sol, comm1, details1] = ImprovedCNP_WithPosition(...
            new_sol, model, tasks_to_reassign, active_agents, agent_positions, costFunc, event.current_time);
        communication_count = communication_count + comm1;
        assignment_details = details1;
        try
            [optimized, ~] = VNS_TabuSearch(temp_sol, new_sol, model, costFunc, DI, 100);
            if costFunc(optimized) < costFunc(temp_sol)
                new_sol = optimized;
            else
                new_sol = temp_sol;
            end
        catch
            new_sol = temp_sol;
        end
        
    elseif DI >= 0.2
        % MODERATE: 完整合同网 + 轻量局部搜索
        fprintf('\n【MODERATE】0.2≤DI<0.4，执行完整合同网 + 轻量局部搜索\n');
        [temp_sol, comm1, details1] = ImprovedCNP_WithPosition(...
            new_sol, model, tasks_to_reassign, active_agents, agent_positions, costFunc, event.current_time);
        communication_count = communication_count + comm1;
        assignment_details = details1;
        try
            [optimized, ~] = LightLocalSearch(temp_sol, model, costFunc, 50);
            if costFunc(optimized) < costFunc(temp_sol)
                new_sol = optimized;
            else
                new_sol = temp_sol;
            end
        catch
            new_sol = temp_sol;
        end
        
    else
        % LIGHT: 完整合同网（无额外优化）
        fprintf('\n【LIGHT】DI<0.2，执行完整合同网\n');
        [new_sol, comm1, details1] = ImprovedCNP_WithPosition(...
            new_sol, model, tasks_to_reassign, active_agents, agent_positions, costFunc, event.current_time);
        communication_count = communication_count + comm1;
        assignment_details = details1;
    end
    
    % ========== 故障安全：确保故障农机上无待分配任务 ==========
    if failed_agent > 0
        misplaced = intersect(new_sol.agents(failed_agent).task, tasks_to_reassign);
        if ~isempty(misplaced)
            fprintf('\n警告：故障农机 %d 被分配了待分配任务 %s，重新分配...\n', failed_agent, num2str(misplaced));
            new_sol.agents(failed_agent).task = setdiff(new_sol.agents(failed_agent).task, misplaced);
            for tid = misplaced
                best_a = -1; best_pos = -1; best_cost = inf;
                cur_cost = costFunc(new_sol);
                for a = active_agents
                    tasks = new_sol.agents(a).task;
                    for pos = 1:length(tasks)+1
                        test_sol = new_sol;
                        test_sol.agents(a).task = insertTaskAtIndex(tasks, tid, pos);
                        c = costFunc(test_sol);
                        if c < best_cost
                            best_cost = c;
                            best_a = a;
                            best_pos = pos;
                        end
                    end
                end
                if best_a > 0
                    new_sol.agents(best_a).task = insertTaskAtIndex(new_sol.agents(best_a).task, tid, best_pos);
                    fprintf('  任务 %d 重分配给农机 %d (位置 %d)\n', tid, best_a, best_pos);
                end
            end
        end
    end
    
    % 最终结果展示
    fprintf('\n【待执行任务分配）】\n');
    all_assigned = [];
    for i = 1:length(new_sol.agents)
        if i==failed_agent && failed_agent>0
            fprintf('  农机 %d: (故障) 已完成 %s\n', i, num2str(new_sol.agents(i).task));
        else
            fprintf('  农机 %d: %s\n', i, num2str(new_sol.agents(i).task));
            all_assigned = [all_assigned, new_sol.agents(i).task];
        end
    end
    unassigned = setdiff(tasks_to_reassign, unique(all_assigned));
    if ~isempty(unassigned)
        fprintf('\n警告：未分配任务 %s\n', num2str(unassigned));
    else
        fprintf('\n所有任务分配成功\n');
    end
    fprintf('通信次数: %d, 最终代价: %.4f\n', communication_count, costFunc(new_sol));
end

% ==================== 辅助函数 ====================
function newList = insertTaskAtIndex(taskList, task, index)
    if isempty(taskList)
        newList = task;
    elseif index == 1
        newList = [task, taskList];
    elseif index > length(taskList)
        newList = [taskList, task];
    else
        newList = [taskList(1:index-1), task, taskList(index:end)];
    end
end

function [best_sol, best_cost] = LightLocalSearch(initial_sol, model, costFunc, max_iter)
    best_sol = initial_sol;
    best_cost = costFunc(initial_sol);
    n_agents = length(initial_sol.agents);
    for iter = 1:max_iter
        neighbor = best_sol;
        if rand() < 0.5
            nonempty = find(cellfun(@(x)~isempty(x), {neighbor.agents.task}));
            if length(nonempty) < 2, continue; end
            from = nonempty(randi(length(nonempty)));
            tasks = neighbor.agents(from).task;
            if isempty(tasks), continue; end
            tid = tasks(randi(length(tasks)));
            neighbor.agents(from).task = setdiff(tasks, tid);
            to = randi(n_agents);
            neighbor.agents(to).task = [neighbor.agents(to).task, tid];
        else
            nonempty = find(cellfun(@(x)~isempty(x), {neighbor.agents.task}));
            if length(nonempty) < 2, continue; end
            idx = randperm(length(nonempty), 2);
            a = nonempty(idx(1));
            b = nonempty(idx(2));
            tasks_a = neighbor.agents(a).task;
            tasks_b = neighbor.agents(b).task;
            if isempty(tasks_a) || isempty(tasks_b), continue; end
            ta = tasks_a(randi(length(tasks_a)));
            tb = tasks_b(randi(length(tasks_b)));
            neighbor.agents(a).task(tasks_a==ta) = tb;
            neighbor.agents(b).task(tasks_b==tb) = ta;
        end
        new_cost = costFunc(neighbor);
        if new_cost < best_cost
            best_cost = new_cost;
            best_sol = neighbor;
        end
    end
end