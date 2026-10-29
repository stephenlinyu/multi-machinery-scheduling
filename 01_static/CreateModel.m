% Create model

function model = CreateModel()
    %---------------------------------------------------------------------%
    % Initialize global variables
    %---------------------------------------------------------------------%
    
    WORLD.CLR  = rand(100,3);  %每行代表一个RGB颜色，数字表示亮度（亮度范围0-255）
    
    WORLD.XMIN = 0;
    WORLD.XMAX =  10.0;
    WORLD.YMIN = 0;
    WORLD.YMAX =  10.0;

    WORLD.MAX_DISTANCE = sqrt((WORLD.XMAX - WORLD.XMIN)^2 + ...
                              (WORLD.YMAX - WORLD.YMIN)^2 );
     
    %---------------------------------------------------------------------%
    % Define agents and tasks
    %---------------------------------------------------------------------%
    % Grab agent and task types from CBBA Parameter definitions
    
    % Initialize possible agent fields
    agent_default.id    = 0;            % agent id
    agent_default.clr = [];             % for plotting
    agent_default.nom_vel = 0;          % agent cruise velocity (m/s)(km/h)*
    agent_default.vel_task= 0;          % 作业平均速度(km/h) *
    agent_default.wide    = 0;          % 机器作业宽度(m) *
    agent_default.w       = 0;          % 平均作业能力（m^2/h）*
    agent_default.tturn   = 0;          % 第i 台农机作业中每次调头的平均时间( h)*
    agent_default.fuel    = 0;          % agent fuel penalty (per meter)(L/h)*
    agent_default.fueltask= 0;          % 农机作业时单位时间的平均油耗( L / h)*
    
    agent_default.x       = 0;          % agent position (meters)
    agent_default.y       = 0;          % agent position (meters)
    
    % Initialize possible task fields
    task_default.id       = 0;          % task id
    task_default.kuan     = 0;          % 表示任务垂直作业路径的宽度(m)*
    task_default.chang    = 0;          % 表示任务平行作业路径的长度 (m)*
    task_default.S        = 0;          % 表示任务的作业面积 *
    task_default.duration = 0;          % task default duration (sec)
    
    task_default.x        = 0;          % task position (meters)
    task_default.y        = 0;          % task position (meters)
    
    % List agent types 
    AGENT_TYPES.CAR1   = 1;  %定义了agent类型的枚举
    AGENT_TYPES.CAR2   = 2;
    AGENT_TYPES.CAR3   = 3;
    
    % List task types
    TASK_TYPES.TRACK   =1;
    
    % Create some default agents
    % CAR1
    agent_car1         = agent_default;
    agent_car1.type    = AGENT_TYPES.CAR1;  % agent type
    agent_car1.nom_vel = 4;         % agent cruise velocity (m/s)
    agent_car1.vel_task= 2;          % 作业平均速度(km/h) *
    agent_car1.wide    = 6.9;        % 机器作业宽度(m) *
    agent_car1.w       = 7000;       % 平均作业能力（m^2/h）*
    agent_car1.tturn   = 0.004;      % 第i 台农机作业中每次调头的平均时间( h)*
    agent_car1.fuel    = 1;          % agent fuel penalty (per meter)(L/h)*
    agent_car1.fueltask= 2;          % 农机作业时单位时间的平均油耗( L / h)*
    
    % CAR2
    agent_car2         = agent_default;
    agent_car2.type    = AGENT_TYPES.CAR2;  % agent type
    agent_car2.nom_vel = 10;        % agent cruise velocity
    agent_car2.vel_task= 5;          % 作业平均速度(km/h) *
    agent_car2.wide    = 5.5;         % 机器作业宽度(m) *
    agent_car2.w       = 3000;        % 平均作业能力（m^2/min）*
    agent_car2.tturn   = 0.003;       % 第i 台农机作业中每次调头的平均时间( h)*
    agent_car2.fuel    = 2.5;         % agent fuel penalty (per meter)(L/h)*
    agent_car2.fueltask= 5;           % 农机作业时单位时间的平均油耗( L / h)*
    
    % CAR3
    agent_car3         = agent_default;
    agent_car3.type    = AGENT_TYPES.CAR3;  % agent type
    agent_car3.nom_vel = 5;        % agent cruise velocity (m/s)
    agent_car3.vel_task= 3;           % 作业平均速度(km/h) *
    agent_car3.wide    = 3.7;         % 机器作业宽度(m) *
    agent_car3.w       = 4000;        % 平均作业能力（m^2/h）*
    agent_car3.tturn   = 0.002;       % 第i 台农机作业中每次调头的平均时间( h)*
    agent_car3.fuel    = 2;           % agent fuel penalty (per meter)(L/h)*
    agent_car3.fueltask= 4;           % 农机作业时单位时间的平均油耗( L / h)*
    
    % Create some default tasks
    
    % Track
    task_track          = task_default;
    task_track.type     = TASK_TYPES.TRACK;      % task type
   
    
    %---------------------------------------------------------------------%
    % Define sample scenario
    %---------------------------------------------------------------------%
    
    N = 8;      % number of agents
    M = 30;     % number of tasks


    % Create  agents and define parameters for each agents
    for n=1:N
            agents(n) = agent_car2; 
        if n<=N/2;
        agents(n).x    = 0.3*(WORLD.XMAX-WORLD.XMIN)+WORLD.XMIN;
        agents(n).y    = 0.3*(WORLD.XMAX-WORLD.XMIN)+WORLD.YMIN;

        else
        agents(n).x    = 0.7*(WORLD.XMAX-WORLD.XMIN)+WORLD.XMIN;
        agents(n).y    = 0.3*(WORLD.XMAX-WORLD.XMIN)+WORLD.YMIN;
        end
        % Init remaining agent parameters
        agents(n).id   = n;  %为每一个agent分配唯一标识符（ID）
        agents(n).clr  = WORLD.CLR(n,:);  %从之前定义的rand矩阵中分配颜色
    end
    
    % Create tasks
 fixed_task_positions = [
    0 0 750; 2 1 770; 0.5 3 1200; 1.5 4 960; 4 4 1064; 5 2 1100; 4 1 1000; % 7
    0 7 600; 1 6 700; 3 5 400; 4 6 1080; 1 8 1026; 2 10 975; 4 9 966;  % 7
    6 1 1056; 8 0 1032; 10 2 1107; 9 4 980; 6 2 1200; 5.5 4 1125; 6 5 1034; 8 4 576; % 8
    6 7 969; 5 6 950; 7 5 1173; 
    8 6 1040; 6 8 700; 7 10 648; 8 9 529; 10 7 1044; % 8
    0.2 1.5 1250; 3 2 825; 0.5 10 1400; 2.8 7.5 1430; 5.5 10 1800; % 5
    7.5 7.5 1020; 9.5 9.5 972; 9.7 5 1140; 10 0.1 800; 8.2 1.5 900; % 5
];

    for m=1:M
        tasks(m) = task_track;
        tasks(m).id       = m;
        tasks(m).x = fixed_task_positions(m, 1);
        tasks(m).y = fixed_task_positions(m, 2);
        tasks(m).S = fixed_task_positions(m, 3);
%         tasks(m).x = rand(1)*(WORLD.XMAX-WORLD.XMIN)+WORLD.XMIN;
%         tasks(m).y =rand(1)*(WORLD.YMAX-WORLD.YMIN)+WORLD.YMIN;
    end 

    model = WORLD;  %WORLD结构体赋值给变量model，model 是一个包含多个属性的结构体，如，tasks和agents属性，它本身是一个结构体数组，包含了有关代理的信息
    model.tasks = tasks;  %将之前定义的tasks数组（任务信息）赋给model结构体的tasks属性，model中就包含任务信息
    model.agents = agents;
    model.N = N;
    model.M = M;
end
