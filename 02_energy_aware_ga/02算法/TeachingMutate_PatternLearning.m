function mutated = TeachingMutate_PatternLearning(individual, teacher, model)
    % 模式学习式变异 - 学习教师的调度模式
    
    mutated = individual;
    N = length(mutated.agents);
    
    % 分析负载分布模式
    teacher_loads = zeros(1, N);
    student_loads = zeros(1, N);
    
    for i = 1:N
        teacher_loads(i) = length(teacher.agents(i).task);
        student_loads(i) = length(individual.agents(i).task);
    end
    
    % 找出负载分布差异最大的机器
    load_differences = abs(teacher_loads - student_loads);
    [max_diff, target_machine] = max(load_differences);
    
    if max_diff > 0
        % 调整该机器的任务数量向教师靠拢
        if teacher_loads(target_machine) > student_loads(target_machine)
            % 需要增加任务
            num_to_add = teacher_loads(target_machine) - student_loads(target_machine);
            available_tasks = findTasksInOtherAgents(mutated, target_machine);
            
            if ~isempty(available_tasks)
                num_to_add = min(num_to_add, length(available_tasks));
                tasks_to_move = available_tasks(1:num_to_add);
                
                for task = tasks_to_move
                    source_agent = findAgentWithTask(mutated, task);
                    mutated.agents(source_agent).task = ...
                        setdiff(mutated.agents(source_agent).task, task);
                    mutated.agents(target_machine).task = ...
                        sort([mutated.agents(target_machine).task, task]);
                end
            end
            
        else
            % 需要减少任务
            num_to_remove = student_loads(target_machine) - teacher_loads(target_machine);
            if num_to_remove > 0
                tasks_to_remove = mutated.agents(target_machine).task(1:num_to_remove);
                
                for task = tasks_to_remove
                    % 随机分配到其他机器
                    available_agents = setdiff(1:N, target_machine);
                    target_agent = available_agents(randi(length(available_agents)));
                    
                    mutated.agents(target_machine).task = ...
                        setdiff(mutated.agents(target_machine).task, task);
                    mutated.agents(target_agent).task = ...
                        sort([mutated.agents(target_agent).task, task]);
                end
            end
        end
    end
    
    mutated = resolveConflicts(mutated, model);
end