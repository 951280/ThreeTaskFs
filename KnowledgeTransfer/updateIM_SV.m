function KB = updateIM_SV(KB, Elite2, Elite3, params)
% UPDATEIM_SV 根据任务二/三的竞争结果更新知识库
% 优化版：增加了高维数据保护阈值，防止在 Leukemia 等超高维数据集上卡死

    % 0. 配置参数
    Delta = params.LearningRate.ChangeFactor;
    Init_Value = params.Knowledge.IM_SV_InitValue;
    
    % --- 1. 确定 Winner 和 Loser ---
    if Elite2.Fitness > Elite3.Fitness
        Winner = Elite2; Loser = Elite3;
    elseif Elite3.Fitness > Elite2.Fitness
        Winner = Elite3; Loser = Elite2;
    else
        if Elite3.FeatureCount < Elite2.FeatureCount
            Winner = Elite3; Loser = Elite2;
        else
            Winner = Elite2; Loser = Elite3;
        end
    end
    
    % --- 2. 准备数据 ---
    Indices_Domain = KB.FeatureDomainIndices;
    D_domain = KB.DomainSize;
    
    S_winner_global = Winner.FeaturesSubset;
    S_loser_global = Loser.FeaturesSubset;
    
    % 映射到当前知识域
    S_winner_vec = double(S_winner_global(Indices_Domain));
    S_loser_vec = double(S_loser_global(Indices_Domain));
    
    % 识别活跃特征
    active_mask = S_winner_vec | S_loser_vec;
    active_indices = find(active_mask);
    N_active = length(active_indices);
    
    fprintf('  > KB更新: 域大小 D=%d, 活跃特征数 N_active=%d.\n', D_domain, N_active);
    
    % --- 3. 更新 SV 向量 (线性复杂度，很快) ---
    update_count_sv = 0;
    for k = 1:N_active
        i = active_indices(k);
        SV_i = KB.SV(i);
        W_i = S_winner_vec(i);
        L_i = S_loser_vec(i);
        
        SV_new = SV_i;
        if W_i == 1 && L_i == 0
            SV_new = SV_i + Delta;
            update_count_sv = update_count_sv + 1;
        elseif W_i == 0 && L_i == 1
            SV_new = max(SV_i - Delta, Init_Value);
            update_count_sv = update_count_sv + 1;
        end
        if SV_new ~= SV_i, KB.SV(i) = SV_new; end
    end
    fprintf('  > SV向量更新完成。更新: %d/%d.\n', update_count_sv, D_domain);
    
    % --- 4. 更新 IM 矩阵 (平方复杂度，需要保护) ---
    
    % ★★★ 高维保护阈值 ★★★
    % 如果活跃特征超过 800 个，两两组合将超过 32万对，极慢且初期无意义。
    % 此时跳过 IM 更新，等待特征筛选变少后再启用。
    IM_UPDATE_THRESHOLD = 800; 
    
    if N_active > IM_UPDATE_THRESHOLD
        fprintf('  > [跳过] 活跃特征过多 (%d > %d)，跳过 IM 更新以加速计算。\n', N_active, IM_UPDATE_THRESHOLD);
        return; % 直接返回，不跑下面的循环
    end
    
    IM_matrix = KB.IM; 
    update_count_im = 0;
    
    for k = 1:N_active
        i = active_indices(k);
        W_i = S_winner_vec(i);
        L_i = S_loser_vec(i);
        
        for m = k:N_active
            j = active_indices(m);
            if i == j, continue; end
            
            W_j = S_winner_vec(j);
            L_j = S_loser_vec(j);
            
            IM_ij = IM_matrix(i, j);
            IM_new = IM_ij;
            
            % 增强逻辑
            if W_i && W_j
                if L_i && L_j
                    IM_new = IM_ij + Delta;
                elseif (L_i && ~L_j) || (~L_i && L_j)
                    IM_new = IM_ij + 2*Delta;
                elseif ~L_i && ~L_j
                    IM_new = IM_ij + Delta;
                end
            % 削弱逻辑
            elseif L_i && L_j
                if ~W_i && ~W_j
                    IM_new = max(IM_ij - Delta, Init_Value);
                elseif (W_i && ~W_j) || (~W_i && W_j)
                    IM_new = max(IM_ij - 2*Delta, Init_Value);
                end
            end
            
            if IM_new ~= IM_ij
                IM_matrix(i, j) = IM_new;
                IM_matrix(j, i) = IM_new;
                update_count_im = update_count_im + 1;
            end
        end
    end
    
    KB.IM = IM_matrix;
    fprintf('  > IM矩阵更新完成。更新: %d 对特征。\n', update_count_im);
end