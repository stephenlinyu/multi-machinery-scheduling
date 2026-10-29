function mutated = TeachingMutate_Reassignment(individual, teacher, model, iteration, max_iterations)
    % 任务重分配式变异 - 基于教师的经验重新分配任务
    
    strength = 0.8 - 0.5 * (iteration / max_iterations);
    mutated = individual;
    N = length(mutated.agents);
    M = model.M;
    
    % 找出与教师分配差异最大的农机
    differences = calculateAssignmentDifference(individual, teacher);
    
    % 选择差异最大的前K台农机进行调整
    K = max(1, round(strength * N));  % 基于农机数量N计算
    [~, sorted_idx] = sort(differences, 'descend');
    machines_to_adjust = sorted_idx(1:min(K, length(sorted_idx)));
    
    % 收集这些农机上的所有任务
    all_tasks_to_reassign = [];
    for machine_idx = machines_to_adjust
        current_tasks = mutated.agents(machine_idx).task;
        if ~isempty(current_tasks)
            all_tasks_to_reassign = union(all_tasks_to_reassign, current_tasks);
        end
    end
    
    % 如果收集到任务，进行重分配
    if ~isempty(all_tasks_to_reassign)
        % 随机选择部分任务进行重分配（避免一次改变太多）
        num_tasks_to_change = min(length(all_tasks_to_reassign), max(1, round(K * 2)));
        if length(all_tasks_to_reassign) > num_tasks_to_change
            selected_indices = randperm(length(all_tasks_to_reassign), num_tasks_to_change);
            tasks_to_reassign = all_tasks_to_reassign(selected_indices);
        else
            tasks_to_reassign = all_tasks_to_reassign;
        end
        
        for task_idx = 1:length(tasks_to_reassign)
            task = tasks_to_reassign(task_idx);
            
            % 找出该任务在当前个体和教师中的分配位置
            current_agent = findAgentWithTask(mutated, task);
            teacher_agent = findAgentWithTask(teacher, task);
            
            % 70%概率按照教师的分配方式进行重分配
            if rand() < 1 && teacher_agent > 0
                % 从原位置移除任务
                if current_agent > 0
                    current_tasks = mutated.agents(current_agent).task;
                    % 安全移除任务的方法
                    if isscalar(current_tasks) && current_tasks == task
                        mutated.agents(current_agent).task = [];
                    else
                        mutated.agents(current_agent).task = current_tasks(current_tasks ~= task);
                    end
                end
                
                % 添加到教师指定的位置
                teacher_tasks = mutated.agents(teacher_agent).task;
                if isempty(teacher_tasks)
                    mutated.agents(teacher_agent).task = task;
                else
                    mutated.agents(teacher_agent).task = sort([teacher_tasks, task]);
                end
                
            else
                % 选择负载最轻的机器进行分配
                [~, agent_costs] = CostFunction(mutated, model);
                [~, best_agent] = min(agent_costs);
                
                % 从原位置移除（如果与目标位置不同）
                if current_agent > 0 && current_agent ~= best_agent
                    current_tasks = mutated.agents(current_agent).task;
                    % 安全移除任务的方法
                    if isscalar(current_tasks) && current_tasks == task
                        mutated.agents(current_agent).task = [];
                    else
                        mutated.agents(current_agent).task = current_tasks(current_tasks ~= task);
                    end
                end
                
                % 添加到最佳位置
                best_tasks = mutated.agents(best_agent).task;
                if isempty(best_tasks)
                    mutated.agents(best_agent).task = task;
                else
                    mutated.agents(best_agent).task = sort([best_tasks, task]);
                end
            end
        end
    end
    
    mutated = resolveConflicts(mutated, model);
end