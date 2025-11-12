% OptimizationEngines/EDA_Optimizer.m

function [NewPopulation, EliteIndividual] = EDA_Optimizer(Population, KnowledgeBase, X, Y, params, fitness_funcs, task_id)
% EDA_OPTIMIZER 实现了基于 IM/SV 知识引导的伯努利抽样进化算法 (EDA)。
% 用于任务二 (精度优化器) 和任务三 (紧凑性优化器)。
%
% 输入:
%   Population: [Individual array] 当前代种群。
%   KnowledgeBase: [KnowledgeBase object] 共享 IM/SV 知识库实例。
%   X, Y: [matrix/vector] 数据和标签。
%   params: [struct] 配置参数。
%   fitness_funcs: [struct] 包含 f1, f2, f3 函数句柄的结构体。
%   task_id: [int] 任务 ID (2 或 3)。
%
% 输出:
%   NewPopulation: [Individual array] 进化后的下一代种群。
%   EliteIndividual: [Individual object] 本代适应度最高的个体。

    D_total = size(X, 2);
    PopSize = length(Population);
    
    % --- 配置参数 ---
    P_Elite = max(2, round(PopSize * 0.1)); % 10% 精英集大小
    GAMMA = 0.7; % 融合权重：P_base 占 70%，P_prior (SV 引导) 占 30%
    INIT_PROB = 0.01; % 概率抽样 P_sample 的最小值限制

    % ----------------- 1 & 2: 确定精英集并计算基础概率 P_base -----------------
    
    % 根据单目标适应度排序 (降序)
    all_fitness = [Population.Fitness];
    [~, sorted_indices] = sort(all_fitness, 'descend');
    
    EliteSet = Population(sorted_indices(1:P_Elite));
    
    % 计算基础概率 P_base: 精英集中特征被选中的频率
    P_base = zeros(1, D_total);
    for i = 1:P_Elite
        % 假设 FeaturesSubset 是逻辑向量
        P_base(EliteSet(i).FeaturesSubset) = P_base(EliteSet(i).FeaturesSubset) + 1;
    end
    P_base = P_base / P_Elite;
    
    % ----------------- 3: 知识引导与融合 P_sample -----------------
    
    SV_domain = KnowledgeBase.SV;
    Indices_domain = KnowledgeBase.FeatureDomainIndices;
    Init_Value = params.Knowledge.IM_SV_InitValue;
    
    % 3.a 映射 SV_domain 到全长向量 SV_full
    SV_full = ones(1, D_total) * Init_Value; % 极小值填充
    
    % 映射域内有效值
    % 注意：MATLAB 索引操作比循环更快
    SV_full(Indices_domain) = SV_domain;
    
    % 3.b 归一化 SV_full 作为先验概率 P_prior
    min_sv = min(SV_full);
    max_sv = max(SV_full);
    
    if max_sv == min_sv
        P_prior = ones(1, D_total) * 0.5; % 均匀分布
    else
        % 归一化到 [0, 1] 区间
        P_prior = (SV_full - min_sv) / (max_sv - min_sv);
    end
    
    % 3.c 融合经验 P_base 和先验 P_prior
    P_sample = GAMMA * P_base + (1 - GAMMA) * P_prior;
    
    % 限制概率范围 [INIT_PROB, 1-INIT_PROB]
    P_sample = max(INIT_PROB, min(1 - INIT_PROB, P_sample));
    
    % ----------------- 4 & 5: 采样、评估和选择 -----------------
    
    NewSamples(PopSize) = Individual(); % 预分配数组
    
    for i = 1:PopSize
        % 4. 伯努利抽样生成新子集
        % MATLAB 的 rand(1, D) < P_sample 即可实现伯努利抽样
        new_subset_mask = rand(1, D_total) < P_sample;
        
        % 强制选中一个特征 (避免空集)
        if sum(new_subset_mask) == 0
            % 选中概率最高的特征
            [~, idx] = max(P_sample);
            new_subset_mask(idx) = true;
        end
        
        % 5. 创建并评估新个体
        new_individual = Individual(new_subset_mask, task_id);
        
        % 评估：调用 Individual 类中的 evaluate 方法
        % 需要传入 X, Y 和适应度函数
        new_individual = new_individual.evaluate(X, Y, fitness_funcs); 
        
        NewSamples(i) = new_individual;
    end
    
    % 精英保留策略：合并旧种群和新采样，选择最好的 PopSize 个体
    CombinedPop = [Population, NewSamples];
    CombinedFitness = [CombinedPop.Fitness];
    [~, final_sorted_indices] = sort(CombinedFitness, 'descend');
    
    NewPopulation = CombinedPop(final_sorted_indices(1:PopSize));
    EliteIndividual = NewPopulation(1); % 适应度最高的个体

end