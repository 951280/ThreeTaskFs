% FeatureProcessing/initialFeatureSelection.m

function [initial_population, K1, initial_domain] = initialFeatureSelection(X, Y, W, params, f_eval, task_id)
% INITIALFEATURESELECTION 1. 使用膝点法确定初始特征数量 K1。
%                         2. 使用概率抽样生成初始种群。
%
% 输入:
%   X: [N x D double] 全体特征矩阵。
%   Y: [N x 1 categorical/double] 标签向量。
%   W: [D x 1 double] 特征重要性向量 (例如 W_LGBM 或 W_ReliefF)。
%   params: [struct] 配置参数结构体。
%   f_eval: [function_handle] 评估函数句柄 (@evaluateSubset)。
%   task_id: [int] 任务ID (1, 2, 或 3)。
%
% 输出:
%   initial_population: [Individual array] 初始种群对象数组。
%   K1: [int] 确定的初始特征数量 K1。
%   initial_domain: [vector] 初始种群中所有个体特征的并集。

    D_total = size(X, 2); % 总特征数 D
    PopSize = params.PopSize;

    % --- 1. 确定初始特征数量 K1 (膝点法) ---
    
    % 1.1 特征排序
    [~, Indices_Sorted] = sort(W, 'descend');
    
    % 1.2 评估 Top K 曲线 (只评估一小部分点以提高效率)
    % 抽样点数量
    N_Points = min(D_total, 50); 
    k_values = unique(round(linspace(1, D_total, N_Points))); % 从 1 到 D_total 均匀选取 N_Points 个 k
    
    accuracies = zeros(1, length(k_values));
    
    disp(['  > 正在运行膝点法评估 ', num2str(length(k_values)), ' 个点...']);
    
    for i = 1:length(k_values)
        k = k_values(i);
        subset_mask = false(1, D_total);
        subset_mask(Indices_Sorted(1:k)) = true;
        
        % 评估当前 Top K 特征的精度
        accuracies(i) = f_eval(X, Y, subset_mask, params);
    end
    
    % 1.3 寻找膝点 (最大垂直距离法)
    % 曲线点：X 轴为特征数量比例 (k/D)，Y 轴为精度 (Acc)
    X_curve = k_values / D_total;
    Y_curve = accuracies;
    
    % 定义基准线 L：连接 (X_curve(1), Y_curve(1)) 到 (X_curve(end), Y_curve(end))
    % 假设直线方程： Ax + By + C = 0
    % 设 P1 = (X_curve(1), Y_curve(1)), P2 = (X_curve(end), Y_curve(end))
    A = Y_curve(end) - Y_curve(1);
    B = X_curve(1) - X_curve(end);
    C = X_curve(end) * Y_curve(1) - X_curve(1) * Y_curve(end);
    
    % 计算每个点到直线 L 的垂直距离 d = |Ax + By + C| / sqrt(A^2 + B^2)
    distances = abs(A * X_curve + B * Y_curve + C) / sqrt(A^2 + B^2);
    
    % 找到距离最大的点 (膝点)
    [~, knee_index] = max(distances);
    
    % 确定 K1
    K1 = k_values(knee_index);
    K1 = max(1, K1); % 确保 K1 至少为 1
    
    disp(['  > 膝点法确定初始特征数量 K1 = ', num2str(K1)]);

    % --- 2. 概率抽样生成初始种群 ---
    
    % 2.1 计算选择概率
    % 权重 W 已经归一化到 [0, 1]，可直接作为选择概率
    P_select = W;
    
    % 2.2 生成种群
    initial_population(PopSize) = Individual(); % 预分配 Individual 对象数组
    all_selected_indices = []; % 用于计算 initial_domain
    
    for i = 1:PopSize
        % 初始化个体的特征子集 (逻辑掩码)
        subset_mask = false(1, D_total);
        selected_count = 0; % 实际选择的特征数量
        
        % 根据概率 P_select 对每个特征进行伯努利抽样
        for j = 1:D_total
            if rand() < P_select(j)
                subset_mask(j) = true;
                selected_count = selected_count + 1;
            end
        end
        
        % 确保抽样结果至少有 K1/2 个特征 (防止过度稀疏)
        if selected_count < max(1, round(K1/2))
            % 如果太少，强制加入 Top K1/2 的特征
            top_half_k1 = max(1, round(K1/2));
            subset_mask(Indices_Sorted(1:top_half_k1)) = true;
        end
        
        % 2.3 创建个体并评估
        new_individual = Individual(subset_mask, task_id);
        
        % 注意：此处不立即计算适应度，而是将评估工作交给 main 函数统一处理，
        % 以便在 Task 2/3 的第一次迭代中进行评估。
        
        initial_population(i) = new_individual;
        
        % 记录所有被选中的特征索引，用于确定初始知识库的领域
        all_selected_indices = [all_selected_indices, find(subset_mask)]; %#ok<AGROW>
    end
    
    % 3. 确定初始知识库的特征领域 (并集)
    initial_domain = unique(all_selected_indices);

end