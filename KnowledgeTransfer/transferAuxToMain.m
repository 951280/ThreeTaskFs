% KnowledgeTransfer/transferAuxToMain.m

function P_KB = transferAuxToMain(KB, CSO_Population, params)
% TRANSFERAUXTOMAIN 将辅助任务 (IM/SV) 知识迁移到主任务 CSO。
% 
% 输入:
%   KB: [KnowledgeBase handle] 共享 IM/SV 知识库实例。
%   CSO_Population: [Individual array] 主任务种群 (用于确定维度)。
%   params: [struct] 配置参数。
%
% 输出:
%   P_KB: [1 x D_total double] 基于知识库的推荐位置向量 (即特征被选中概率 P)。

    disp('  > 知识迁移：辅助任务 (IM/SV) -> 主任务 (CSO) 启动...');
    
    % 1. 确定目标维度 D_total
    % 假设 CSO 种群的 Position 属性长度为 D_total
    if isempty(CSO_Population) || isempty(CSO_Population(1).Position)
        error('transferAuxToMain:EmptyPopulation', 'CSO 种群为空或未初始化 Position 属性。');
    end
    D_total = length(CSO_Population(1).Position);
    
    % 2. 生成知识引导向量 P_KB
    % P_KB 是一个长度为 D_total 的向量，其值基于 SV 归一化，作为 CSO 粒子的
    % 推荐位置 (即特征被选中的倾向 P)。
    
    % 调用 CSO 辅助函数来实现核心逻辑
    P_KB = GenerateKnowledgeVector(KB, params, D_total); 

    disp('  > 知识迁移完成。P_KB 向量已生成并准备用于 CSO 引导。');
    
end