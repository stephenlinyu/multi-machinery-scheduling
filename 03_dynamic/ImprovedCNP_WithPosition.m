function [new_sol, communication_count, assignment_details] = ImprovedCNP_WithPosition(...
    current_sol, model, tasks_to_assign, active_agents, agent_positions, costFunc, current_time)

    % 改进合同网算法（完整版）
    % 输入：
    %   current_sol: 当前分配方案
    %   model: 模型数据
    %   tasks_to_assign: 待分配任务列表
    %   active_agents: 可用农机列表（已排除故障农机）
    %   agent_positions: 农机当前位置和状态
    %   costFunc: 代价函数句柄
    %   current_time: 当前时间（分钟）
    % 输出：
    %   new_sol: 新分配方案
    %   communication_count: 通信次数
    %   assignment_details: 分配详情

    communication_count = 0;
    new_sol = current_sol;
    assignment_details = {};
    
    % 完整合同网参数（固定，不简化）
    lambda_load = 20;           % 负载均衡权重
    alpha_travel = 30;          % 行驶中断惩罚系数
    alpha_work = 50;            % 作业中断惩罚系数
    
    fprintf('\n========== 改进合同网算法（完整版） ==========\n');
    fprintf('待分配任务: %s\n', num2str(tasks_to_assign));
    fprintf('可用农机: %s\n', num2str(active_agents));
    fprintf('当前时间: %.1f 分钟\n', current_time);
    
    % 确保 active_agents 只包含可用且未故障的农机
    if isfield(model, 'agents')
        available_flag = [model.agents(:).available];
        active_agents = active_agents(available_flag(active_agents) == 1);
    end
    
    % 过滤有效的任务
    valid_tasks = tasks_to_assign(tasks_to_assign <= length(model.tasks));
    if length(valid_tasks) < length(tasks_to_assign)
        fprintf('警告: 过滤了 %d 个无效任务\n', length(tasks_to_assign) - length(valid_tasks));
        tasks_to_assign = valid_tasks;
    end
    
    if isempty(tasks_to_assign)
        fprintf('没有有效的待分配任务\n');
        return;
    end
    
    % 显示各农机状态
    fprintf('\n各农机状态:\n');
    for agent_id = active_agents
        if agent_id > length(agent_positions), continue; end
        n_tasks = length(current_sol.agents(agent_id).task);
        if agent_positions(agent_id).is_moving
            fprintf('  农机 %d: 前往任务 %d (%.1f%%), 已有任务数 %d\n', ...
                    agent_id, agent_positions(agent_id).current_task, ...
                    agent_positions(agent_id).progress * 100, n_tasks);
        elseif agent_positions(agent_id).is_working
            fprintf('  农机 %d: 执行任务 %d (%.1f%%), 已有任务数 %d\n', ...
                    agent_id, agent_positions(agent_id).current_task, ...
                    agent_positions(agent_id).progress * 100, n_tasks);
        else
            fprintf('  农机 %d: 空闲, 已有任务数 %d\n', agent_id, n_tasks);
        end
    end
    
    % 对每个待分配任务进行合同网协商
    for task_idx = 1:length(tasks_to_assign)
        task_id = tasks_to_assign(task_idx);
        if task_id > length(model.tasks)
            fprintf('跳过无效任务 %d\n', task_id);
            continue;
        end
        
        fprintf('\n========== 任务 %d 合同网协商 ==========\n', task_id);
        fprintf('任务信息: 位置(%.2f, %.2f), 面积 %.0f\n', ...
                model.tasks(task_id).x, model.tasks(task_id).y, model.tasks(task_id).S);
        
        % 步骤1：选择招标者
        tenderer = selectTendererByPosition(active_agents, agent_positions);
        fprintf('\n【步骤1】选择招标者 -> 农机 %d\n', tenderer);
        
        % 步骤2：计算招标者自评价阈值（含中断惩罚）
        [theta, theta_insert_pos] = computeSelfEvaluation(tenderer, task_id, current_sol, ...
                                    model, agent_positions, alpha_travel, alpha_work, current_time);
        fprintf('【步骤2】招标者自评价阈值 θ = %.4f\n', theta);
        
        % 步骤3：收集投标（含中断惩罚+负载均衡）
        bids = [];
        bidders = [];
        best_positions = [];
        fprintf('\n【步骤3】收集投标:\n');
        for agent_id = active_agents
            if agent_id == tenderer, continue; end
            [bid_value, best_pos] = computeBidValue(agent_id, task_id, current_sol, ...
                                        model, agent_positions, lambda_load, ...
                                        alpha_travel, alpha_work, current_time);
            if bid_value < theta
                bids = [bids, bid_value];
                bidders = [bidders, agent_id];
                best_positions = [best_positions, best_pos];
                fprintf('  农机 %d 投标: %.4f (位置 %d) ?\n', agent_id, bid_value, best_pos);
            else
                fprintf('  农机 %d 投标: %.4f ?\n', agent_id, bid_value);
            end
        end
        
        % 步骤4：选择中标者
        fprintf('\n【步骤4】选择中标者:\n');
        if isempty(bids)
            winner = tenderer;
            winner_pos = theta_insert_pos;
            winner_bid = theta;
            fprintf('  无合格投标者 -> 招标者农机 %d 执行\n', winner);
        else
            [min_bid, min_idx] = min(bids);
            winner = bidders(min_idx);
            winner_pos = best_positions(min_idx);
            winner_bid = min_bid;
            fprintf('  中标者: 农机 %d (%.4f)\n', winner, min_bid);
        end
        
        % 步骤5：插入任务
        new_sol = insertTaskAtPosition(new_sol, winner, task_id, winner_pos);
        assignment_details{end+1} = struct('task_id', task_id, 'winner', winner, ...
                                           'insert_pos', winner_pos, 'bid', winner_bid);
        communication_count = communication_count + 1;
        fprintf('【步骤5】任务 %d -> 农机 %d (位置 %d)\n', task_id, winner, winner_pos);
        
        % 更新 current_sol 以便后续任务使用最新分配
        current_sol.agents(winner).task = new_sol.agents(winner).task;
    end
    
    % ========== 后优化阶段（完整版） ==========
    fprintf('\n========== 后优化阶段 ==========\n');
    fprintf('【步骤6】任务再分配优化:\n');
    [new_sol, redist_count] = taskRedistribution(new_sol, model, costFunc, ...
                                agent_positions, alpha_travel, alpha_work, lambda_load, active_agents);
    communication_count = communication_count + redist_count;
    
    fprintf('\n【步骤7】任务交换优化:\n');
    [new_sol, swap_count] = taskExchange(new_sol, model, costFunc, ...
                            agent_positions, alpha_travel, alpha_work, lambda_load, active_agents);
    communication_count = communication_count + swap_count;
    
    fprintf('\n========== 合同网分配完成 ==========\n');
    fprintf('总通信次数: %d\n', communication_count);
