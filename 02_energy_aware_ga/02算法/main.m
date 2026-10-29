
clc;   %清除命令窗口
clear;  %清除工作区
close all;  %关闭图形窗口

%% Problem Definition

model = CreateModel();  %调用CreateModel.m函数创建模型，初始化智能体和任务
% load('modelTest3.mat');

%% GA Parameters

MaxIt = 50;     % Maximum Number of Iterationsv
nPop = 70;       % Population Size
pt = 0.9;
nt = floor(pt*nPop);
pc = 0.4;                 % Crossover Percentage
nc = 2*round(pc*nPop/2);  % Number of Offsprings (also Parnets)...
pm = 0.1;                 % Mutation Percentage
nm = round(pm*nPop);      % Number of Mutants   round函数用作四舍五入取整数，若出现中间值2.5，取最近偶数2
beta = 8;                 % Selection Pressure: for exponential distribution 选择压力，用于指数分布
% pause(0.01); % Due to a bug in older versions of MATLAB

%% Initialization

empty_individual.Position = [];
empty_individual.gongxian = 0;
empty_individual.Cost = inf;  % 初始化一个空个体empty_individual，其位置为空，成本为无穷大

pop = repmat(empty_individual, nPop, 1); % 重复数组函数，empty_individual是要重复的数组，nPop 和 1 分别是沿行和列方向的重复次数
                                         % 注意：重复1次表示不变，使用repmat函数创建一个种群pop，包含nPop个这样的空个体

for i = 1:nPop
    % Initialize Position
    pop(i).Position = InitAssignment(model);  % 生成一个初始的任务分配方案
    % Evaluation
    pop(i).Cost = CostFunction(pop(i).Position,model);  % 计算成本
end

% Sort Population
Costs = [pop.Cost];
[Costs, SortOrder] = sort(Costs);
pop = pop(SortOrder);

% Store Best Solution
BestSol = pop(1);
% Array to Hold Best Cost Values
BestCost = zeros(MaxIt, 1); 
% Store Cost
WorstCost = pop(end).Cost;

%% 初始化奖惩机制参数
mutation_weights = [0.25, 0.25, 0.25, 0.25]; % 四种策略的初始权重
strategy_performance = cell(1, 4); % 策略性能记录
for i = 1:4
    strategy_performance{i} = [];
end

