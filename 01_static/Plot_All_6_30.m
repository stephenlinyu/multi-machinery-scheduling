clc;
clear;
close all;
% % 读取第一个数据表
% % 自适应
% data_table1 = readtable('data_6_30.xlsx', 'Sheet', 1);
% data_array1 = table2array(data_table1);
% average_cost1 = mean(data_array1, 2);
% 
% % 读取第二个数据表
% data_table2 = readtable('data_6_30.xlsx', 'Sheet', 2);
% data_array2 = table2array(data_table2);
% average_cost2 = mean(data_array2, 2);
% 
% data_table3 = readtable('data_6_30.xlsx', 'Sheet', 3);
% data_array3 = table2array(data_table3);
% average_cost3 = mean(data_array3, 2);
% 
% data_table4 = readtable('data_6_30.xlsx', 'Sheet', 4);
% data_array4 = table2array(data_table4);
% average_cost4 = mean(data_array4, 2);
% 
% data_table5 = readtable('data_6_30.xlsx', 'Sheet', 5);
% data_array5 = table2array(data_table5);
% average_cost5 = mean(data_array5, 2);
% 
% % 教学
% % data_table6 = readtable('data_6_30.xlsx', 'Sheet', 6);
% % data_array6 = table2array(data_table6);
% % average_cost6 = mean(data_array6, 2);
% 
% data_table7 = readtable('data_6_30.xlsx', 'Sheet', 7);
% data_array7 = table2array(data_table7);
% average_cost7 = mean(data_array7, 2);
% % 绘制图形
% figure;
% hold on; % 保持当前图形，允许在同一画布上绘制多条曲线
% 
% % 绘制第一个算法的平均成本
% plot(1:size(data_array1, 1), average_cost1, 'r', 'LineWidth', 1.5);
% % plot(1:size(data_array6, 1), average_cost6, 'r', 'LineWidth', 1.5);
% plot(1:size(data_array2, 1), average_cost2, 'b-.', 'LineWidth', 1.5);
% plot(1:size(data_array3, 1), average_cost3, 'k--', 'LineWidth', 1.5);
% plot(1:size(data_array4, 1), average_cost4, 'g:', 'LineWidth', 1.5);
% plot(1:size(data_array5, 1), average_cost5, 'Color',[1,0.5,0],'LineStyle','--','LineWidth', 1.5);
% plot(1:size(data_array7, 1), average_cost7, 'Color',[0.5,0.1,0.6],'LineStyle','-.', 'LineWidth', 1.5);
% 
% 
% % xlabel('迭代次数');
% % ylabel('平均成本');
% xlabel('Iterations');
% ylabel('Average cost');
% % title('随迭代变化的平均成本');
% legend('ADMGA', 'MGGA','GA','MGA','ISA-CO', 'AGA-ACO'); % 更新图例
% % legend('GAWTM', 'MGGA','GA','MGA','ISA-CO','AGA-ACO'); % 更新图例
% hold off; % 关闭保持模式
% 
% clc;
% clear;
% 
% % 读取第一个数据表
% data_table1 = readtable('time_6_30.xlsx', 'Sheet', 1);
% data_array1 = table2array(data_table1);
% average_cost1 = mean(data_array1, 2);
% 
% % 读取第二个数据表
% data_table2 = readtable('time_6_30.xlsx', 'Sheet', 2);
% data_array2 = table2array(data_table2);
% average_cost2 = mean(data_array2, 2);
% 
% data_table3 = readtable('time_6_30.xlsx', 'Sheet', 3);
% data_array3 = table2array(data_table3);
% average_cost3 = mean(data_array3, 2);
% 
% data_table4 = readtable('time_6_30.xlsx', 'Sheet', 4);
% data_array4 = table2array(data_table4);
% average_cost4 = mean(data_array4, 2);
% 
% data_table5 = readtable('time_6_30.xlsx', 'Sheet', 5);
% data_array5 = table2array(data_table5);
% average_cost5 = mean(data_array5, 2);
% 
% % data_table6 = readtable('time_8_30.xlsx', 'Sheet', 6);
% % data_array6 = table2array(data_table6);
% % average_cost6 = mean(data_array6, 2);
% 
% data_table7 = readtable('time_6_30.xlsx', 'Sheet', 7);
% data_array7 = table2array(data_table7);
% average_cost7 = mean(data_array7, 2);
% % 绘制图形
% figure;
% hold on; % 保持当前图形，允许在同一画布上绘制多条曲线
% 
% % 绘制第一个算法的平均成本
% plot(1:size(data_array1, 1), average_cost1, 'r', 'LineWidth', 1.5);
% % plot(1:size(data_array6, 1), average_cost6, 'r', 'LineWidth', 1.5);
% plot(1:size(data_array2, 1), average_cost2, 'b-.', 'LineWidth', 1.5);
% plot(1:size(data_array3, 1), average_cost3, 'k--', 'LineWidth', 1.5);
% plot(1:size(data_array4, 1), average_cost4, 'g:', 'LineWidth', 1.5);
% plot(1:size(data_array5, 1), average_cost5, 'Color',[1,0.5,0],'LineStyle','--','LineWidth', 1.5);
% plot(1:size(data_array7, 1), average_cost7, 'Color',[0.5,0.1,0.6],'LineStyle','-.', 'LineWidth', 1.5);
% 
% % xlabel('时间/s');
% % ylabel('平均成本');
% xlabel('Time/s');
% ylabel('Average cost');
% % title('随时间变化的平均成本');
% legend('ADMGA', 'MGGA','GA','MGA','ISA-CO', 'AGA-ACO'); % 更新图例
% % legend('GAWTM', 'MGGA','GA','MGA','ISA-CO','AGA-ACO'); % 更新图例
% hold off; % 关闭保持模式

