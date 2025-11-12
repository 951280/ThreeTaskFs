% OptimizationEngines/GenerateKnowledgeVector.m

function KB_V = GenerateKnowledgeVector(KB, params, D_total)
% GENERATEKNOWLEDGEVECTOR 基于 SV 知识生成一个推荐的位置向量 KB_V。
%
% 输入:
%   KB: [KnowledgeBase handle] 知识库实例。
%   params: [struct] 配置参数。
%   D_total: [int] 总特征数量。
%
% 输出:
%   KB_V: [1 x D_total double] 基于知识库的推荐位置向量 (即特征被选中概率 P)。

    SV_domain = KB.SV;
    Indices_domain = KB.FeatureDomainIndices;
    Init_Value = params.Knowledge.IM_SV_InitValue;

    % 1. 映射 SV_domain 到全长向量 SV_full
    SV_full = ones(1, D_total) * Init_Value; % 极小值填充
    SV_full(Indices_domain) = SV_domain;
    
    % 2. 归一化 SV_full 作为推荐概率 P (Knowledge Vector)
    min_sv = min(SV_full);
    max_sv = max(SV_full);
    
    if max_sv == min_sv
        KB_V = ones(1, D_total) * 0.5; % 均匀分布
    else
        % 归一化到 [0, 1] 区间
        KB_V = (SV_full - min_sv) / (max_sv - min_sv);
    end
    
    % 3. 约束概率范围
    INIT_PROB = 0.01;
    KB_V = max(INIT_PROB, min(1 - INIT_PROB, KB_V));

    % 注意: IM 在这个简单的引导公式中不直接使用，它通过 updateIM_SV 间接修正了 SV。
end