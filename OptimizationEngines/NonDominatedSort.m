% 文件: OptimizationEngines/NonDominatedSort.m
function Population = NonDominatedSort(Population, ObjectiveMatrix)
% NONDOMINATEDSORT 执行标准的 NSGA-II 快速非支配排序和拥挤距离计算
%
% 输入:
%   Population: [Individual array] 种群数组
%   ObjectiveMatrix: [PopSize x 2] 目标矩阵 [Accuracy, Compression]
%                    (注意：本系统默认目标是最大化，越大越好)
%
% 输出:
%   Population: 更新了 ParetoFrontRank 和 CrowdingDistance 属性的种群

    PopSize = length(Population);
    
    % --- 1. 快速非支配排序 (Fast Non-Dominated Sort) ---
    % 注意：适配为【最大化】问题 (Dominance: >= 且 >)
    
    fronts = cell(PopSize, 1); % 存储每一层的个体索引
    dominates_list = cell(PopSize, 1); % S_p: p 支配的个体集合
    dominated_count = zeros(PopSize, 1); % n_p: 支配 p 的个体数量
    rank_count = 0; % 前沿层数
    
    for p = 1:PopSize
        dominates_list{p} = [];
        dominated_count(p) = 0;
        
        for q = 1:PopSize
            if p == q
                continue;
            end
            
            % 获取目标值
            ObjP = ObjectiveMatrix(p, :);
            ObjQ = ObjectiveMatrix(q, :);
            
            % 判断 p 是否支配 q (最大化逻辑)
            % 条件：p 在所有目标上 >= q，且至少在一个目标上 > q
            if all(ObjP >= ObjQ) && any(ObjP > ObjQ)
                dominates_list{p} = [dominates_list{p}, q]; % p 支配 q
            elseif all(ObjQ >= ObjP) && any(ObjQ > ObjP)
                dominated_count(p) = dominated_count(p) + 1; % p 被 q 支配
            end
        end
        
        % 如果 p 不被任何人支配，则属于第一前沿 Rank 1
        if dominated_count(p) == 0
            Population(p).ParetoFrontRank = 1;
            if isempty(fronts{1})
                fronts{1} = p;
            else
                fronts{1} = [fronts{1}, p];
            end
        end
    end
    
    % 生成后续前沿 (Rank 2, 3, ...)
    i = 1;
    while i <= length(fronts) && ~isempty(fronts{i})
        Q = []; % 存放下一层前沿
        for p = fronts{i} % 遍历当前层
            for q = dominates_list{p} % 遍历 p 支配的个体
                dominated_count(q) = dominated_count(q) - 1;
                if dominated_count(q) == 0
                    % 如果 q 的支配计数归零，则进入下一层
                    Population(q).ParetoFrontRank = i + 1;
                    Q = [Q, q];
                end
            end
        end
        i = i + 1;
        if ~isempty(Q)
            fronts{i} = Q;
        end
    end
    
    % --- 2. 计算每一层的拥挤距离 (Crowding Distance) ---
    % 初始化所有个体的距离为 0
    for p = 1:PopSize
        Population(p).CrowdingDistance = 0;
    end
    
    NumFronts = i - 1;
    NumObjectives = size(ObjectiveMatrix, 2);
    
    for f = 1:NumFronts
        current_front = fronts{f};
        k = length(current_front);
        
        if k <= 2
            % 如果前沿只有 1 或 2 个个体，距离设为无穷大（保留边界）
            for idx = current_front
                Population(idx).CrowdingDistance = inf;
            end
            continue;
        end
        
        % 获取当前前沿的目标值矩阵
        FrontObj = ObjectiveMatrix(current_front, :);
        
        % 对每个目标进行处理
        for m = 1:NumObjectives
            % 根据第 m 个目标值排序
            [sortedVals, sortedIndices] = sort(FrontObj(:, m));
            
            % 获取原始种群中的索引
            original_indices = current_front(sortedIndices);
            
            % 边界个体距离设为无穷大
            Population(original_indices(1)).CrowdingDistance = inf;
            Population(original_indices(end)).CrowdingDistance = inf;
            
            % 归一化分母 (Max - Min)
            obj_range = sortedVals(end) - sortedVals(1);
            if obj_range == 0
                continue; % 目标值全部相同，跳过
            end
            
            % 计算中间个体的距离
            for j = 2:(k-1)
                % 如果已经是无穷大，保持无穷大
                if isinf(Population(original_indices(j)).CrowdingDistance)
                    continue;
                end
                
                % 标准公式：(后一个值 - 前一个值) / 范围
                % 注意：无论是最大化还是最小化，只要已排序，距离就是正的
                dist_inc = (sortedVals(j+1) - sortedVals(j-1)) / obj_range;
                Population(original_indices(j)).CrowdingDistance = ...
                    Population(original_indices(j)).CrowdingDistance + dist_inc;
            end
        end
    end
end