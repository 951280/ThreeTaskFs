% FeatureProcessing/getReliefFImportance.m

function importance_norm = getReliefFImportance(X, Y)
% GETRELIEFFIMPORTANCE 计算基于 Relief-F 算法的特征重要性分数。
% 该分数作为 Task 3 的预处理特征。
%
% 输入:
%   X: [N x D double] 特征矩阵。
%   Y: [N x 1 categorical/double] 标签向量。
%
% 输出:
%   importance_norm: [D x 1 double] 归一化后的特征重要性向量。

    % 1. 配置 Relief-F 参数
    % K_NEIGHBORS: 邻居数量 K。Relief-F 默认使用 10。
    K_NEIGHBORS = 10;
    
    % 2. 计算 Relief-F 分数
    % MATLAB 的 relieff 函数返回每个特征的权重，权重越大，特征越重要。
    % 负权重表示该特征与类别标签负相关。
    try
        [raw_importance, ~] = relieff(X, Y, K_NEIGHBORS);
    catch ME
        error('getReliefFImportance:ReliefFError', '执行 relieff 函数时出错: %s', ME.message);
    end
    
    % 3. 归一化特征重要性
    % Relief-F 的分数是有正负的，归一化通常需要平移到非负区间 [0, 1]。
    
    % a. 平移：将所有分数平移到非负，min_imp 变为 0
    min_imp = min(raw_importance);
    shifted_importance = raw_importance - min_imp;
    
    % b. 缩放：将最大值缩放到 1
    max_shifted = max(shifted_importance);
    
    if max_shifted == 0
        % 所有特征重要性相同 (可能都为 0 或都为相同的负数)，归一化为均匀分布
        importance_norm = ones(size(raw_importance)) / size(X, 2);
    else
        % 归一化到 [0, 1]
        importance_norm = shifted_importance / max_shifted;
    end
    
    % 确保是列向量输出
    importance_norm = importance_norm(:);

end