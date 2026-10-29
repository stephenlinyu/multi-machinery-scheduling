function differences = calculateAssignmentDifference(ind1, ind2)
    % 计算两个个体在任务分配上的差异度
    N = length(ind1.agents);
    differences = zeros(1, N);
    
    for i = 1:N
        tasks1 = ind1.agents(i).task;
        tasks2 = ind2.agents(i).task;
        
        % 计算Jaccard差异系数
        intersection = length(intersect(tasks1, tasks2));
        union_size = length(union(tasks1, tasks2));
        
        if union_size > 0
            differences(i) = 1 - intersection / union_size;
        else
            differences(i) = 0;
        end
    end
end