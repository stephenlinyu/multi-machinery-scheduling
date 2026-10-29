% SaveStaticResult.m
% 运行一次GA优化，保存最优的静态分配结果

clc;
clear;
close all;

%% Problem Definition
model = CreateModel();
for i = 1:length(model.agents)
    model.agents(i).available = 1;
end

CostFunc = @(x) CostFunction(x, model);

%% GA Parameters
MaxIt = 500;  % 可以运行更多迭代以获得更好的结果
nPop = 70;
pc = 1;
nc = 2*round(pc*nPop/2);
pm = 1;
nm = round(pm*nPop);
beta = 8;

%% Initialization
empty_individual.Position = [];
empty_individual.Cost = inf;

pop = repmat(empty_individual, nPop, 1);

disp('开始静态任务分配优化...');

for i = 1:nPop
    pop(i).Position = InitAssignment(model);
    pop(i).Cost = CostFunc(pop(i).Position);
end

% Sort Population
Costs = [pop.Cost];
[Costs, SortOrder] = sort(Costs);
pop = pop(SortOrder);

% Store Best Solution
BestSol = pop(1);
BestCost = zeros(MaxIt, 1);
WorstCost = pop(end).Cost;

%% Main GA Loop
for it = 1:MaxIt
    P = exp(-beta*Costs/WorstCost);
    P = P/sum(P);
    
    % Crossover
    popc = repmat(empty_individual, nc, 1);
    for k = 1:nc
        i1 = RouletteWheelSelection(P);
        i2 = RouletteWheelSelection(P);
        p1 = pop(i1);
        p2 = pop(i2);
        
        probCrossover = 0.6;
        if rand() < probCrossover
           popc(k).Position = Crossover(p1.Position, p2.Position, model);
        else
            popc(k).Position = CrossoverB(p1.Position);
        end
        popc(k).Cost = CostFunc(popc(k).Position);
    end
    
    Costs = [popc.Cost];   
    [~, SortOrder] = sort(Costs);
    popc = popc(SortOrder); 
    crossPopulation = [popc(1:69); pop(1)];

    % Mutation
    popmA = repmat(empty_individual, nm, 1);
    probMutateA = 0.6;
    r1 = 0;
    
    for k = 1:nm
        i = randi([1 nPop]);
        p = crossPopulation(i);
        if rand() < probMutateA
            p.Position = Mutate(p.Position, model.M);
            r1 = r1 + 1;
        end
        popmA(k) = p;
        popmA(k).Cost = CostFunc(popmA(k).Position);
    end
    
    Costs = [popmA.Cost];   
    [~, SortOrder] = sort(Costs);
    popmA = popmA(SortOrder); 
    popmA = [popmA(1:r1); popc(1:nPop-r1)];
    
    popmB = repmat(empty_individual, nm, 1);
    probMutateB = 0.7;
    r2 = 0;
    
    for k = 1:nm
        i = randi([1 nPop]);
        p = popmA(i);
        if rand() < probMutateB
            p.Position = MutateB(p.Position, model.M);
            r2 = r2 + 1;
        end
        popmB(k) = p;
        popmB(k).Cost = CostFunc(popmB(k).Position);
    end
    
    Costs = [popmB.Cost];   
    [~, SortOrder] = sort(Costs);
    popmB = popmB(SortOrder);    
    popmB = [popmB(1:r2); popc(1:nPop-r2)];
    
    popmC = repmat(empty_individual, nm, 1);
    probMutateC = 1.0;
    r3 = 0;
    
    for k = 1:nm
        i = randi([1 nPop]);
        p = popmB(i);
        if rand() < probMutateC
            p.Position = MutateC(p.Position, model.M);
            r3 = r3 + 1;
        end
        popmC(k) = p;
        popmC(k).Cost = CostFunc(popmC(k).Position);
    end
    
    Costs = [popmC.Cost];   
    [~, SortOrder] = sort(Costs);
    popmC = popmC(SortOrder);    
    
    % Create Merged Population
    pop = [popmC(1:66); popmA(1); popmB(1); popc(1); pop(1)];

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
    BestCost(it) = BestSol.Cost;
    
    fprintf('迭代 %d: 最优代价 = %.4f\n', it, BestCost(it));
end

%% 显示结果
fprintf('\n========== 静态分配最终结果 ==========\n');
fprintf('最优代价: %.4f\n\n', BestSol.Cost);

static_sol = BestSol.Position;

fprintf('静态分配农机任务详情:\n');
for i = 1:model.N
    if ~isempty(static_sol.agents(i).task)
        tasks = static_sol.agents(i).task;
        fprintf('  农机 %2d: 任务 %s\n', i, num2str(tasks));
    else
        fprintf('  农机 %2d: 无任务\n', i);
    end
end

%% 保存结果到文件
save('static_result.mat', 'static_sol', 'BestSol', 'model');
fprintf('\n静态分配结果已保存到 static_result.mat\n');

%% ========== 绘图 ==========

% 图1：静态任务分配迭代收敛曲线
figure(1);
plot(1:MaxIt, BestCost, 'b-', 'LineWidth', 2);
xlabel('迭代次数');
ylabel('最优代价');
title('静态任务分配迭代收敛曲线');
grid on;
set(gca, 'FontSize', 10);

% 图2：静态任务分配路径图（故障前的分配）
figure(2);
PlotAssignmentsWithComparison(model, static_sol, 2, -1, [], [], []);
title('静态任务分配路径图 (初始分配)');