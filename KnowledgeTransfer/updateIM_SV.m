% KnowledgeTransfer/updateIM_SV.m

function KB = updateIM_SV(KB, Elite2, Elite3, params)
% UPDATEIM_SV 根据任务二和任务三的最佳个体竞争结果，更新共享的 IM 和 SV 知识库。
%
% 输入:
%   KB: [KnowledgeBase handle] 共享 IM/SV 知识库实例 (会被修改)。
%   Elite2: [Individual] 任务二最佳个体。
%   Elite3: [Individual] 任务三最佳个体。
%   params: [struct] 配置参数 (ChangeFactor, IM_SV_InitValue)。
%
% 输出:
%   KB: 更新后的 KnowledgeBase 实例。

    % 0. 配置学习参数 (假设 ChangeFactor 已在 config_parameters.m 中定义)
    Delta = params.LearningRate.ChangeFactor;
    Init_Value = params.Knowledge.IM_SV_InitValue;
    
    % --- 1. 确定 Winner 和 Loser ---
    % 竞争标准：Fitness 优先，平局则 FeatureCount 少者胜。
    if Elite2.Fitness > Elite3.Fitness
        Winner = Elite2;
        Loser = Elite3;
    elseif Elite3.Fitness > Elite2.Fitness
        Winner = Elite3;
        Loser = Elite2;
    else % 适应度相同，使用特征数量少者胜
        if Elite3.FeatureCount < Elite2.FeatureCount
            Winner = Elite3;
            Loser = Elite2;
        else
            Winner = Elite2;
            Loser = Elite3;
        end
    end
    
    % --- 2. 准备域内逻辑向量 (S_domain) ---
    Indices_Domain = KB.FeatureDomainIndices;
    D_domain = KB.DomainSize;
    
    % Winner 和 Loser 的全局特征子集 (假设是逻辑向量)
    S_winner_global = Winner.FeaturesSubset; 
    S_loser_global = Loser.FeaturesSubset;
    
    % 映射到当前知识库域 (长度为 D_domain 的 0/1 向量)
    % S_domain(i) = 1/0 表示域内第 i 个特征是否被选中
    S_winner_vec = double(S_winner_global(Indices_Domain));
    S_loser_vec = double(S_loser_global(Indices_Domain));
    
    % --- 3. 更新 SV 向量 (单特征显著性学习) ---
    for i = 1:D_domain
        SV_i = KB.SV(i);
        W_i = S_winner_vec(i);
        L_i = S_loser_vec(i);
        
        if W_i == 1 && L_i == 0
            % 增强：只在 Winner 中
            KB.SV(i) = SV_i + Delta;
        elseif W_i == 0 && L_i == 1
            % 削弱：只在 Loser 中 (应用非负约束)
            KB.SV(i) = max(SV_i - Delta, Init_Value);
        end
        % W_i == L_i 的情况保持不变
    end
    
    % --- 4. 更新 IM 矩阵 (特征协同性学习) ---
    IM_matrix = KB.IM; % 获取矩阵副本进行操作
    
    for i = 1:D_domain
        for j = i:D_domain % 只遍历上三角 (包括对角线)
            if i == j
                continue; % 对角线由 SV 处理，跳过
            end
            
            IM_ij = IM_matrix(i, j);
            W_i = S_winner_vec(i); W_j = S_winner_vec(j);
            L_i = S_loser_vec(i); L_j = S_loser_vec(j);
            
            IM_new = IM_ij; % 默认不变
            
            % --- 增强 (Winner 同时选择) ---
            if W_i == 1 && W_j == 1
                if L_i == 1 && L_j == 1 % 状态 1: W/L 都选
                    IM_new = IM_ij + Delta;
                elseif (L_i == 0 && L_j == 1) || (L_i == 1 && L_j == 0) % 状态 2/3: W 选，L 选一个
                    IM_new = IM_ij + 2*Delta;
                elseif L_i == 0 && L_j == 0 % 状态 4: W 选，L 都不选
                    IM_new = IM_ij + Delta;
                end
            % --- 削弱 (Loser 同时选择) ---
            elseif L_i == 1 && L_j == 1
                if W_i == 0 && W_j == 0 % 状态 5: L 选，W 都不选
                    IM_new = max(IM_ij - Delta, Init_Value);
                elseif (W_i == 0 && W_j == 1) || (W_i == 1 && W_j == 0) % 状态 6/7: L 选，W 选一个
                    IM_new = max(IM_ij - 2*Delta, Init_Value);
                end
            end
            
            % 更新矩阵 (i, j) 和 (j, i) 确保对称性
            IM_matrix(i, j) = IM_new;
            IM_matrix(j, i) = IM_new;
        end
    end
    
    % 将更新后的矩阵赋值回 KnowledgeBase 对象
    KB.IM = IM_matrix;
    
    disp('  > 知识库 IM/SV 已根据辅助任务的竞争结果更新。');
end