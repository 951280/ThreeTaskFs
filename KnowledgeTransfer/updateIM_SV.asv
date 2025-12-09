function KB = updateIM_SV(KB, Elite2, Elite3, params)
% UPDATEIM_SV 根据任务二/三的竞争结果更新知识库
% 优化版：采用【向量化外积】计算，彻底解决了高维数据集（如 Leukemia）卡死的问题。
% 移除了 800 维度的强制限制。

    % 0. 配置参数
    Delta = params.LearningRate.ChangeFactor;
    Init_Value = params.Knowledge.IM_SV_InitValue;
    
    % --- 1. 确定 Winner 和 Loser ---
    % 逻辑：优先比 Fitness，如果一样，比特征数量（Task3 倾向）
    if Elite2.Fitness > Elite3.Fitness
        Winner = Elite2; Loser = Elite3;
    elseif Elite3.Fitness > Elite2.Fitness
        Winner = Elite3; Loser = Elite2;
    else
        % 平局时，优先选特征少的作为 Winner
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
    
    % 识别活跃特征（只要有一方选中就算活跃）
    active_mask = S_winner_vec | S_loser_vec;
    active_indices = find(active_mask);
    N_active = length(active_indices);
    
    % 打印日志 (可选，调试用)
    % fprintf('  > KB更新: 域大小 D=%d, 活跃特征数 N_active=%d.\n', D_domain, N_active);
    
    % --- 3. 更新 SV 向量 (线性复杂度 O(N)，无需向量化也很快) ---
    update_count_sv = 0;
    for k = 1:N_active
        i = active_indices(k);
        SV_i = KB.SV(i);
        W_i = S_winner_vec(i);
        L_i = S_loser_vec(i);
        
        SV_new = SV_i;
        % 简单的差分学习逻辑
        if W_i == 1 && L_i == 0
            SV_new = SV_i + Delta;
            update_count_sv = update_count_sv + 1;
        elseif W_i == 0 && L_i == 1
            SV_new = max(SV_i - Delta, Init_Value); % 只有这里需要防越界
            update_count_sv = update_count_sv + 1;
        end
        
        if SV_new ~= SV_i
            KB.SV(i) = SV_new; 
        end
    end
    % fprintf('  > SV向量更新完成。更新: %d/%d.\n', update_count_sv, D_domain);
    
    % --- 4. 更新 IM 矩阵 (向量化版本，极大提升速度) ---
    
    % 如果没有活跃特征，直接跳过
    if N_active == 0
        return;
    end
    
    % 1. 提取活跃区域的 Winner/Loser 向量 (列向量)
    W_vec = S_winner_vec(active_indices); % Winner 的 0/1 向量
    L_vec = S_loser_vec(active_indices);  % Loser 的 0/1 向量
    n = length(active_indices);
    
    % 2. 构造基础逻辑矩阵 (利用外积)
    % 逻辑：乘积为1代表两者都为1 (逻辑与)
    WW = logical(W_vec * W_vec'); % Winner 同时选中的 pair (W_i && W_j)
    LL = logical(L_vec * L_vec'); % Loser 同时选中的 pair (L_i && L_j)
    
    % 构造 "混合" 状态 (一个选了一个没选) (XOR)
    % A_mixed(i,j) = 1 表示 (A_i=1, A_j=0) 或 (A_i=0, A_j=1)
    W_mixed = xor(W_vec, W_vec'); % 利用 xor 函数更简洁
    L_mixed = xor(L_vec, L_vec');
    
    % 构造 Winner 的 "全无" 状态 (~W_i && ~W_j)
    W_none = ~W_vec * ~W_vec';
    
    % 3. 计算增量矩阵 (Step Matrix)
    Step_Matrix = zeros(n, n);
    
    % === 增强逻辑 (Winner 认为好的) ===
    % 前提：Winner 必须同时选中 i 和 j
    mask_enhance = WW; 
    
    % a. Loser 同时也选中了 (说明这是共识，稍微加强) -> +Delta
    idx_boost1 = mask_enhance & LL;
    Step_Matrix(idx_boost1) = Delta;
    
    % b. Loser 只有一半选中 (说明 Loser 犹豫，Winner 坚定) -> +2*Delta (强加强)
    idx_boost2 = mask_enhance & L_mixed;
    Step_Matrix(idx_boost2) = 2 * Delta;
    
    % c. Loser 完全没选中 (Winner 独具慧眼) -> +Delta
    idx_boost3 = mask_enhance & (~LL & ~L_mixed); 
    Step_Matrix(idx_boost3) = Delta;
    
    % === 削弱逻辑 (Loser 认为好，但 Winner 没选) ===
    % 前提：Loser 同时选中，但 Winner 没有同时选中 (else 逻辑)
    % 注意：要排除掉 mask_enhance 的情况
    mask_weaken = LL & ~WW; 
    
    % a. Winner 完全没选 (说明这是垃圾特征对) -> -Delta
    idx_pen1 = mask_weaken & W_none;
    Step_Matrix(idx_pen1) = -Delta;
    
    % b. Winner 选了一半 (说明 Winner 觉得这对不行) -> -2*Delta (强削弱)
    idx_pen2 = mask_weaken & W_mixed;
    Step_Matrix(idx_pen2) = -2 * Delta;
    
    % 4. 消除对角线更新 (特征自己对自己不需要交互值)
    Step_Matrix(logical(eye(n))) = 0;
    
    % 5. 批量应用更新
    % 提取当前 IM 子矩阵 (转换为 dense 进行计算)
    Current_Sub_IM = full(KB.IM(active_indices, active_indices));
    
    % 计算新矩阵
    New_Sub_IM = Current_Sub_IM + Step_Matrix;
    
    % 6. 边界约束 (必须 >= Init_Value)
    % 只需要检查变小的部分，但全矩阵检查也很快
    New_Sub_IM = max(New_Sub_IM, Init_Value);
    
    % 7. 存回稀疏矩阵 KB.IM
    KB.IM(active_indices, active_indices) = New_Sub_IM;
    
    % 计算更新了多少对 (用于日志)
    update_count_im = nnz(Step_Matrix); 
    
    fprintf('  > IM更新完成(Vectorized)。活跃维: %d, 更新对数: %d\n', n, update_count_im);

end