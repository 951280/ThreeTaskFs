% FitnessAndEval/evaluateSubset.m

function accuracy = evaluateSubset(X, Y, subset_mask, params)
% EVALUATESUBSET 使用特征子集对数据进行 K-折交叉验证，并返回平均分类准确率。
%
% 1. 签名中添加 params 输入，以从配置文件中读取 KFold 和 KNN_K。
% 2. 引入 CLASSIFIER_TYPE 开关，临时切换为 Naive Bayes (NB) 以加速调试。
%
% 输入:
%   X: [N x D double] 全体特征矩阵。
%   Y: [N x 1 categorical/double] 标签向量。
%   subset_mask: [1 x D logical] 特征子集的逻辑掩码。
%   params: [struct] 配置参数结构体。
%
% 输出:
%   accuracy: [double] 平均分类准确率。

    % 1. 配置参数 (从 params 读取)
    K_FOLD = params.Evaluation.KFold;            % K-折交叉验证的 K (来自 config_parameters.m)
    NUM_NEIGHBORS = params.Evaluation.KNN_K;      % K-近邻的 K 值 (来自 config_parameters.m)
    
    % --- 调试/提速开关 ---
   % CLASSIFIER_TYPE = 'NB'; % <--- 临时设置为 'NB' (朴素贝叶斯)，大幅提速
     CLASSIFIER_TYPE = 'KNN'; % 最终实验时恢复为 'KNN' (K-近邻)
    %CLASSIFIER_TYPE = 'LR'; % <--- 最终调试提速：切换到 Logistic Regression
    
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
        
        % --- 训练分类器 (根据开关选择) ---
        if strcmp(CLASSIFIER_TYPE, 'KNN')
            % K-近邻分类器 (原评估器，耗时高)
            model = fitcknn(X_train, Y_train, 'NumNeighbors', NUM_NEIGHBORS);
        elseif strcmp(CLASSIFIER_TYPE, 'NB')
            % 朴素贝叶斯分类器 (fitcnb)，速度远超 KNN，用于调试提速
            %使用 'kernel' 分布替代默认的 'normal'
            model = fitcnb(X_train, Y_train, 'DistributionNames', 'kernel'); 
        elseif strcmp(CLASSIFIER_TYPE, 'LR')
             % 训练速度极快，适合作为进化算法的适应度评估器
             model = fitclinear(X_train, Y_train, 'Learner', 'logistic');
        else
            error('EvaluateSubset:ClassifierError', '配置的分类器类型无效，请检查代码。');
        end
        
        % 预测测试集标签
        Y_pred = predict(model, X_test);
        
        % 计算当前折的准确率
        fold_accuracies(i) = sum(Y_pred == Y_test) / length(Y_test);
    end
    
    % 5. 返回平均准确率
    accuracy = mean(fold_accuracies);

end