% 文件: NSGAII_Optimizer.m
function NewPop = NSGAII_Optimizer(Pop, X, Y, params)
    % NSGA-II 核心迭代函数 (One Generation)
    
    nPop = length(Pop);
    D = size(X, 2);
    
    % --- 1. 生成子代 (Offspring Generation) ---
    Offspring = repmat(struct('Position', [], 'Cost', [], 'Rank', [], 'CD', [], 'Acc', [], 'FeatCount', []), nPop, 1);
    
    % 二元锦标赛选择 (Binary Tournament Selection)
    % 先计算父代的 Rank 和 CD (如果上一代没算过)
    if isempty(Pop(1).Rank)
        [Pop, ~] = NonDominatedSorting(Pop);
        Pop = CalcCrowdingDistance(Pop);
    end
    
    for i = 1:2:nPop
        % 选择父本
        p1 = TournamentSelect(Pop);
        p2 = TournamentSelect(Pop);
        
        % 交叉 (Uniform Crossover for Binary)
        c1 = p1.Position;
        c2 = p2.Position;
        if rand < 0.9 % Crossover Rate
            mask = rand(1, D) > 0.5;
            temp = c1;
            c1(mask) = c2(mask);
            c2(mask) = temp(mask);
        end
        
        % 变异 (Bit-flip Mutation)
        MuRate = 1/D;
        c1 = Mutate(c1, MuRate);
        c2 = Mutate(c2, MuRate);
        
        % 存入子代并评估
        Offspring(i).Position = c1;
        [acc1, cnt1] = Evaluate_Helper(c1, X, Y, params);
        Offspring(i).Cost = [(1-acc1), (cnt1/D)];
        Offspring(i).Acc = acc1;
        Offspring(i).FeatCount = cnt1;
        
        if i+1 <= nPop
            Offspring(i+1).Position = c2;
            [acc2, cnt2] = Evaluate_Helper(c2, X, Y, params);
            Offspring(i+1).Cost = [(1-acc2), (cnt2/D)];
            Offspring(i+1).Acc = acc2;
            Offspring(i+1).FeatCount = cnt2;
        end
    end
    
    % --- 2. 合并种群 (Merge) ---
    CombinedPop = [Pop; Offspring];
    
    % --- 3. 快速非支配排序 (Fast Non-Dominated Sorting) ---
    [CombinedPop, F] = NonDominatedSorting(CombinedPop);
    
    % --- 4. 拥挤度距离计算与精英保留 (Crowding Distance & Elitism) ---
    NewPop = repmat(struct('Position', [], 'Cost', [], 'Rank', [], 'CD', [], 'Acc', [], 'FeatCount', []), nPop, 1);
    newPopIdx = 1;
    
    % 依次把 Front 加入新种群，直到填满
    for i = 1:length(F)
        Front = CombinedPop(F{i});
        if newPopIdx + length(Front) - 1 <= nPop
            % 如果能全部放下
            Front = CalcCrowdingDistance(Front);
            NewPop(newPopIdx : newPopIdx+length(Front)-1) = Front;
            newPopIdx = newPopIdx + length(Front);
        else
            % 如果放不下了，按拥挤度排序截断
            Front = CalcCrowdingDistance(Front);
            [~, CD_Sort_Idx] = sort([Front.CD], 'descend');
            NumNeeded = nPop - newPopIdx + 1;
            NewPop(newPopIdx : end) = Front(CD_Sort_Idx(1:NumNeeded));
            break;
        end
    end
end

% --- 辅助函数 ---

function p = TournamentSelect(Pop)
    % 二元锦标赛：随机选两个，Rank小的赢；Rank一样CD大的赢
    idx = randperm(length(Pop), 2);
    ind1 = Pop(idx(1));
    ind2 = Pop(idx(2));
    
    if ind1.Rank < ind2.Rank
        p = ind1;
    elseif ind2.Rank < ind1.Rank
        p = ind2;
    else
        if ind1.CD > ind2.CD
            p = ind1;
        else
            p = ind2;
        end
    end
end

function pos = Mutate(pos, mu)
    idx = rand(size(pos)) < mu;
    pos(idx) = ~pos(idx); % 0变1, 1变0
    % 确保至少有一个特征
    if sum(pos) == 0
        pos(randi(length(pos))) = 1;
    end
end

function [Pop, F] = NonDominatedSorting(Pop)
    n = length(Pop);
    dominate_list = cell(n, 1);
    dominated_count = zeros(n, 1);
    F = cell(1, 1); % Fronts
    
    for i = 1:n
        for j = i+1:n
            % 检查支配关系
            if Dominate(Pop(i), Pop(j))
                dominate_list{i} = [dominate_list{i}, j];
                dominated_count(j) = dominated_count(j) + 1;
            elseif Dominate(Pop(j), Pop(i))
                dominate_list{j} = [dominate_list{j}, i];
                dominated_count(i) = dominated_count(i) + 1;
            end
        end
        if dominated_count(i) == 0
            Pop(i).Rank = 1;
            F{1} = [F{1}, i];
        end
    end
    
    k = 1;
    while ~isempty(F{k})
        Q = [];
        for i = F{k}
            for j = dominate_list{i}
                dominated_count(j) = dominated_count(j) - 1;
                if dominated_count(j) == 0
                    Pop(j).Rank = k + 1;
                    Q = [Q, j];
                end
            end
        end
        k = k + 1;
        F{k} = Q;
    end
    F(end) = []; % 移除最后的空层
end

function flag = Dominate(p1, p2)
    % 最小化问题: Cost(1)是错误率, Cost(2)是特征率
    % p1 支配 p2 当且仅当：所有目标 p1<=p2 且 至少一个 p1<p2
    flag = all(p1.Cost <= p2.Cost) && any(p1.Cost < p2.Cost);
end

function Pop = CalcCrowdingDistance(Pop)
    n = length(Pop);
    if n == 0, return; end
    
    num_obj = length(Pop(1).Cost);
    for i = 1:n, Pop(i).CD = 0; end
    
    for m = 1:num_obj
        [~, idx] = sort([Pop.Cost] * (m==1)); % 这里需要一点技巧处理多列排序，简化写法如下
        % 提取第 m 个目标并排序
        Costs = reshape([Pop.Cost], num_obj, n)';
        [~, idx] = sort(Costs(:, m));
        
        Pop(idx(1)).CD = inf;
        Pop(idx(end)).CD = inf;
        
        Range = Costs(idx(end), m) - Costs(idx(1), m);
        if Range == 0, Range = 1e-6; end
        
        for j = 2:n-1
            Pop(idx(j)).CD = Pop(idx(j)).CD + (Costs(idx(j+1), m) - Costs(idx(j-1), m)) / Range;
        end
    end
end

function [acc, cnt] = Evaluate_Helper(mask, X, Y, params)
    % 本地评估函数封装
    acc = evaluateSubset(X, Y, mask, params);
    cnt = sum(mask);
end