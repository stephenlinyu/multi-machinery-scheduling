function [updated_weights, performance_history] = updateWeightsSimple(...
    current_weights, performance_history, strategy_idx, improvement)
    % 简化的滑动窗口奖惩机制 - 只有2个参数需要调整
    
    % 固定参数（经验值，通常不需要调整）
    learning_rate = 0.2;    % 学习率
    window_size = 10;       % 滑动窗口大小
    
    % 更新性能记录
    if isempty(performance_history)
        performance_history = cell(1, 4);
        for i = 1:4
            performance_history{i} = [];
        end
    end
    
    % 记录本次改进
    performance_history{strategy_idx} = [performance_history{strategy_idx}, improvement];
    
    % 保持窗口大小
    if length(performance_history{strategy_idx}) > window_size
        performance_history{strategy_idx} = performance_history{strategy_idx}(end-window_size+1:end);
    end
    
    % 计算平均改进率
    if ~isempty(performance_history{strategy_idx})
        avg_improvement = mean(performance_history{strategy_idx});
    else
        avg_improvement = 0;
    end
    
    % 更新权重
    updated_weights = current_weights;
    weight_change = learning_rate * avg_improvement;
    updated_weights(strategy_idx) = current_weights(strategy_idx) + weight_change;
    
    % 确保权重合理范围 [0.05, 0.6]
    updated_weights = max(updated_weights, 0.05);
    updated_weights = min(updated_weights, 0.6);
    
    % 归一化
    updated_weights = updated_weights / sum(updated_weights);
end