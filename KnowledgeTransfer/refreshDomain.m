% KnowledgeTransfer/refreshDomain.m

function KB = refreshDomain(KB, Elite2, Elite3)
% REFRESHDOMAIN 周期性地刷新 IM 和 SV 的特征域。
% 该函数将任务二和任务三的当前最佳特征子集求并集，作为新的特征域 F1。
%
% 输入:
%   KB: [KnowledgeBase handle] 共享 IM/SV 知识库实例 (会被修改)。
%   Elite2: [Individual] 任务二最佳个体。
%   Elite3: [Individual] 任务三最佳个体。
%
% 输出:
%   KB: 更新了特征域的 KnowledgeBase 实例。

    disp('  > 知识迁移：正在执行 IM/SV 知识域刷新...');

    % 1. 获取任务二和任务三的当前精英特征子集 (全局逻辑向量)
    % 确保子集不是空的，否则会影响并集计算
    S_Elite2 = Elite2.FeaturesSubset;
    S_Elite3 = Elite3.FeaturesSubset;
    
    % 2. 计算新的特征域 F1
    % F1 是 Elite2 和 Elite3 特征子集的并集。
    % MATLAB 的逻辑 OR (|) 操作符可以直接求两个逻辑向量的并集。
    
    % 确保两个逻辑向量长度一致 (理论上应该与 D_total 一致)
    if length(S_Elite2) ~= length(S_Elite3)
        error('refreshDomain:SubsetLengthMismatch', '任务二和任务三的特征子集长度不匹配。');
    end
    
    % F1_mask 是一个逻辑向量，表示并集特征
    F1_mask = S_Elite2 | S_Elite3;
    
    % F1_indices 是实际的特征索引 (即论文中的 F1)
    F1_indices = find(F1_mask);

    % 3. 调用 KnowledgeBase 内部方法进行实际的矩阵调整
    % KB 类的 refreshDomain 方法会处理旧知识的迁移和新矩阵的初始化。
    KB = KB.refreshDomain(F1_indices);

    disp(['  > 知识域刷新完成。新域大小: ', num2str(KB.DomainSize), ' (共 ', num2str(KB.TotalFeatureCount), ' 个特征)']);

end