% 文件名: Calc_Metrics_Standalone.m
% 功能: 手动选择 .mat 结果文件，计算 HV 和 IGD 指标
clear; clc;

% 1. 选择文件
disp('请选择一个算法生成的 .mat 结果文件...');
[file, path] = uigetfile('*.mat', '选择 Results_xxx.mat 文件');
if isequal(file, 0)
    disp('用户取消操作');
    return;
end
load(fullfile(path, file));

fprintf('\n>>> 正在分析文件: %s <<<\n', file);

% 2. 提取数据
if ~exist('Final_Pareto_Solutions', 'var')
    error('错误: 文件中找不到 Final_Pareto_Solutions 变量。请确保这是最新代码生成的结果文件。');
end

% 提取错误率 (Error) 和 特征数量 (Count)
Errors = [Final_Pareto_Solutions.Error]'; % 转置为列向量
Counts = [Final_Pareto_Solutions.Count]';

% 3. 归一化 (Normalization)
% HV 计算必须归一化到 [0, 1] 空间，否则特征数量(如 500) 会完全掩盖错误率(如 0.1)
% 尝试从 params 中获取总特征数 D
if exist('params', 'var') && isfield(params, 'InitialSelect') && isfield(params.InitialSelect, 'W')
    D_total = size(params.InitialSelect.W, 1);
elseif exist('Global_Archive', 'var') && ~isempty(Global_Archive)
    % 如果 params 不全，尝试从 Individual 对象推断
    D_total = length(Global_Archive(1).Position);
else
    % 如果实在找不到，弹出输入框让用户确认
    prompt = {'未找到总特征数 D，请输入该数据集的总特征数 (用于归一化):'};
    dlgtitle = '输入参数';
    dims = [1 35];
    definput = {'1000'}; % 默认值
    answer = inputdlg(prompt,dlgtitle,dims,definput);
    if isempty(answer), return; end
    D_total = str2double(answer{1});
end

% 归一化后的种群目标矩阵 [N x 2]
% Column 1: Error (本身就是 0-1)
% Column 2: Feature Ratio (Count / D_total)
PopObj = [Errors, Counts / D_total];

fprintf(' > 数据集: %s (总特征数 D=%d, 前沿解数=%d)\n', dataset_name, D_total, length(Errors));

% 4. 计算 Hypervolume (HV)
% 参考点设置：通常设为比 [1, 1] 稍差一点，例如 [1.1, 1.1]
RefPoint = [1.1, 1.1]; 
HV_Value = Calculate_HV_2D(PopObj, RefPoint);

fprintf('--------------------------------------------------\n');
fprintf('★ Hypervolume (HV) : %.6f  (参考点 [1.1, 1.1])\n', HV_Value);
fprintf('--------------------------------------------------\n');

% 5. 计算 IGD (可选)
% 注意：IGD 需要“真实帕累托前沿 (True PF)”。
% 如果你有该数据集的已知最优解集，可以在这里加载。
% 这里演示如何加载一个假定的 TruePF (仅作示例，实际需替换)

% 假设 params 中存了 TruePF (通常真实数据没有这个，如果是测试函数会有)
if exist('params', 'var') && isfield(params, 'TruePF') && ~isempty(params.TruePF)
    TruePF = params.TruePF;
    IGD_Value = Calculate_IGD(PopObj, TruePF);
    fprintf('★ IGD              : %.6f\n', IGD_Value);
else
    fprintf('   IGD              : [跳过] (未提供真实前沿 TruePF)\n');
    fprintf('   (注意：对于真实数据集，通常没有 TruePF，IGD 无法直接计算，建议主要看 HV)\n');
end
fprintf('--------------------------------------------------\n');


% =========================================================
% 底部辅助函数
% =========================================================

function score = Calculate_HV_2D(PopObj, RefPoint)
    % 简单的二维 HV 计算算法
    % PopObj: [N x 2], 假设都是最小化问题
    
    % 1. 按第一维(错误率)排序
    [~, idx] = sort(PopObj(:,1));
    SortedObj = PopObj(idx, :);
    
    % 2. 过滤掉被参考点支配的解(即超过 1.1 的)
    valid = all(SortedObj <= RefPoint, 2);
    SortedObj = SortedObj(valid, :);
    
    if isempty(SortedObj)
        score = 0; return;
    end
    
    % 3. 累加矩形面积
    score = 0;
    % 对于每一个点，它贡献的面积高度是 (上一个点的Y 或 参考点Y) - 当前Y
    % 宽度是 (参考点X - 当前X)
    
    % 这种算法需要从 X 最大的点开始往回算，或者维护当前 Y 的上限
    % 简单方法：面积 = sum( (SortedObj(i+1, 1) - SortedObj(i, 1)) * (RefPoint(2) - SortedObj(i, 2)) )
    
    % 补充左边界和右边界
    % 我们希望计算并集面积。
    % 排序后 X 递增，对于非支配解，Y 应该递减。
    
    % 确保是非支配集 (过滤掉内部支配的，虽然 Final_Pareto 应该已经过滤了)
    [~, final_idx] = unique(SortedObj(:,1)); 
    SortedObj = SortedObj(final_idx, :); % 去重 X
    
    % 真正的面积计算
    area = 0;
    
    % 哨兵：上一项的 X，初始为第一个点的 X
    % 但为了计算简单，我们可以用 "切条法"
    % 每一个点的覆盖矩形是 [x, ref_x] * [y, ref_y]
    % 排序后：x1 < x2 < x3 ...
    % y1 > y2 > y3 ... (理想情况)
    
    % 第 i 个点贡献的【独特】面积是一个长条：
    % 宽 = (下一个点的 X) - (当前点的 X)
    % 高 = (参考点 Y) - (当前点的 Y)
    
    for i = 1:size(SortedObj, 1)-1
        width = SortedObj(i+1, 1) - SortedObj(i, 1);
        height = RefPoint(2) - SortedObj(i, 2);
        % 只有当 height > 0 才加 (防止非支配排序不严格)
        if height > 0 && width > 0
            area = area + width * height;
        end
    end
    
    % 加上最后一块 (从最后一个点到参考点 X)
    width = RefPoint(1) - SortedObj(end, 1);
    height = RefPoint(2) - SortedObj(end, 2);
    if height > 0 && width > 0
        area = area + width * height;
    end
    
    score = area;
end

function score = Calculate_IGD(PopObj, TruePF)
    % 计算从 TruePF 到 PopObj 的最小距离平均值
    dists = pdist2(TruePF, PopObj, 'euclidean');
    min_dists = min(dists, [], 2);
    score = mean(min_dists);
end