% OptimizationEngines/CSO_Optimizer.m

function [Population, ParetoFront] = CSO_Optimizer(Population, KnowledgeBase, X, Y, params, fitness_funcs, Generation)
% CSO_OPTIMIZER 实现了主任务 (任务一) 的 CSO 竞争群多目标优化。
%
% 输入:
%   Population: [Individual array] 种群数组 (包含 Position/Velocity)。
%   KnowledgeBase: [KnowledgeBase handle] 共享知识库实例。
%   X, Y: [matrix/vector] 数据和标签。
%   params: [struct] 配置参数。
%   fitness_funcs: [struct] 适应度函数句柄。
%   Generation: [int] 当前迭代代数 (用于迁移判断)。
%
% 输出:
%   Population: 更新了位置和速度的种群。
%   ParetoFront: 包含非支配解的 Individual 数组。

    D_total = size(X, 2);
    PopSize = length(Population);
    
    % --- 配置参数 ---
    P_TRANS = params.Knowledge.T_Transfer; % 知识迁移概率 (或周期性判断)
    R_V = 0.5; % 额外速度校正的随机因子 (对应公式 (4) 中的 r4)

    % --- 1. 双目标评估和解码 (P -> S) ---
    ObjectiveMatrix = zeros(PopSize, 2); % 目标矩阵: [Acc, Compression]
    
    for i = 1:PopSize
        % 解码：将实数位置 P 映射到二元子集 S (使用 Sigmoid 或简单二值化)
        % 简化的二值化 (阈值 0.5)
        P = Population(i).Position;
        S_mask = P > 0.5; 
        
        % 计算两个目标值
        Acc = evaluateSubset(X, Y, S_mask);
        Compression = 1 - (sum(S_mask) / D_total);

        % 更新个体属性
        Population(i).FeaturesSubset = S_mask;
        Population(i).Accuracy = Acc;
        Population(i).FeatureCount = sum(S_mask);
        Population(i).DuoObjective = [Acc, Compression];
        ObjectiveMatrix(i, :) = [Acc, Compression];
    end
    
    % --- 2. 非支配排序和拥挤距离计算 ---
    Population = NonDominatedSort(Population, ObjectiveMatrix);
    
    % --- 3. 配对竞争并生成 Winner/Loser 索引 ---
    
    % 随机打乱种群配对
    P_indices = randperm(PopSize); 
    Winner_indices = zeros(PopSize/2, 1);
    Loser_indices = zeros(PopSize/2, 1);
    
    for k = 1:PopSize/2
        P1_idx = P_indices(2*k - 1);
        P2_idx = P_indices(2*k);
        
        % 调用双目标竞争函数 (基于 Rank 和 Distance)
        [W_idx, L_idx] = Compare_DuoObjective(P1_idx, P2_idx, Population, [], []); % Fronts/CD已存储在Population中，无需再次传入
        
        Winner_indices(k) = W_idx;
        Loser_indices(k) = L_idx;
    end
    
    % --- 4. 学习更新 (速度/位置更新) ---
    for k = 1:length(Loser_indices)
        L_idx = Loser_indices(k);
        W_idx = Winner_indices(k);
        
        L = Population(L_idx);
        W = Population(W_idx);
        
        r1 = rand(); r2 = rand(); r3 = rand(); r4 = rand(); 

        % 4.1 知识迁移判断 (简化：基于概率 P_TRANS)
        if rand() < P_TRANS
            % Step 4: 知识迁移更新 (向 Winner 和 Knowledge Vector 学习)
            
            % 获取知识库推荐向量 KB_V (作为推荐位置 P_KB)
            P_KB = GenerateKnowledgeVector(KnowledgeBase, params, D_total); 

            % 速度更新: V_L = r1*V_L + r2*(P_W - P_L) + r3*(P_KB - P_L)
            new_V = r1 * L.Velocity + r2 * (W.Position - L.Position) + r3 * (P_KB - L.Position);

        else
            % Step 6: CSO 标准更新 (向 Winner W 和 随机 Winner W2 学习)
            
            % 随机选择一个不同的 Winner W2 (排除 W)
            WinnerPool = Winner_indices(Winner_indices ~= W_idx);
            if isempty(WinnerPool)
                W2_idx = W_idx; % 如果只有一个 Winner，就用自己
            else
                W2_idx = WinnerPool(randi(length(WinnerPool)));
            end
            W2 = Population(W2_idx);

            % 速度更新: V_L = r1*V_L + r2*(P_W - P_L) + r3*(P_W2 - P_L)
            new_V = r1 * L.Velocity + r2 * (W.Position - L.Position) + r3 * (W2.Position - L.Position);

        end
        
        % 4.2 位置更新 (基于公式(4)的变体)
        % P_new = P_L + new_V + r4*(new_V - V_L)
        new_P = L.Position + new_V + r4 * (new_V - L.Velocity);
        
        % 4.3 约束和更新
        L.Velocity = new_V;
        L.Position = max(0, min(1, new_P)); % 边界钳位 (Position 限制在 [0, 1])
        Population(L_idx) = L; % 赋值回数组 (如果 Individual 不是 handle 类，此处必须赋值)
    end
    
    % --- 5. 提取帕累托前沿 F1 ---
    ParetoFront = Population([Population.ParetoFrontRank] == 1);
    
end