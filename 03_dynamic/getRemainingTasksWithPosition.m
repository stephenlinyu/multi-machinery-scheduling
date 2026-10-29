function [remaining_sol, finished_tasks, agent_positions, uncompleted_tasks_by_agent] = ...
    getRemainingTasksWithPosition(current_sol, model, current_time_minutes)
% 根据当前时间，确定每个农机已完成的任务、未完成的任务、以及当前位置
% 输出：
%   remaining_sol          : 剩余未完成任务分配方案（只包含未完成的任务）
%   finished_tasks         : 所有农机已完成的任务ID列表（全局）
%   agent_positions        : 各农机当前位置及状态的结构体数组
%   uncompleted_tasks_by_agent : 每个农机未完成的任务ID（cell数组）

    n_agents = length(current_sol.agents);
    remaining_sol = struct('agents', struct('task', cell(1, n_agents)));
    finished_tasks = [];
    uncompleted_tasks_by_agent = cell(1, n_agents);
    
    % 初始化 agent_positions 结构体
    for i = 1:n_agents
        agent_positions(i).agent_id = i;
        agent_positions(i).x = model.agents(i).x;
        agent_positions(i).y = model.agents(i).y;
        agent_positions(i).current_task = [];
        agent_positions(i).progress = 0;
        agent_positions(i).is_moving = false;
        agent_positions(i).is_working = false;
        agent_positions(i).completed_tasks = [];    % 已完成的任务列表
        agent_positions(i).uncompleted_tasks = [];  % 未完成的任务列表
    end
    
    for agent_id = 1:n_agents
        tasks = current_sol.agents(agent_id).task;
        if isempty(tasks)
            % 无任务，剩余方案为空，位置保持车库
            remaining_sol.agents(agent_id).task = [];
            continue;
        end
        
        time_accum = 0;          % 已累计作业+行驶时间（分钟）
        completed_list = [];     % 该农机已完成的任务ID
        uncompleted_list = [];   % 该农机未完成的任务ID（包括当前未完成的）
        found_uncompleted = false;
        
        for task_idx = 1:length(tasks)
            task_id = tasks(task_idx);
            if task_id > length(model.tasks)
                warning('任务ID %d 超出模型任务总数，跳过', task_id);
                continue;
            end
            
            % 计算从上一位置到当前任务的距离和时间
            if task_idx == 1
                % 第一个任务：从车库出发
                travel_dist = Distance(model.agents(agent_id).x, model.agents(agent_id).y, ...
                                       model.tasks(task_id).x, model.tasks(task_id).y);
                travel_time = travel_dist / model.agents(agent_id).nom_vel * 60;  % 分钟
            else
                prev_task = tasks(task_idx-1);
                travel_dist = Distance(model.tasks(prev_task).x, model.tasks(prev_task).y, ...
                                       model.tasks(task_id).x, model.tasks(task_id).y);
                travel_time = travel_dist / model.agents(agent_id).nom_vel * 60;
            end
            
            % 作业时间（分钟）
            work_time = 60 * (model.tasks(task_id).S / model.agents(agent_id).w);
            task_total_time = travel_time + work_time;
            
            if ~found_uncompleted
                if time_accum + task_total_time <= current_time_minutes + 1e-6
                    % 该任务已经全部完成
                    time_accum = time_accum + task_total_time;
                    completed_list = [completed_list, task_id];
                    finished_tasks = [finished_tasks, task_id];
                    % 农机位置更新到该任务点
                    agent_positions(agent_id).x = model.tasks(task_id).x;
                    agent_positions(agent_id).y = model.tasks(task_id).y;
                else
                    % 当前任务未完成（可能正在路上或作业中）
                    found_uncompleted = true;
                    % 当前任务及其之后的所有任务都算未完成
                    uncompleted_list = tasks(task_idx:end);
                    agent_positions(agent_id).uncompleted_tasks = uncompleted_list;
                    
                    % 计算当前时间点在任务周期内的剩余时间
                    remaining_time = current_time_minutes - time_accum;  % 已进入当前任务的时间
                    
                    if remaining_time <= travel_time
                        % 正在前往任务的路上
                        agent_positions(agent_id).is_moving = true;
                        agent_positions(agent_id).is_working = false;
                        progress = remaining_time / travel_time;
                        % 起点
                        if task_idx == 1
                            start_x = model.agents(agent_id).x;
                            start_y = model.agents(agent_id).y;
                        else
                            prev_task = tasks(task_idx-1);
                            start_x = model.tasks(prev_task).x;
                            start_y = model.tasks(prev_task).y;
                        end
                        end_x = model.tasks(task_id).x;
                        end_y = model.tasks(task_id).y;
                        agent_positions(agent_id).x = start_x + (end_x - start_x) * progress;
                        agent_positions(agent_id).y = start_y + (end_y - start_y) * progress;
                        agent_positions(agent_id).current_task = task_id;
                        agent_positions(agent_id).progress = progress;
                    else
                        % 正在作业
                        agent_positions(agent_id).is_moving = false;
                        agent_positions(agent_id).is_working = true;
                        agent_positions(agent_id).x = model.tasks(task_id).x;
                        agent_positions(agent_id).y = model.tasks(task_id).y;
                        agent_positions(agent_id).current_task = task_id;
                        work_progress = (remaining_time - travel_time) / work_time;
                        agent_positions(agent_id).progress = work_progress;
                    end
                    break;  % 跳出循环，后续任务已标记为未完成
                end
            end
        end
        
        % 如果所有任务都完成了
        if ~found_uncompleted && ~isempty(tasks)
            agent_positions(agent_id).completed_tasks = tasks;
            % 位置已在循环中更新为最后一个任务点
        end
        
        % 记录已完成任务（用于外部查看）
        agent_positions(agent_id).completed_tasks = completed_list;
        
        % 构建剩余方案：只保留未完成的任务
        if found_uncompleted
            remaining_sol.agents(agent_id).task = uncompleted_list;
        else
            remaining_sol.agents(agent_id).task = [];   % 无未完成任务
        end
        
        % 输出每个农机的未完成任务列表
        uncompleted_tasks_by_agent{agent_id} = remaining_sol.agents(agent_id).task;
    end
end