%% 读取第一个数据表
% 自适应
% data_table1 = readtable('data_6_30.xlsx', 'Sheet', 1);
% data_array1 = table2array(data_table1);
% average_cost1 = mean(data_array1, 2);

% 读取第二个数据表
data_table2 = readtable('data_6_30.xlsx', 'Sheet', 2);
data_array2 = table2array(data_table2);
average_cost2 = mean(data_array2, 2);

data_table3 = readtable('data_6_30.xlsx', 'Sheet', 3);
data_array3 = table2array(data_table3);
average_cost3 = mean(data_array3, 2);

data_table4 = readtable('data_6_30.xlsx', 'Sheet', 4);
data_array4 = table2array(data_table4);
average_cost4 = mean(data_array4, 2);

data_table5 = readtable('data_6_30.xlsx', 'Sheet', 5);
data_array5 = table2array(data_table5);
average_cost5 = mean(data_array5, 2);

% 教学
data_table6 = readtable('data_6_30.xlsx', 'Sheet', 6);
data_array6 = table2array(data_table6);
average_cost6 = mean(data_array6, 2);

data_table7 = readtable('data_6_30.xlsx', 'Sheet', 7);
data_array7 = table2array(data_table7);
average_cost7 = mean(data_array7, 2);
% 绘制图形
figure;
hold on; % 保持当前图形，允许在同一画布上绘制多条曲线

% 绘制第一个算法的平均成本
% plot(1:size(data_array1, 1), average_cost1, 'r', 'LineWidth', 1.5);
plot(1:size(data_array6, 1), average_cost6, 'r', 'LineWidth', 1.5);
plot(1:size(data_array2, 1), average_cost2, 'b-.', 'LineWidth', 1.5);
plot(1:size(data_array3, 1), average_cost3, 'k--', 'LineWidth', 1.5);
plot(1:size(data_array4, 1), average_cost4, 'g:', 'LineWidth', 1.5);
plot(1:size(data_array5, 1), average_cost5, 'Color',[1,0.5,0],'LineStyle','--','LineWidth', 1.5);
plot(1:size(data_array7, 1), average_cost7, 'Color',[0.5,0.1,0.6],'LineStyle','-.', 'LineWidth', 1.5);


xlabel('迭代次数');
ylabel('平均成本');
% xlabel('Iterations');
% ylabel('Average cost');
% title('随迭代变化的平均成本');
% legend('ADMGA', 'MGGA','GA','MGA','ISA-CO', 'AGA-ACO'); % 更新图例
legend('GAWTM', 'MGGA','GA','MGA','ISA-CO','AGA-ACO'); % 更新图例
hold off; % 关闭保持模式

clc;
clear;

% 读取第一个数据表
% data_table1 = readtable('time_6_30.xlsx', 'Sheet', 1);
% data_array1 = table2array(data_table1);
% average_cost1 = mean(data_array1, 2);

% 读取第二个数据表
data_table2 = readtable('time_6_30.xlsx', 'Sheet', 2);
data_array2 = table2array(data_table2);
average_cost2 = mean(data_array2, 2);

data_table3 = readtable('time_6_30.xlsx', 'Sheet', 3);
data_array3 = table2array(data_table3);
average_cost3 = mean(data_array3, 2);

data_table4 = readtable('time_6_30.xlsx', 'Sheet', 4);
data_array4 = table2array(data_table4);
average_cost4 = mean(data_array4, 2);

data_table5 = readtable('time_6_30.xlsx', 'Sheet', 5);
data_array5 = table2array(data_table5);
average_cost5 = mean(data_array5, 2);

data_table6 = readtable('time_8_30.xlsx', 'Sheet', 6);
data_array6 = table2array(data_table6);
average_cost6 = mean(data_array6, 2);

data_table7 = readtable('time_6_30.xlsx', 'Sheet', 7);
data_array7 = table2array(data_table7);
average_cost7 = mean(data_array7, 2);
% 绘制图形
figure;
hold on; % 保持当前图形，允许在同一画布上绘制多条曲线

% 绘制第一个算法的平均成本
% plot(1:size(data_array1, 1), average_cost1, 'r', 'LineWidth', 1.5);
plot(1:size(data_array6, 1), average_cost6, 'r', 'LineWidth', 1.5);
plot(1:size(data_array2, 1), average_cost2, 'b-.', 'LineWidth', 1.5);
plot(1:size(data_array3, 1), average_cost3, 'k--', 'LineWidth', 1.5);
plot(1:size(data_array4, 1), average_cost4, 'g:', 'LineWidth', 1.5);
plot(1:size(data_array5, 1), average_cost5, 'Color',[1,0.5,0],'LineStyle','--','LineWidth', 1.5);
plot(1:size(data_array7, 1), average_cost7, 'Color',[0.5,0.1,0.6],'LineStyle','-.', 'LineWidth', 1.5);

xlabel('时间/s');
ylabel('平均成本');
% xlabel('Time');
% ylabel('Average cost');
% title('随时间变化的平均成本');
% legend('ADMGA', 'MGGA','GA','MGA','ISA-CO', 'AGA-ACO'); % 更新图例
legend('GAWTM', 'MGGA','GA','MGA','ISA-CO','AGA-ACO'); % 更新图例
hold off; % 关闭保持模式