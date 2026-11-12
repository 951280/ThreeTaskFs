% 文件: Check_NSGAII_Style_Save.m
% 功能: 检查 NSGA-II 结果，绘制"橙色点集"风格，并自动保存图片

clc; clear; close all;

% ================= 配置区 =================
DatasetName = 'SONAR';      % 数据集名称
RunID = 1;                  % 运行编号
BaseDir = 'D:\code\ThreeTaskFs\Results'; % 你的绝对路径
% =========================================

% 1. 构建路径
ResultDir = fullfile(BaseDir, [DatasetName, '_NSGAII']);
ResultFile = fullfile(ResultDir, sprintf('Result_Run%d.mat', RunID));

% 检查文件
if ~exist(ResultFile, 'file')
    error('【错误】找不到文件: %s', ResultFile);
end

% 2. 加载数据
disp(['正在加载: ', ResultFile]);
Data = load(ResultFile); 
PF = Data.Final_PF;

% 3. 设置绘图风格 (Paper Style)
OrangeColor = [0.85 0.32 0.09]; % 经典的学术橙色 (RGB)
GreyColor   = [0.2 0.2 0.2];    % 深灰色用于坐标轴

% 4. 准备画图
fig = figure('Name', ['NSGA-II Check: ', DatasetName], 'Color', 'w', 'Position', [300, 300, 900, 400]);

% --- 子图 1: 帕累托前沿 (橙色散点图) ---
subplot(1, 2, 1);
hold on;

% 提取数据
if isfield(PF, 'FeatCount')
    X_Feat = [PF.FeatCount];
    if isfield(PF, 'Acc'), Y_Error = 1 - [PF.Acc]; 
    else, Y_Error = PF.Cost(1,:); end
elseif isfield(PF, 'Cost')
    Costs = [PF.Cost];
    if size(Costs, 1) == 2
        Y_Error = Costs(1, :);
        X_Feat = Costs(2, :) * Data.params.D_total; 
    else
        Y_Error = Costs(:, 1)';
        X_Feat = Costs(:, 2)' * Data.params.D_total;
    end
end

% ★★★ 核心修改：使用 scatter 画出橙色实心点 ★★★
scatter(X_Feat, Y_Error, 60, 'MarkerFaceColor', OrangeColor, ...
    'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.8);

% 加上网格和标签
xlabel('Number of Features', 'FontWeight', 'bold');
ylabel('Classification Error Rate', 'FontWeight', 'bold');
title(['Pareto Front (Run ', num2str(RunID), ')'], 'FontSize', 12);
grid on; box on;
set(gca, 'LineWidth', 1.2, 'FontSize', 10, 'GridLineStyle', ':');

% --- 子图 2: 收敛过程 (折线图) ---
subplot(1, 2, 2);
History = Data.ParetoFront_History;
MaxGen = length(History);
BestAccCurve = zeros(1, MaxGen);
for g = 1:MaxGen
    Pop = History{g};
    if ~isempty(Pop)
        if isfield(Pop, 'Acc'), BestAccCurve(g) = max([Pop.Acc]);
        elseif isfield(Pop, 'Cost')
            Costs = [Pop.Cost];
            if size(Costs,1)==2, Costs=Costs'; end
            BestAccCurve(g) = 1 - min(Costs(:,1));
        end
    else
        if g>1, BestAccCurve(g) = BestAccCurve(g-1); end
    end
end

plot(1:MaxGen, BestAccCurve, '-', 'Color', OrangeColor, 'LineWidth', 2);
xlabel('Generation', 'FontWeight', 'bold');
ylabel('Best Accuracy', 'FontWeight', 'bold');
title('Convergence Trend', 'FontSize', 12);
grid on; box on;
set(gca, 'LineWidth', 1.2, 'FontSize', 10, 'GridLineStyle', ':');

% 5. ★★★ 自动保存图片 ★★★
% 图片名: NSGAII_Check_Run1.png
SaveName = fullfile(ResultDir, sprintf('NSGAII_Check_Run%d.png', RunID));

saveas(fig, SaveName);
disp('------------------------------------------------');
disp(['>>> 图片已保存至: ', SaveName]);
disp('------------------------------------------------');