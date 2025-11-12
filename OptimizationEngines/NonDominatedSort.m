% OptimizationEngines/NonDominatedSort.m

function Population = NonDominatedSort(Population, ObjectiveMatrix)
% NONDOMINATEDSORT 执行非支配排序并计算拥挤距离 (简化版)。
% (CSO 的基础，类似于 NSGA-II 的排序步骤)
%
% 输入:
%   Population: [Individual array] 种群数组。
%   ObjectiveMatrix: [PopSize x M double] 目标矩阵 (M=2: Acc 和 Compression)。
%
% 输出:
%   Population: 更新了 Rank 和 CrowdingDistance 属性的种群。

    PopSize = length(Population);
    
    % --- 1. 初始化和寻找支配关系 ---
    for i = 1:PopSize
        P = Population(i);
        P.DominatingCount = 0;
        P.DominatedSet = [];
        
        for j = 1:PopSize
            Q = Population(j);
            
            % 检查 P 是否支配 Q (目标值都是越大越好)
            P_dominates_Q = all(P.DuoObjective >= Q.DuoObjective) && any(P.DuoObjective > Q.DuoObjective);
            
            if P_dominates_Q
                P.DominatedSet = [P.DominatedSet, j]; % P 支配 Q
            elseif all(Q.DuoObjective >= P.DuoObjective) && any(Q.DuoObjective > P.DuoObjective)
                P.DominatingCount = P.DominatingCount + 1; % Q 支配 P
            end
        end
    end

    % --- 2. 确定前沿 (Fronts) ---
    CurrentFront = [];
    NextPopulationIndices = [];
    
    % 找到第一个前沿 F1 (DominatingCount = 0 的个体)
    for i = 1:PopSize
        if Population(i).DominatingCount == 0
            Population(i).ParetoFrontRank = 1;
            CurrentFront = [CurrentFront, i];
        end
    end
    
    % (此处省略后续前沿 F2, F3... 的迭代逻辑，只聚焦于更新 F1)

    % --- 3. 计算拥挤距离 (Crowding Distance) ---
    
    % 只对当前找到的前沿 (F1) 计算距离 (简化)
    FrontIndices = CurrentFront; 
    FrontSize = length(FrontIndices);
    
    if FrontSize > 0
        % 目标数量 M=2
        for m = 1:2
            [~, sorted_idx] = sort(ObjectiveMatrix(FrontIndices, m));
            sorted_FrontIndices = FrontIndices(sorted_idx);

            % 边界点的距离设为 Inf
            Population(sorted_FrontIndices(1)).CrowdingDistance = Inf;
            Population(sorted_FrontIndices(end)).CrowdingDistance = Inf;
            
            % 计算中间点的距离
            for k = 2:FrontSize-1
                % 距离 = 两个相邻点的目标差 / 目标范围
                Range = ObjectiveMatrix(sorted_FrontIndices(end), m) - ObjectiveMatrix(sorted_FrontIndices(1), m);
                if Range == 0
                    % 目标值都相同，距离设为 0
                    Distance_Change = 0;
                else
                    Distance_Change = (ObjectiveMatrix(sorted_FrontIndices(k+1), m) - ObjectiveMatrix(sorted_FrontIndices(k-1), m)) / Range;
                end
                
                Population(sorted_FrontIndices(k)).CrowdingDistance = Population(sorted_FrontIndices(k)).CrowdingDistance + Distance_Change;
            end
        end
    end
end