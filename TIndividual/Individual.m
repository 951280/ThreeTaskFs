% @Individual/Individual.m

classdef Individual < handle
    % Individual 类：表示协同进化算法中的一个解（特征子集）。
    % 继承自 handle 类，允许对象通过引用传递，这对进化算法中的种群更新非常高效。
    
    properties
        % --- 核心特征子集 (Feature Selection) ---
        FeaturesSubset      % [逻辑数组] 当前个体所选择的特征子集 (二元解)。
        Accuracy            % [double] 使用 FeaturesSubset 在分类器上的准确率 Acc(S)。
        FeatureCount        % [int] 特征子集的数量 |S|。
        
        % --- CSO/PSO 优化属性 (实数解空间) ---
        Position            % [double vector] 个体在实数空间中的位置 (P, 用于 CSO 迭代)。
        Velocity            % [double vector] 个体在实数空间中的速度 (V, 用于 CSO 迭代)。

        % --- 任务适应度和目标 ---
        Fitness             % [double] 单目标适应度值 (f1/f2/f3)。
        DuoObjective        % [1x2 double vector] 任务一的双目标值: [Accuracy, CompressionRatio]。
        TaskID              % [int] 属于哪个任务 (1, 2, 或 3)。
        
        % --- 多目标优化属性 (CSO/NSGA-II) ---
        ParetoFrontRank     % [int] 帕累托前沿的等级 (Rank)。
        CrowdingDistance    % [double] 拥挤距离 (Crowding Distance)。
        
        % 以下属性用于 CSO/NSGA-II 排序过程中的临时存储
        DominatingCount     % [int] 个体被多少其他个体支配。
        DominatedSet        % [vector] 个体支配的其他个体的索引集合。
    end
    
    methods
        function obj = evaluate(obj, X, Y, fitness_functions, params) % <--- 修改: 新增 params 输入
            % EVALUATE 评估个体的分类精度和计算适应度。
            
            % 1. 获取子集的准确率 Acc(S)
            % 注意：对于 CSO 任务，解码/子集确定已在 CSO_Optimizer 中完成
            if isempty(obj.FeaturesSubset) || ~any(obj.FeaturesSubset)
                obj.Accuracy = 0.0;
                obj.FeatureCount = 0;
            else
                obj.Accuracy = evaluateSubset(X, Y, obj.FeaturesSubset);
                obj.FeatureCount = sum(obj.FeaturesSubset);
            end

            % 2. 根据任务 ID 计算适应度
            S_total = size(X, 2);
            CompressionRatio = 1 - (obj.FeatureCount / S_total);
            
            switch obj.TaskID
                case 1
                    % 任务一：平衡精度与特征数量
                    % f1(Acc, S_count, N_total, alpha)
                    alpha = params.Fitness.Alpha; % 从 params 中获取 alpha
                    obj.Fitness = fitness_functions.f1(obj.Accuracy, obj.FeatureCount, S_total, alpha);
                    % 存储双目标值
                    obj.DuoObjective = [obj.Accuracy, CompressionRatio];
                case 2
                    % 任务二：精度优化器
                    % f2(Acc, S_count, N_total, lambda)
                    lambda = params.Fitness.Lambda; % 从 params 中获取 lambda
                    obj.Fitness = fitness_functions.f2(obj.Accuracy, obj.FeatureCount, S_total, lambda); 
                case 3
                    % 任务三：紧凑性优化器
                    % f3(Acc, S_count, N_total, theta_acc)
                    theta_acc = params.Fitness.ThetaAcc; % 从 params 中获取 theta_acc
                    obj.Fitness = fitness_functions.f3(obj.Accuracy, obj.FeatureCount, S_total, theta_acc); 
                otherwise
                    error('Individual:InvalidTaskID', '个体任务 ID 必须是 1, 2, 或 3。');
            end
        end        function new_individual = clone(obj)
            % CLONE 创建当前个体的一个深拷贝。
            new_individual = copy(obj);
        end
        
    end % methods
end % classdef