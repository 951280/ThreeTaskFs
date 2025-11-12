% KnowledgeTransfer/transferMainToAux.m

function [Population2, Population3] = transferMainToAux(ParetoFront, Population2, Population3)
% TRANSFERMAINTOAUX 将主任务的帕累托前沿解迁移给辅助任务作为指导解。
%
% 输入:
%   ParetoFront: [Individual array] 主任务 F1 帕累托前沿解集。
%   Population2: [Individual array] 任务二种群 (会被修改)。
%   Population3: [Individual array] 任务三种群 (会被修改)。
%
% 输出:
%   Population2, Population3: 更新了指导解的种群。

    disp('  > 知识迁移：主任务 (CSO) -> 辅助任务 (EDA) 启动...');

    if isempty(ParetoFront)
        warning('transferMainToAux:EmptyParetoFront', 'CSO 帕累托前沿为空，无法进行知识迁移。');
        return;
    end
    
    % --- 1. 确定辅助任务的当前最佳个体 (Elite) ---
    Elite2 = findBestIndividual(Population2); % 任务二最佳 (f2)
    Elite3 = findBestIndividual(Population3); % 任务三最佳 (f3)

    % --- 2. 迁移给任务二 (精度优化器) ---
    % 目标：与 Elite2 相似，但精度更高 (Precision)
    G2 = Find_Guiding_Solution(Elite2, ParetoFront, 'Precision');

    if ~isempty(G2)
        % 替换任务二中最差的个体
        Population2 = Replace_Loser(Population2, G2);
        disp('  > 任务二：已找到并迁移更优精度指导解 G2。');
    end

    % --- 3. 迁移给任务三 (紧凑性优化器) ---
    % 目标：与 Elite3 相似，但特征数量更少 (Compactness)
    G3 = Find_Guiding_Solution(Elite3, ParetoFront, 'Compactness');

    if ~isempty(G3)
        % 替换任务三中最差的个体
        Population3 = Replace_Loser(Population3, G3);
        disp('  > 任务三：已找到并迁移更优紧凑性指导解 G3。');
    end

    disp('  > 知识迁移完成。');
end


% --- 辅助函数：寻找指导解的核心逻辑 ---

function Best_Guide = Find_Guiding_Solution(Elite_aux, ParetoFront, Goal)
    Best_Guide = [];
    Min_Distance = inf; 

    for k = 1:length(ParetoFront)
        Guide = ParetoFront(k);
        
        % 步骤 A: 相似性检查 (汉明距离)
        % 汉明距离 = 特征子集不同的个数
        Hamming_Distance = sum(Elite_aux.FeaturesSubset ~= Guide.FeaturesSubset);
        
        % 步骤 B: 目标优越性检查
        Is_Superior = false;
        if strcmp(Goal, 'Precision')
            % 任务二：寻找精度更高的解
            if Guide.Accuracy > Elite_aux.Accuracy
                Is_Superior = true;
            end
        elseif strcmp(Goal, 'Compactness')
            % 任务三：寻找特征数量更少的解
            if Guide.FeatureCount < Elite_aux.FeatureCount
                Is_Superior = true;
            end
        end

        % 步骤 C: 寻找最相似且优越的解 (最小化汉明距离)
        if Is_Superior && Hamming_Distance < Min_Distance
            Min_Distance = Hamming_Distance;
            Best_Guide = Guide;
        end
    end
end

% --- 辅助函数：替换最差个体 ---

function Population = Replace_Loser(Population, Guide)
    % 找到种群中适应度最低的个体 (Loser) 的索引
    all_fitness = [Population.Fitness];
    [~, Loser_idx] = min(all_fitness);
    
    % 用指导解的深拷贝替换 Loser
    Population(Loser_idx) = Guide.clone();
end

% --- 辅助函数：找到最佳个体 ---

function Elite = findBestIndividual(Population)
    all_fitness = [Population.Fitness];
    [~, Elite_idx] = max(all_fitness);
    Elite = Population(Elite_idx);
end