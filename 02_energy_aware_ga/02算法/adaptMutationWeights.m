function weights = adaptMutationWeights(history_performance, current_iteration, max_iterations)
    % 根据各策略的历史表现自适应调整权重
    
    if isempty(history_performance) || size(history_performance, 1) < 5
        % 初始权重
        weights = [0.25, 0.25, 0.25, 0.25];
        return;
    end
    
    % 计算各策略的平均改进率
    avg_improvement = mean(history_performance, 1);
    
    % 避免除零错误
    avg_improvement(avg_improvement <= 0) = 0.001;
    
    % 基于性能的权重调整
    weights = avg_improvement / sum(avg_improvement);
    
    % 保持最小权重以避免策略消失
    min_weight = 0.1;
    weights = max(weights, min_weight);
    weights = weights / sum(weights);
end