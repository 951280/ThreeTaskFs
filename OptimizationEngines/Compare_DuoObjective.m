% OptimizationEngines/Compare_DuoObjective.m

function [Winner_idx, Loser_idx] = Compare_DuoObjective(P1_idx, P2_idx, Population, Fronts, CrowdingDistances)
% COMPARE_DUOOBJECTIVE 比较两个个体 P1 和 P2，根据非支配排序和拥挤距离确定 Winner 和 Loser。
% 
% 输入:
%   P1_idx, P2_idx: [int] 个体在 Population 中的索引。
%   Population: [Individual array] 种群数组。
%   Fronts: [cell array] 非支配前沿的索引列表。
%   CrowdingDistances: [vector] 每个个体的拥挤距离。
%
% 输出:
%   Winner_idx, Loser_idx: [int] 获胜者和失败者在 Population 中的索引。

    P1 = Population(P1_idx);
    P2 = Population(P2_idx);
    
    % 1. 获取非支配等级 (Rank) 和拥挤距离 (Distance)
    R1 = P1.ParetoFrontRank; 
    R2 = P2.ParetoFrontRank;
    D1 = P1.CrowdingDistance;
    D2 = P2.CrowdingDistance;

    % 2. 比较逻辑 (基于支配排序理论)
    % 规则 1: 等级低者胜 (等级 R 越小越好)
    if R1 < R2
        Winner_idx = P1_idx;
        Loser_idx = P2_idx;
    elseif R2 < R1
        Winner_idx = P2_idx;
        Loser_idx = P1_idx;
    
    % 规则 2: 等级相同时，拥挤距离大者胜 (距离 D 越大越好)
    else % R1 == R2 (两者位于同一前沿)
        if D1 > D2
            Winner_idx = P1_idx;
            Loser_idx = P2_idx;
        elseif D2 > D1
            Winner_idx = P2_idx;
            Loser_idx = P1_idx;
        
        % 规则 3: 完全相同时，随机选择
        else
            if rand() < 0.5
                Winner_idx = P1_idx;
                Loser_idx = P2_idx;
            else
                Winner_idx = P2_idx;
                Loser_idx = P1_idx;
            end
        end
    end
end