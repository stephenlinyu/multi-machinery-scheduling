function agent_idx = findAgentWithTask(individual, task)
    % 查找包含指定任务的机器
    agent_idx = 0;
    for i = 1:length(individual.agents)
        if ismember(task, individual.agents(i).task)
            agent_idx = i;
            return;
        end
    end
end