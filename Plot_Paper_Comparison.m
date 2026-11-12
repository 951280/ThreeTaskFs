% 文件: Plot_Paper_Comparison.m
% 功能: 加载本地保存的 .mat 文件，对比 "Ours" 和 "NSGA-II"
% 自动绘制：1. Pareto 前沿对比图  2. 收敛曲线对比图

clc; clear; close all;

% ================= 配置区 =================
DatasetName = 'SONAR';   % 你要看哪个数据集
RunID = 1;               % 你要看第几次运行的结果
BaseDir = 'Results';     % 结果根目录

% 设定文件路径 (请根据你实际下载回来的路径修改)
% 1. 你的算法结果
Dir_Ours = fullfile(BaseDir, [DatasetName, '_Full']); 
% 注意：如果是用时间戳保存的，你需要手动指定文件名，或者用 dir 找最新的
% 这里假设你改成了 Result_Run1.mat 这种格式
File_Ours = fullfile(Dir_Ours, sprintf('Result_Run%d.mat', RunID));

% 2. NSGA-II 结果
Dir_NSGA = fullfile(BaseDir, [DatasetName, '_NSGAII']);
File_NSGA = fullfile(Dir_NSGA, sprintf('Result_Run%d.mat', RunID));
% =========================================

% --- 加载数据 ---
Data_Ours = load(File_Ours); % 包含 Final_PF, History
Data_NSGA = load(File_NSGA); % 包含 Final_PF, ParetoFront_History

% --- 绘图 1: Pareto 前沿对比 (Scatter Plot) ---
figure('Name', ['Pareto Front: ', DatasetName], 'Color', 'w', 'Position', [100, 100, 600, 500]);
hold on;

% 1. 画 NSGA-II (灰色/蓝色，作为基准)
PF_NSGA = Data_NSGA.Final_PF;
Cost_NSGA = [PF_NSGA.Cost]; % 假设 Cost 是 [Error, Ratio]
if size(Cost_NSGA, 1) == 2, Cost_NSGA = Cost_NSGA'; end
% 转换 Ratio -> Count (如果 NSGA 存的是比率)
D_total = Data_NSGA.params.D_total; % 或者是手动指定维度
% 如果 NSGA 代码里存了 FeatCount 最好，直接用
if isfield(PF_NSGA, 'FeatCount')
    X_NSGA = [PF_NSGA.FeatCount];
else
    X_NSGA = Cost_NSGA(:, 2) * 60; % 假设 SONAR D=60，或者从 params 读取
end
Y_NSGA = Cost_NSGA(:, 1); % Error Rate

plot(X_NSGA, Y_NSGA, 'o', 'MarkerSize', 6, 'MarkerEdgeColor', [0.5 0.5 0.5], 'MarkerFaceColor', 'none', 'DisplayName', 'NSGA-II');

% 2. 画 Ours (红色/实心，作为主角)
PF_Ours = Data_Ours.Final_PF;
% 你的 Individual 结构体里通常有 FeatureCount 和 Accuracy
X_Ours = [PF_Ours.FeatureCount];
Y_Ours = 1 - [PF_Ours.Accuracy]; % 转换 Accuracy -> Error Rate

plot(X_Ours, Y_Ours, 'pentagram', 'MarkerSize', 9, 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', 'DisplayName', 'MT-GF-MoFS (Ours)');

% 美化
xlabel('Number of Features');
ylabel('Classification Error Rate');
title(['Pareto Front Comparison on ', DatasetName]);
legend('Location', 'best');
grid on; box on;
hold off;

% --- 绘图 2: 收敛曲线对比 (Line Plot) ---
figure('Name', ['Convergence: ', DatasetName], 'Color', 'w', 'Position', [750, 100, 600, 500]);
hold on;

% 1. 提取 NSGA-II 收敛数据 (最高精度)
Hist_NSGA = Data_NSGA.ParetoFront_History;
Curve_NSGA = zeros(1, length(Hist_NSGA));
for g = 1:length(Hist_NSGA)
    if ~isempty(Hist_NSGA{g})
        Curve_NSGA(g) = max([Hist_NSGA{g}.Acc]); % 取每代最高精度
    end
end
% 补齐 (防止空代)
Curve_NSGA(Curve_NSGA==0) = NaN;
plot(1:length(Curve_NSGA), Curve_NSGA, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5, 'DisplayName', 'NSGA-II (Best Acc)');

% 2. 提取 Ours 收敛数据
% 你的 Experiment_History 记录了 Mean_Fit1, Acc_Elite2 等
% 通常我们看 Task 1 (Population 1) 的演化，或者 Elite2 的精度
Hist_Ours = Data_Ours.History;
% 注意：根据你的 struct 结构提取
Curve_Ours = [Hist_Ours.Acc_Elite2]; % 或者是主任务的最佳精度，看你存了哪个
% 如果 History 是 struct array
if isstruct(Hist_Ours)
    Gens = [Hist_Ours.Gen];
    Curve_Ours = [Hist_Ours.Acc_Elite2]; 
end

plot(Gens, Curve_Ours, 'r-', 'LineWidth', 2, 'DisplayName', 'MT-GF-MoFS (Elite Acc)');

% 美化
xlabel('Generation');
ylabel('Classification Accuracy');
title(['Convergence Curve on ', DatasetName]);
legend('Location', 'Southeast');
grid on; box on;

disp('绘图完成！图片已生成。');