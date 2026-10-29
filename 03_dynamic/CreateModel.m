% Create model
function model = CreateModel()
    %---------------------------------------------------------------------%
    % Initialize global variables
    %---------------------------------------------------------------------%
    
    WORLD.CLR  = rand(100,3);
    WORLD.XMIN = 0;
    WORLD.XMAX = 10.0;
    WORLD.YMIN = 0;
    WORLD.YMAX = 10.0;
    WORLD.MAX_DISTANCE = sqrt((WORLD.XMAX - WORLD.XMIN)^2 + ...
                              (WORLD.YMAX - WORLD.YMIN)^2);
     
    %---------------------------------------------------------------------%
    % Define agents and tasks
    %---------------------------------------------------------------------%
    
    % Initialize possible agent fields
    agent_default.id    = 0;
    agent_default.clr = [];
    agent_default.nom_vel = 0;
    agent_default.vel_task= 0;
    agent_default.wide    = 0;
    agent_default.w       = 0;
    agent_default.tturn   = 0;
    agent_default.fuel    = 0;
    agent_default.fueltask= 0;
    agent_default.x       = 0;
    agent_default.y       = 0;
    agent_default.available = 1;  % 新增：农机可用状态
    
    % Initialize possible task fields
    task_default.id       = 0;
    task_default.kuan     = 0;
    task_default.chang    = 0;
    task_default.S        = 0;
    task_default.duration = 0;
    task_default.x        = 0;
    task_default.y        = 0;
    task_default.status   = 'pending';  % 新增：任务状态（pending/completed）
    
    % List agent types 
    AGENT_TYPES.CAR1   = 1;
    AGENT_TYPES.CAR2   = 2;
    AGENT_TYPES.CAR3   = 3;
    
    % List task types
    TASK_TYPES.TRACK   = 1;
    
    % Create some default agents
    % CAR1
    agent_car1 = agent_default;
    agent_car1.type = AGENT_TYPES.CAR1;
    agent_car1.nom_vel = 4;
    agent_car1.vel_task = 2;
    agent_car1.wide = 6.9;
    agent_car1.w = 7000;
    agent_car1.tturn = 0.004;
    agent_car1.fuel = 1;
    agent_car1.fueltask = 2;
    
    % CAR2
    agent_car2 = agent_default;
    agent_car2.type = AGENT_TYPES.CAR2;
    agent_car2.nom_vel = 10;
    agent_car2.vel_task = 5;
    agent_car2.wide = 5.5;
    agent_car2.w = 3000;
    agent_car2.tturn = 0.003;
    agent_car2.fuel = 2.5;
    agent_car2.fueltask = 5;
    
    % CAR3
    agent_car3 = agent_default;
    agent_car3.type = AGENT_TYPES.CAR3;
    agent_car3.nom_vel = 5;
    agent_car3.vel_task = 3;
    agent_car3.wide = 3.7;
    agent_car3.w = 4000;
    agent_car3.tturn = 0.002;
    agent_car3.fuel = 2;
    agent_car3.fueltask = 4;
    
    % Create some default tasks
    task_track = task_default;
    task_track.type = TASK_TYPES.TRACK;
    
    %---------------------------------------------------------------------%
    % Define sample scenario
    %---------------------------------------------------------------------%
    
    N = 4;      % number of agents
    M = 20;      % number of tasks

    % Create agents and define parameters for each agents
    for n = 1:N
        if n <= N/2
            agents(n) = agent_car2;
            agents(n).x = 0.3*(WORLD.XMAX-WORLD.XMIN) + WORLD.XMIN;
            agents(n).y = 0.3*(WORLD.XMAX-WORLD.XMIN) + WORLD.YMIN;
        else
            agents(n) = agent_car2;
            agents(n).x = 0.7*(WORLD.XMAX-WORLD.XMIN) + WORLD.XMIN;
            agents(n).y = 0.3*(WORLD.XMAX-WORLD.XMIN) + WORLD.YMIN;
        end
        agents(n).id = n;
        agents(n).clr = WORLD.CLR(n,:);
        agents(n).available = 1;  % 新增：初始化可用状态
    end
    
    % Create tasks
    fixed_task_positions = [
        0 0 750; 2 1 770; 0.5 3 1200; 1.5 4 960; 4 4 1064; 
        5 2 1100; 4 1 1000; 0 7 600; 1 6 700; 3 5 400; 
        4 6 1080; 1 8 1026; 2 10 975; 4 9 966; 6 1 1056; 
        8 0 1032; 10 2 1107; 9 4 980; 6 2 1200; 5.5 4 1125; 
        6 5 1034; 8 4 576; 6 7 969; 5 6 950; 7 5 1173; 
        8 6 1040; 6 8 700; 7 10 648; 8 9 529; 10 7 1044;
        0.2 1.5 1250; 3 2 825; 0.5 10 1400; 2.8 7.5 1430; 5.5 10 1800;
        7.5 7.5 1020; 9.5 9.5 972; 9.7 5 1140; 10 0.1 800; 8.2 1.5 900;
    ];

    for m = 1:M
        tasks(m) = task_track;
        tasks(m).id = m;
        tasks(m).x = fixed_task_positions(m, 1);
        tasks(m).y = fixed_task_positions(m, 2);
        tasks(m).S = fixed_task_positions(m, 3);
        tasks(m).status = 'pending';  % 新增：初始化任务状态
    end

    model = WORLD;
    model.tasks = tasks;
    model.agents = agents;
    model.N = N;
    model.M = M;
end