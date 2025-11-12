% FeatureProcessing/getLGBMImportance.m

function importance_norm = getLGBMImportance(X, Y)
% GETLGBMIMPORTANCE 计算基于集成学习模型（Bagging 决策树）的特征重要性。
% 该方法用于近似 LightGBM 的特征重要性输出，作为 Task 2 的预处理特征。
%
% 输入:
%   X: [N x D double] 特征矩阵。
%   Y: [N x 1 categorical/double] 标签向量。
%
% 输出:
%   importance_norm: [D x 1 double] 归一化后的特征重要性向量。

    % 1. 配置模型参数
    NUM_TREES = 100;    % Bagging 集成中树的数量
    
    % 2. 训练集成模型
    try
        % 使用 Bagging 方法训练分类集成模型 (fitcensemble)
        % 'Method','Bag' (Bagging) 是一种常用的并行集成方法
        % 'Learners','Tree' 指定基础分类器为决策树
        Mdl = fitcensemble(X, Y, 'Method', 'Bag', 'NumLearningCycles', NUM_TREES, ...
                           'Learners', 'Tree', 'NPrint', 0);
                       
    catch ME
        error('getLGBMImportance:TrainingError', '训练集成模型时出错: %s', ME.message);
    end
    
    % 3. 提取特征重要性
    % MATLAB 的 fitcensemble 对象没有直接的 featureImportance 方法。
    % 对于 Bagged Trees，我们通过计算每个特征在所有树中的预测能力（例如 Gini Diversity Index 变化）来衡量。
    
    % 提取方法: 使用 MATLAB 的内置函数 'predictorImportance'
    % 对于树集成，该函数返回特征在所有树中分裂时对模型性能的平均贡献。
    raw_importance = predictorImportance(Mdl);
    
    % 检查重要性向量是否为空
    if isempty(raw_importance)
        warning('getLGBMImportance:EmptyImportance', '未能成功提取特征重要性，返回零向量。');
        importance_norm = zeros(size(X, 2), 1);
        return;
    end
    
    % 4. 归一化特征重要性
    % 将重要性分数归一化到 [0, 1] 范围
    max_imp = max(raw_importance);
    min_imp = min(raw_importance);
    
    if max_imp == min_imp
        % 所有特征重要性相同，归一化为均匀分布
        importance_norm = ones(size(raw_importance)) / size(X, 2);
    else
        % 归一化公式: (Value - Min) / (Max - Min)
        importance_norm = (raw_importance - min_imp) / (max_imp - min_imp);
    end
    
    % 确保是列向量输出，方便后续处理
    importance_norm = importance_norm(:);

end