function mutated = TeachingMutate_Bottleneck(individual, teacher, model, iteration, max_iterations)
    % 瓶颈导向式变异 - 针对影响整体目标的关键资源进行优化
    
    % 找出教师个体的瓶颈机器（完成时间最晚的机器）
    [~, teacher_costs] = CostFunction(teacher, model);
    [~, bottleneck_machine] = max(teacher_costs);
    
    mutated = individual;
    
    if iteration > max_iterations * 0.5
        % 策略1：直接学习教师的瓶颈机器调度方案
        mutated.agents(bottleneck_machine).task = teacher.agents(bottleneck_machine).task;
    else
        % 策略2：优化学生自身的瓶颈机器
        [~, student_costs] = CostFunction(individual, model);
        [~, student_bottleneck] = max(student_costs);
        
        % 获取教师瓶颈机器的任务排序模式
        teacher_tasks = teacher.agents(bottleneck_machine).task;
        student_tasks = mutated.agents(student_bottleneck).task;
        
        if ~isempty(student_tasks) && ~isempty(teacher_tasks)
            % 尝试按照教师的模式重新排序
            [~, order] = ismember(student_tasks, teacher_tasks);
            valid_order = order(order > 0);
            if ~isempty(valid_order)
                [~, sorted_idx] = sort(valid_order);
                mutated.agents(student_bottleneck).task = student_tasks(sorted_idx);
            end
        end
    end
    
    % 处理任务冲突
    mutated = resolveConflicts(mutated, model);
end