end

%% -------------------- 辅助函数 --------------------
function tenderer = selectTendererByPosition(active_agents, agent_positions)
    if isempty(active_agents), tenderer=1; return; end
    min_avg = inf;
    tenderer = active_agents(1);
    for i = 1:length(active_agents)
        id_i = active_agents(i);
        if id_i > length(agent_positions), continue; end
        sum_d = 0; cnt = 0;
        for j = 1:length(active_agents)
            id_j = active_agents(j);
            if id_j > length(agent_positions) || id_i == id_j, continue; end
            sum_d = sum_d + Distance(agent_positions(id_i).x, agent_positions(id_i).y, ...
                                     agent_positions(id_j).x, agent_positions(id_j).y);
            cnt = cnt + 1;
        end
        if cnt > 0
            avg = sum_d / cnt;
            if avg < min_avg
                min_avg = avg;
                tenderer = id_i;
            end
        end
    end
end

function [theta, best_pos] = computeSelfEvaluation(agent_id, task_id, current_sol, ...
                                model, agent_positions, alpha_travel, alpha_work, current_time)
    [delta_f, best_pos] = computeBaseDelta(agent_id, task_id, current_sol, model, agent_positions, current_time);
    theta = delta_f;
    if agent_id <= length(agent_positions)
        if agent_positions(agent_id).is_moving
            progress = agent_positions(agent_id).progress;
            theta = theta + (1 - progress) * alpha_travel;
        elseif agent_positions(agent_id).is_working
            progress = agent_positions(agent_id).progress;
            theta = theta + (1 - progress) * alpha_work;
        end
    end
end