%% Main Loop
tic;
for it = 1:MaxIt

    % Calculate Selection Probabilities
    P = exp(-beta*Costs/WorstCost);
    P = P/sum(P);
    
    % 自学习
    popt = repmat(empty_individual, nt, 1);
    for k = 1:nt
        k1 = RouletteWheelSelection(P);
        parent = pop(k1);
        
        best_mutant = parent; % 初始化最佳个体
        best_cost = parent.Cost;
        
        % 以一定概率接受较差的解
        for inner_iter = 1:4
            mutant = parent;
            mutant.Position = Tubian(parent.Position, model.M);
            mutant.Cost = CostFunction(mutant.Position, model);
    
            % 模拟退火接受准则
            if mutant.Cost < best_cost || rand() < exp((best_cost - mutant.Cost) / (best_cost * (MaxIt - it + 1)/MaxIt))
                best_mutant = mutant;
                best_cost = mutant.Cost;
            end
        end
        
        % 使用最佳结果
        popt(k) = best_mutant;
    end
    
    Costs = [popt.Cost];   
    [~, SortOrder] = sort(Costs);
    popt = popt(SortOrder);
    tubian_Population = [popt; pop(1:nPop-nt)];
    
    % 创建精英教师库（每代前20%的个体）
    elite_threshold = max(1, round(0.2 * nPop));
    elite_teachers = cell(1, elite_threshold);
    for i = 1:elite_threshold
        elite_teachers{i} = popt(i).Position;
    end
    
    % Crossover
    popc = repmat(empty_individual, nc, 1);
    for k = 1:nc
        % Select Parents Indices
        i1 = RouletteWheelSelection(P);
        i2 = RouletteWheelSelection(P);
    
        % Select Parents
        p1 = pop(i1);
        p2 = pop(i2);
        
        % Apply Crossover      
        popc(k).Position = Crossover(p1.Position, p2.Position, model, elite_teachers);

        % Evaluate Offsprings
        popc(k).Cost = CostFunction(popc(k).Position, model);
    end
    Costs = [popc.Cost];   
    [~, SortOrder] = sort(Costs);
    popc = popc(SortOrder);
    crossPopulation = [pop(1:nPop-nc); popc];
      
    % Mutation - 使用滑动窗口平均改进率奖惩
    popm = repmat(empty_individual, nm, 1);
    
    for k = 1:nm
        % Select Parent
        i = randi([1 nPop]);
        p = crossPopulation(i);
        
        % 选择教师（从精英库中选择）
        if ~isempty(elite_teachers)
            teacher = elite_teachers{randi(length(elite_teachers))};
        else
            teacher = BestSol.Position;
        end
        
        % 记录原始成本
        original_cost = p.Cost;
        
        % 基于权重随机选择变异策略
        r = rand();
        cumulative_weight = 0;
        used_strategy = 0;
        
        for strategy_idx = 1:4
            cumulative_weight = cumulative_weight + mutation_weights(strategy_idx);
            if r <= cumulative_weight
                used_strategy = strategy_idx;
                break;
            end
        end
        
        % 应用选中的变异策略
        switch used_strategy
            case 1 % 瓶颈导向式变异
                popm(k).Position = TeachingMutate_Bottleneck(...
                    p.Position, teacher, model, it, MaxIt);
                
            case 2 % 任务重分配式变异
                popm(k).Position = TeachingMutate_Reassignment(...
                    p.Position, teacher, model, it, MaxIt);
                
            case 3 % 模式学习式变异
                popm(k).Position = TeachingMutate_PatternLearning(...
                    p.Position, teacher, model);
                
            case 4 % 自适应组合变异
                popm(k).Position = TeachingMutate_Adaptive(...
                    p.Position, teacher, model, it, MaxIt);
        end
        
        % Evaluate Mutant
        popm(k).Cost = CostFunction(popm(k).Position, model);
        
        % 计算改进率
        improvement = max(0, (original_cost - popm(k).Cost) / original_cost);
        
        % 使用滑动窗口平均改进率奖惩更新权重
        [mutation_weights, strategy_performance] = updateWeightsSimple(...
            mutation_weights, strategy_performance, used_strategy, improvement);
    end
    
    Costs = [popm.Cost];   
    [~, SortOrder] = sort(Costs);
    popm = popm(SortOrder);
    
    % 合并种群
%     pop = [popt(1); popc; popm(1:27); pop(1)];
    pop = [popt(1); popc; popm; pop(1:nPop-nc-nm-1)];

    % Sort Population
    Costs = [pop.Cost];
    [Costs, SortOrder] = sort(Costs);
    pop = pop(SortOrder);
    
    % Update Worst Cost
    WorstCost = max(WorstCost, pop(end).Cost);
    
    % Truncation
    pop = pop(1:nPop);
    Costs = Costs(1:nPop);
    
    % Store Best Solution Ever Found
    BestSol = pop(1);
    
    % Store Best Cost Ever Found
    BestCost(it) = BestSol.Cost;
    
    % 显示迭代信息和当前策略权重
    disp(['Iteration ' num2str(it) ': Best Cost = ' num2str(BestCost(it))]);
%     disp(['Strategy Weights: ' num2str(mutation_weights)]);
end
[~, ~, total_uphill, total_energy] = CostFunction(BestSol.Position, model);
disp(['最优方案累计爬坡量: ', num2str(total_uphill), ' m']);
disp(['最优方案总能耗: ', num2str(total_energy), ' L']);

elapsedTime = toc;
disp(['Elapsed time for ' num2str(MaxIt) ' iterations: ' num2str(elapsedTime) ' seconds']);

%% Results
% PlotAssignments(model, BestSol.Position, 1);
% 
% figure;
% semilogy(BestCost, 'LineWidth', 2);
% plot(BestCost,'r', 'LineWidth', 2);
% xlabel('Iteration');
% ylabel('Cost');
% legend('改进');
% grid on;