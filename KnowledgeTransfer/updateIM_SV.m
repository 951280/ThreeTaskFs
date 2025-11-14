% KnowledgeTransfer/updateIM_SV.m

function KB = updateIM_SV(KB, Elite2, Elite3, params)
% UPDATEIM_SV 根据任务二和任务三的最佳个体竞争结果，更新共享的 IM 和 SV 知识库。
%
% 优化说明: 针对高维特征集，本函数采用“稀疏增量更新”策略：
% 仅对 Winner 或 Loser 选中的“活跃特征” (Active Features) 更新 SV 向量和 IM 矩阵，
% 避免遍历整个特征域，从而显著提升运算速度。

    % 0. 配置学习参数
    Delta = params.LearningRate.ChangeFactor;
    Init_Value = params.Knowledge.IM_SV_InitValue;
    
    % --- 1. 确定 Winner 和 Loser (保持原逻辑) ---
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
    
    % --- 2. 准备域内逻辑向量 ---
    Indices_Domain = KB.FeatureDomainIndices;
    D_domain = KB.DomainSize;
    
    % Winner 和 Loser 的全局特征子集
    S_winner_global = Winner.FeaturesSubset; 
    S_loser_global = Loser.FeaturesSubset;
    
    % 映射到当前知识库域 (长度为 D_domain 的 0/1 向量)
    S_winner_vec = double(S_winner_global(Indices_Domain));
    S_loser_vec = double(S_loser_global(Indices_Domain));

    % ====================================================================
    % 优化核心：识别活跃特征 (Active Features) 并进行稀疏更新
    % ====================================================================
    
    % 找到 Winner 或 Loser 中被选中的特征位置 (逻辑 OR)
    % 只有这些位置的 SV 和 IM 才需要更新，其他位置 (0 vs 0) 保持不变
    active_mask = S_winner_vec | S_loser_vec;
    active_indices = find(active_mask); 
    N_active = length(active_indices);
    
    fprintf('  > KB更新: 知识域大小 D=%d, 活跃特征数 N_active=%d. (IM更新将提速)\n', D_domain, N_active);
    
    % --- 3. 稀疏更新 SV 向量 (单特征显著性学习) ---
    % 仅遍历活跃特征的索引
    update_count_sv = 0;

    for k = 1:N_active
        i = active_indices(k); % 当前知识域的特征索引
        
        SV_i = KB.SV(i);
        W_i = S_winner_vec(i);
        L_i = S_loser_vec(i);
        
        SV_new = SV_i; % 默认值
        
        if W_i == 1 && L_i == 0
            % 增强：只在 Winner 中
            SV_new = SV_i + Delta;
            update_count_sv = update_count_sv + 1;
        elseif W_i == 0 && L_i == 1
            % 削弱：只在 Loser 中 (应用非负约束)
            SV_new = max(SV_i - Delta, Init_Value);
            update_count_sv = update_count_sv + 1;
        end
        
        % 仅当 SV 改变时才写入
        if SV_new ~= SV_i
            KB.SV(i) = SV_new;
        end
    end
    
    fprintf('  > SV向量更新完成。更新数量: %d/%d 个特征。\n', update_count_sv, D_domain);

    % --- 4. 稀疏更新 IM 矩阵 (特征协同性学习) ---
    IM_matrix = KB.IM; % 获取矩阵副本进行操作
    update_count_im = 0;
    
    % 只对活跃特征的索引对 (i, j) 进行遍历
    for k = 1:N_active
        i = active_indices(k);
        W_i = S_winner_vec(i); 
        L_i = S_loser_vec(i);
        
        % 只遍历上三角部分 (从 k 开始)
        for m = k:N_active
            j = active_indices(m);
            
            if i == j
                continue; % 对角线由 SV 处理，跳过
            end
            
            W_j = S_winner_vec(j);
            L_j = S_loser_vec(j);
            
            IM_ij = IM_matrix(i, j);
            IM_new = IM_ij; % 默认不变
            
            % --- 增强 (Winner 同时选择) ---
            if W_i == 1 && W_j == 1
                if L_i == 1 && L_j == 1 % 状态 1: W/L 都选 -> 增强
                    IM_new = IM_ij + Delta;
                elseif (L_i == 0 && L_j == 1) || (L_i == 1 && L_j == 0) % 状态 2/3: W 选，L 选一个 -> 强烈增强
                    IM_new = IM_ij + 2*Delta;
                elseif L_i == 0 && L_j == 0 % 状态 4: W 选，L 都不选 -> 增强
                    IM_new = IM_ij + Delta;
                end
            % --- 削弱 (Loser 同时选择) ---
            elseif L_i == 1 && L_j == 1
                if W_i == 0 && W_j == 0 % 状态 5: L 选，W 都不选 -> 削弱
                    IM_new = max(IM_ij - Delta, Init_Value);
                elseif (W_i == 0 && W_j == 1) || (W_i == 1 && W_j == 0) % 状态 6/7: L 选，W 选一个 -> 强烈削弱
                    IM_new = max(IM_ij - 2*Delta, Init_Value);
                end
            end
            
            % 仅当数值改变时才写入矩阵 (减少稀疏矩阵的写入开销并计数)
            if IM_new ~= IM_ij
                IM_matrix(i, j) = IM_new;
                IM_matrix(j, i) = IM_new; % 确保对称性
                update_count_im = update_count_im + 1;
            end
        end
    end
    
    % 将更新后的稀疏矩阵赋值回 KnowledgeBase 对象
    KB.IM = IM_matrix;
    
    fprintf('  > IM矩阵稀疏更新完成。更新数量: %d 对特征。\n', update_count_im);
    disp('  > 知识库 IM/SV 已根据辅助任务的竞争结果更新。');
end