% FitnessAndEval/f2_fitness.m

function fit2 = f2_fitness(Acc, S_count, N_total, lambda)
% F2_FITNESS 计算任务二（辅助任务 1）的适应度。
% 目标是偏重分类精度，同时对特征数量进行轻微惩罚。
%
% 公式: f2(S) = Acc(S) - lambda * (|S|/N)
% Acc(S): 分类准确率
% |S|: 选中的特征数量 (S_count)
% N: 总特征数量 (N_total)
% lambda: 特征数量惩罚项 (从 config_parameters.m 获取)

    % 1. 计算特征数量比例 (|S|/N)
    if N_total == 0
        R_feature = 0; % 避免除以零
    else
        R_feature = S_count / N_total;
    end
    
    % 2. 应用惩罚公式
    fit2 = Acc - lambda * R_feature;

end