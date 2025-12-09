% FitnessAndEval/evaluateSubset.m
function accuracy = evaluateSubset(X, Y, subset_mask, params)
% EVALUATESUBSET 使用特征子集对数据进行 K-折交叉验证，并返回平均分类准确率。
% 更新：增加了对小样本/不平衡类别的自动降级处理 (Stratified -> Random)

    % 1. 配置参数
    K_FOLD = params.Evaluation.KFold;
    NUM_NEIGHBORS = params.Evaluation.KNN_K;
    
    % 2. 数据准备
    % 提取选中的特征子集
    X_subset = X(:, subset_mask);
    
    % 检查是否有选中的特征
    if isempty(X_subset)
        accuracy = 0.0;
        return;
    end
    
    N = size(X, 1);
    
    % =================================================================
    % ★★★ 核心修复：智能分区策略 ★★★
    % 解决 Gait 等小样本数据集无法进行分层抽样(Stratified)的问题
    % =================================================================
    try
        % 1. 检查最小类别样本数
        % countcats 统计每个类别的数量
        min_class_count = min(countcats(Y));
        
        if min_class_count < K_FOLD
            % 如果某个类别的样本数少于 K，无法分层，强制使用普通随机抽样
            % 使用 N (总数) 作为参数，而不是 Y (标签)
            cv = cvpartition(N, 'KFold', K_FOLD);
        else
            % 样本充足，使用分层抽样 (Stratified) - 推荐
            cv = cvpartition(Y, 'KFold', K_FOLD);
        end
        
    catch 
        % 万一还是报错，兜底使用随机抽样
        cv = cvpartition(N, 'KFold', K_FOLD);
    end
    % =================================================================

    % 4. 执行 K-折交叉验证
    fold_accuracies = zeros(K_FOLD, 1);
    
    for i = 1:K_FOLD
        train_indices = training(cv, i);
        test_indices = test(cv, i);
        
        X_train = X_subset(train_indices, :);
        Y_train = Y(train_indices);
        
        X_test = X_subset(test_indices, :);
        Y_test = Y(test_indices);
        
        % --- 训练分类器 (KNN) ---
        % 针对小样本，KNN 依然是最稳健的选择
        try
            model = fitcknn(X_train, Y_train, 'NumNeighbors', NUM_NEIGHBORS);
            Y_pred = predict(model, X_test);
            
            % 计算准确率
            fold_accuracies(i) = sum(Y_pred == Y_test) / length(Y_test);
        catch
            % 极少数情况下如果某一折训练集只有一个类别，fitcknn可能会警告
            fold_accuracies(i) = 0; 
        end
    end
    
    % 5. 返回平均准确率
    accuracy = mean(fold_accuracies);
    
end