function [bid_value, best_pos] = computeBidValue(agent_id, task_id, current_sol, ...
                                model, agent_positions, lambda_load, alpha_travel, alpha_work, current_time)
    [delta_f, best_pos] = computeBaseDelta(agent_id, task_id, current_sol, model, agent_positions, current_time);
    % 中断惩罚
    P_interrupt = 0;
    if agent_id <= length(agent_positions)
        if agent_positions(agent_id).is_moving
            progress = agent_positions(agent_id).progress;
            P_interrupt = (1 - progress) * alpha_travel;
        elseif agent_positions(agent_id).is_working
            progress = agent_positions(agent_id).progress;
            P_interrupt = (1 - progress) * alpha_work;
        end
    end
    % 负载均衡
    n_i = length(current_sol.agents(agent_id).task);
    total = 0; n_ag = length(current_sol.agents);
    for i = 1:n_ag, total = total + length(current_sol.agents(i).task); end
    n_avg = total / n_ag;
if n_avg > 0
    L_load = lambda_load * abs(n_i - n_avg) / n_avg;
else
    L_load = 0;
end
    bid_value = delta_f + P_interrupt + L_load;
end

function [delta_f, best_pos] = computeBaseDelta(agent_id, task_id, current_sol, ...
                                    model, agent_positions, current_time)
    current_tasks = current_sol.agents(agent_id).task;
    task_x = model.tasks(task_id).x;
    task_y = model.tasks(task_id).y;
    task_S = model.tasks(task_id).S;
    w = model.agents(agent_id).w;
    vel = model.agents(agent_id).nom_vel;
    work_distance_equiv = (task_S / w) * vel;  % 作业时间等价距离
    
    if agent_id <= length(agent_positions)
        cur_x = agent_positions(agent_id).x;
        cur_y = agent_positions(agent_id).y;
    else
        cur_x = model.agents(agent_id).x;
        cur_y = model.agents(agent_id).y;
    end
    garage_x = model.agents(agent_id).x;
    garage_y = model.agents(agent_id).y;
    
    best_pos = 1;
    min_delta = inf;
    if isempty(current_tasks)
        dist_to = Distance(cur_x, cur_y, task_x, task_y);
        dist_back = Distance(task_x, task_y, garage_x, garage_y);
        delta_f = dist_to + dist_back + work_distance_equiv;
        best_pos = 1;
    else
        n = length(current_tasks);
        for pos = 1:n+1
            if pos == 1
                first_id = current_tasks(1);
                fx = model.tasks(first_id).x; fy = model.tasks(first_id).y;
                delta = Distance(cur_x, cur_y, task_x, task_y) + Distance(task_x, task_y, fx, fy) ...
                        - Distance(cur_x, cur_y, fx, fy);
            elseif pos == n+1
                last_id = current_tasks(end);
                lx = model.tasks(last_id).x; ly = model.tasks(last_id).y;
                delta = Distance(lx, ly, task_x, task_y) + Distance(task_x, task_y, garage_x, garage_y) ...
                        - Distance(lx, ly, garage_x, garage_y);
            else
                prev_id = current_tasks(pos-1);
                next_id = current_tasks(pos);
                px = model.tasks(prev_id).x; py = model.tasks(prev_id).y;
                nx = model.tasks(next_id).x; ny = model.tasks(next_id).y;
                delta = Distance(px, py, task_x, task_y) + Distance(task_x, task_y, nx, ny) ...
                        - Distance(px, py, nx, ny);
            end
            cand = delta + work_distance_equiv;
            if cand < min_delta
                min_delta = cand;
                best_pos = pos;
            end
        end
        delta_f = min_delta;
    end
    delta_f = max(0, delta_f);
end

function sol = insertTaskAtPosition(sol, agent_id, task_id, position)
    tasks = sol.agents(agent_id).task;
    if ~isnumeric(position) || isinf(position) || isnan(position)
        position = length(tasks) + 1;
    else
        position = round(position);
    end
    if isempty(tasks)
        sol.agents(agent_id).task = task_id;
    elseif position <= 1
        sol.agents(agent_id).task = [task_id, tasks];
    elseif position > length(tasks)
        sol.agents(agent_id).task = [tasks, task_id];
    else
        sol.agents(agent_id).task = [tasks(1:position-1), task_id, tasks(position:end)];
    end
end

