% FitnessAndEval/f1_fitness.m

function fit1 = f1_fitness(Acc, S_count, N_total, alpha)
% F1_FITNESS 计算任务一（主任务）的单目标适应度。
% 目标是平衡分类精度和特征数量。
%
% 公式: f1(S) = alpha * Acc(S) + (1 - alpha) * (1 - |S|/N)
% Acc(S): 分类准确率
% |S|: 选中的特征数量 (S_count)
% N: 总特征数量 (N_total)
% alpha: 平衡因子 (从 config_parameters.m 获取)

    % 1. 计算特征压缩率（特征数量惩罚项）
    % (1 - |S|/N) 代表了特征压缩比越高，该值越大
    if N_total == 0
        R_compression = 0; % 避免除以零
    else
        R_compression = 1 - (S_count / N_total);
    end
    
    % 2. 应用加权公式
    fit1 = alpha * Acc + (1 - alpha) * R_compression;
    
    % 注意：在 CSO 算法中，f1 主要是用于种群内部比较，
    % 帕累托前沿的维护是基于 Acc 和 R_compression 的双目标。

end