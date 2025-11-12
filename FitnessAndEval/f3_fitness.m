% FitnessAndEval/f3_fitness.m

function fit3 = f3_fitness(Acc, S_count, N_total, theta_acc)
% F3_FITNESS 计算任务三（辅助任务 2）的适应度。
% 目标是偏重特征紧凑性（数量），但必须满足最低精度阈值。
%
% 公式: 
%       f3(S) = (1 - |S|/N)                , if Acc(S) >= theta_acc
%       f3(S) = Acc(S) * (1 - |S|/N)     , otherwise
% Acc(S): 分类准确率
% |S|: 选中的特征数量 (S_count)
% N: 总特征数量 (N_total)
% theta_acc: 最低可接受精度阈值 (从 config_parameters.m 获取)

    % 1. 计算特征压缩率 (1 - |S|/N)
    if N_total == 0
        R_compression = 0; % 避免除以零
    else
        R_compression = 1 - (S_count / N_total);
    end

    % 2. 应用条件逻辑
    if Acc >= theta_acc
        % 条件满足：只优化特征数量，适应度等于压缩率
        fit3 = R_compression;
    else
        % 条件不满足：同时惩罚未达标的精度，以精度作为权重
        fit3 = Acc * R_compression;
    end

end