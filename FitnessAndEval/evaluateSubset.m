% FitnessAndEval/evaluateSubset.m

function accuracy = evaluateSubset(X, Y, subset_mask)
% EVALUATESUBSET 使用特征子集对数据进行 K-折交叉验证，并返回平均分类准确率。
% 
% 输入:
%   X: [N x D double] 全体特征矩阵 (N 个样本, D 个特征)。
%   Y: [N x 1 categorical/double] 标签向量。
%   subset_mask: [1 x D logical] 特征子集的逻辑掩码 (true 表示选中)。
%
% 输出:
%   accuracy: [double] 5-折交叉验证的平均分类准确率。

    % 1. 配置参数
    K_FOLD = 5; % 采用 5-折交叉验证
    
    % MATLAB Statistics and Machine Learning Toolbox: K-近邻分类器参数
    NUM_NEIGHBORS = 5; % K-近邻的 K 值，默认为 5
    
    % 2. 数据准备
    % 提取选中的特征子集数据
    X_subset = X(:, subset_mask);
    
    % 检查是否有选中的特征，如果没有则返回 0 准确率，避免错误
    if isempty(X_subset)
        accuracy = 0.0;
        warning('EvaluateSubset:EmptySubset', '特征子集为空，准确率返回 0。');
        return;
    end

    N = size(X, 1); % 样本数量
    
    % 3. 设置交叉验证分区
    % 使用 cvpartition 函数创建 K-折交叉验证分区
    % 确保每个折中的类别分布尽可能均衡 (Stratified)
    try
        cv = cvpartition(Y, 'KFold', K_FOLD);
    catch ME
        % 捕捉错误，例如当类别太少无法分层时
        warning('EvaluateSubset:CVPartition', '无法进行分层交叉验证: %s。尝试非分层。', ME.message);
        cv = cvpartition(N, 'KFold', K_FOLD);
    end
    
    % 4. 执行 K-折交叉验证
    fold_accuracies = zeros(K_FOLD, 1);
    
    for i = 1:K_FOLD
        % 获取当前折的训练和测试样本索引
        train_indices = training(cv, i);
        test_indices = test(cv, i);
        
        % 训练数据和标签
        X_train = X_subset(train_indices, :);
        Y_train = Y(train_indices);
        
        % 测试数据和标签
        X_test = X_subset(test_indices, :);
        Y_test = Y(test_indices);
        
        % 训练 K-近邻分类器
        % 使用 fitcknn 创建模型。如果内存允许，可以考虑使用 'Distance','Euclidean'。
        knn_model = fitcknn(X_train, Y_train, 'NumNeighbors', NUM_NEIGHBORS);
        
        % 预测测试集标签
        Y_pred = predict(knn_model, X_test);
        
        % 计算当前折的准确率
        fold_accuracies(i) = sum(Y_pred == Y_test) / length(Y_test);
    end
    
    % 5. 返回平均准确率
    accuracy = mean(fold_accuracies);

end