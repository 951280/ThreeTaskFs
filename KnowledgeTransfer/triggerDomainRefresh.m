% KnowledgeTransfer/triggerDomainRefresh.m

function KB = triggerDomainRefresh(KB, Elite2, Elite3)
% TRIGGERDOMAINREFRESH 负责计算新特征域并触发知识库更新
% 策略更新：采用“共识机制 (Consensus)”，取任务二和任务三的【交集】。
%
% 输入:
%   KB: [KnowledgeBase handle] 共享 IM/SV 知识库实例 (会被修改)。
%   Elite2: [Individual] 任务二最佳个体。
%   Elite3: [Individual] 任务三最佳个体。
%
% 输出:
%   KB: 更新了特征域的 KnowledgeBase 实例。

    disp('  > 知识迁移：正在执行 IM/SV 知识域刷新...');

    % 1. 获取任务二和任务三的当前精英特征子集
    S_Elite2 = Elite2.FeaturesSubset;
    S_Elite3 = Elite3.FeaturesSubset;
    
    % 确保两个逻辑向量长度一致
    if length(S_Elite2) ~= length(S_Elite3)
        error('triggerDomainRefresh:SubsetLengthMismatch', '任务二和任务三的特征子集长度不匹配。');
    end
    
    % 2. 计算新的特征域 F1 (核心修改)
    % 优先尝试：交集 (Consensus) -> 聚焦核心，去伪存真
    F1_mask = S_Elite2 & S_Elite3;
    F1_indices = find(F1_mask);
    
    % 3. 【高维数据兜底策略】
    % 如果两个任务分歧太大，交集可能为空或极少。这会导致知识库失效。
    % 阈值设为 1 (只要有非空交集就接受)，也可以设为 2 或更多。
    if isempty(F1_indices)
        warning('TriggerRefresh:EmptyIntersection', ...
            '任务二与任务三共识为空 (分歧过大)，本次刷新临时退化为【并集】以保持探索性。');
            
        % 备用方案：退化为并集
        F1_mask = S_Elite2 | S_Elite3;
        F1_indices = find(F1_mask);
    end

    % 4. 调用 KnowledgeBase 内部方法进行实际的矩阵调整
    % KB 类的 refreshDomain 方法会处理旧知识的迁移和新矩阵的初始化。
    KB = KB.refreshDomain(F1_indices); % 这里明确调用类方法

    disp(['  > 知识域刷新完成。新域大小: ', num2str(KB.DomainSize), ...
          ' (共 ', num2str(KB.TotalFeatureCount), ' 个特征)']);

end