function [sol, cnt] = taskRedistribution(sol, model, costFunc, agent_positions, ...
                                         alpha_travel, alpha_work, lambda_load, available_agents)
    cnt = 0;
    n_agents = length(sol.agents);
    if nargin < 8, available_agents = 1:n_agents; end
    if isfield(model,'agents')
        avail_flag = [model.agents(:).available];
        available_agents = available_agents(avail_flag(available_agents)==1);
    end
    if length(available_agents) < 2, return; end
    
    % 获取每个农机正在执行的任务（保护任务）
    protecting_task = -ones(1, n_agents);
    for i = available_agents
        if i <= length(agent_positions) && agent_positions(i).progress > 0 && ...
           isfield(agent_positions(i), 'current_task') && agent_positions(i).current_task > 0
            protecting_task(i) = agent_positions(i).current_task;
        end
    end
    
    max_iter = 20;
    for iter = 1:max_iter
        n_tasks = zeros(1,n_agents);
        for i = available_agents
            n_tasks(i) = length(sol.agents(i).task);
        end
        [max_t, max_idx] = max(n_tasks(available_agents));
        max_idx = available_agents(max_idx);
        [min_t, min_idx] = min(n_tasks(available_agents));
        min_idx = available_agents(min_idx);
        if max_t <= min_t+1, break; end
        
        improved = false;
        for task_id = sol.agents(max_idx).task
            % 跳过保护任务
            if task_id == protecting_task(max_idx)
                continue;
            end
            test_sol = sol;
            pos = find(test_sol.agents(max_idx).task == task_id, 1);
            if isempty(pos), continue; end
            test_sol.agents(max_idx).task(pos) = [];
            [best_pos, ~] = computeBaseDelta(min_idx, task_id, test_sol, model, agent_positions, 0);
            if ~isnumeric(best_pos) || isinf(best_pos), best_pos = length(test_sol.agents(min_idx).task)+1; end
            test_sol = insertTaskAtPosition(test_sol, min_idx, task_id, best_pos);
            if costFunc(test_sol) < costFunc(sol)
                sol = test_sol;
                improved = true;
                cnt = cnt + 1;
                fprintf('  转移任务 %d: %d -> %d\n', task_id, max_idx, min_idx);
                break;
            end
        end
        if ~improved, break; end
    end
    if cnt>0, fprintf('  共转移 %d 个任务\n', cnt); else fprintf('  无任务转移\n'); end
end

function [sol, cnt] = taskExchange(sol, model, costFunc, agent_positions, ...
                                   alpha_travel, alpha_work, lambda_load, available_agents)
    cnt = 0;
    n_agents = length(sol.agents);
    if nargin < 8, available_agents = 1:n_agents; end
    if isfield(model,'agents')
        avail_flag = [model.agents(:).available];
        available_agents = available_agents(avail_flag(available_agents)==1);
    end
    if length(available_agents) < 2, return; end
    
    % 获取每个农机正在执行的任务（保护任务）
    protecting_task = -ones(1, n_agents);
    for i = available_agents
        if i <= length(agent_positions) && agent_positions(i).progress > 0 && ...
           isfield(agent_positions(i), 'current_task') && agent_positions(i).current_task > 0
            protecting_task(i) = agent_positions(i).current_task;
        end
    end
    
    max_iter = 30;
    for iter = 1:max_iter
        improved = false;
        for i_idx = 1:length(available_agents)
            for j_idx = i_idx+1:length(available_agents)
                i = available_agents(i_idx);
                j = available_agents(j_idx);
                tasks_i = sol.agents(i).task;
                tasks_j = sol.agents(j).task;
                if isempty(tasks_i) || isempty(tasks_j), continue; end
                for ti = 1:length(tasks_i)
                    task_i = tasks_i(ti);
                    % 如果任务 i 是农机 i 的保护任务，跳过
                    if task_i == protecting_task(i), continue; end
                    for tj = 1:length(tasks_j)
                        task_j = tasks_j(tj);
                        % 如果任务 j 是农机 j 的保护任务，跳过
                        if task_j == protecting_task(j), continue; end
                        % 同时，如果 task_i 是农机 j 的保护任务，或者 task_j 是农机 i 的保护任务，也应跳过（虽然理论上保护任务不会出现在其他农机的任务列表中，但以防万一）
                        if task_i == protecting_task(j) || task_j == protecting_task(i)
                            continue;
                        end
                        test_sol = sol;
                        test_sol.agents(i).task(ti) = task_j;
                        test_sol.agents(j).task(tj) = task_i;
                        if costFunc(test_sol) < costFunc(sol)
                            sol = test_sol;
                            improved = true;
                            cnt = cnt + 1;
                            fprintf('  交换任务: %d:%d <-> %d:%d\n', i, task_i, j, task_j);
                            break;
                        end
                    end
                    if improved, break; end
                end
                if improved, break; end
            end
            if improved, break; end
        end
        if ~improved, break; end
    end
    if cnt>0, fprintf('  共交换 %d 对任务\n', cnt); else fprintf('  无任务交换\n'); end
end