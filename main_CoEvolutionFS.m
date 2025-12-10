% 文件: main_CoEvolutionFS.m
function main_CoEvolutionFS(target_dataset_name)
% MAIN_COEVOLUTIONFS 三任务协同进化特征选择算法的主控制函数。
% 包含：强力精英注入 + 最终结果融合 + 断层填充局部搜索(GFLS) + 参数同步策略

    t_start = clock; 
    
    % --- 1. 初始化和配置 ---
    if ~exist('params', 'var')
        run('config_parameters.m');
    end
    
    % 接收外部参数
    if nargin < 1
        DATASET_TO_RUN = 'SONAR'; 
    else
        DATASET_TO_RUN = target_dataset_name;
    end
    
    fprintf('>>> 正在启动任务，当前数据集: %s <<<\n', DATASET_TO_RUN);
    
    % --- 数据集路径配置 ---
    if strcmp(DATASET_TO_RUN, 'SECOM')
        disp('  > 正在加载 SECOM 数据集 (N=1567, D=590)...');
        DATA_PATH   = 'D:\learn\yjs\paper\data\secom\secom.data'; 
        LABELS_PATH = 'D:\learn\yjs\paper\data\secom\secom_labels.data';
        [X, Y, ~] = data_loader(DATA_PATH, LABELS_PATH, DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'SPECTF')
        disp('  > 正在加载 SPECTF Heart 数据集 (N=267, D=22)...');
        TRAIN_PATH = 'D:\learn\yjs\paper\data\spect+heart\SPECT.train';  
        TEST_PATH  = 'D:\learn\yjs\paper\data\spect+heart\SPECT.test';   
        [X, Y, ~] = data_loader(TRAIN_PATH, TEST_PATH, DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'SONAR')
        disp(' > 正在加载 SONAR 数据集 (N=208, D=60)...');
        DATA_PATH = 'D:\learn\yjs\paper\data\sonar\sonar.all-data'; 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
    elseif strcmp(DATASET_TO_RUN, 'Gait')
        disp(' > 正在加载 Gait Classification 数据集...');
        DATA_PATH = 'D:\learn\yjs\paper\data\gait+classification\PersonGaitDataSet.mat'; 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
 
    elseif strcmp(DATASET_TO_RUN, 'Madelon')
        disp(' > 正在加载 Madelon 数据集 (N=2000, D=500)...');
        % 修正路径拼写 MADELONn -> MADELON
        DATA_PATH = 'D:\learn\yjs\paper\data\madelon\MADELON\madelon_train.data'; 
        LABELS_PATH = 'D:\learn\yjs\paper\data\madelon\MADELON\madelon_train.labels';
        [X, Y, ~] = data_loader(DATA_PATH, LABELS_PATH, DATASET_TO_RUN);
     elseif strcmp(DATASET_TO_RUN, 'Period_Changer')
        disp(' > 正在加载 Period Changer 数据集 (N=90, D=1177)...');
        DATA_PATH = 'D:\learn\yjs\paper\data\period+changer-2\data.csv'; 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
      elseif strcmp(DATASET_TO_RUN, 'Toxicity')
        disp(' > 正在加载 Toxicity 数据集 (N=171, D=1203)...');     
        DATA_PATH = 'D:\learn\yjs\paper\data\toxicity\data.csv'; 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
       elseif strcmp(DATASET_TO_RUN, 'Micro_Mass')
        disp(' > 正在加载 Micro-Mass (Pure Spectra) 数据集...');
        DATA_PATH = 'D:\learn\yjs\paper\data\micromass\pure_spectra_matrix.csv'; 
        LABELS_PATH = 'D:\learn\yjs\paper\data\micromass\pure_spectra_metadata.csv';
        [X, Y, ~] = data_loader(DATA_PATH, LABELS_PATH, DATASET_TO_RUN);
    elseif strcmp(DATASET_TO_RUN, 'Internet_Ads')
        disp(' > 正在加载 Internet Advertisements 数据集 (N=3279, D=1558)...');
        DATA_PATH = 'D:\learn\yjs\paper\data\internet+advertisements\ad.data'; 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'Colon')
        disp(' > 正在加载 Colon Tumor 数据集 (N=62, D=2000)...');
        DATA_PATH = 'D:\learn\yjs\paper\data\colon.mat'; 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'Lung_Cancer')
        disp(' > 正在加载 Lung Cancer 数据集 (N=203, D=3312)...');
        DATA_PATH = 'D:\learn\yjs\paper\data\lung.mat'; 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'Gisette')
        disp(' > 正在加载 Gisette 数据集 (Train Set, N=6000, D=5000)...');
        DATA_PATH = 'D:\learn\yjs\paper\data\gisette\gisette_train.data'; 
        LABELS_PATH = 'D:\learn\yjs\paper\data\gisette\gisette_train.labels';
        [X, Y, ~] = data_loader(DATA_PATH, LABELS_PATH, DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'Leukemia')
        disp(' > 正在加载 Leukemia 数据集 (N=72, D=7070)...');
        DATA_PATH = 'D:\learn\yjs\paper\data\leukemia.mat'; 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
    elseif strcmp(DATASET_TO_RUN, 'Musk')
        disp(' > 正在加载 Musk (Version 2) 数据集 (N=6598, D=166)...');
        DATA_PATH = 'D:\learn\yjs\paper\data\musk+version+2\clean2.data'; 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
    elseif strcmp(DATASET_TO_RUN, 'LSVT')
        disp(' > 正在加载 LSVT Voice Rehabilitation 数据集 (N=126, D=309)...');
        DATA_PATH = 'D:\learn\yjs\paper\data\lsvt+voice+rehabilitation\LSVT_voice_rehabilitation.xlsx'; 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
    elseif strcmp(DATASET_TO_RUN, 'Arrhythmia')
        disp(' > 正在加载 Arrhythmia 数据集 (N=452, D=279)...');
        DATA_PATH = 'D:\learn\yjs\paper\data\arrhythmia\arrhythmia.data'; 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
    else
        error('main_CoEvolutionFS:InvalidDataset', '请设置 DATASET_TO_RUN 为有效的配置名称。');
    end
    
    % 获取总特征维度
    D_total = size(X, 2);
    
    % 1.3 初始化函数句柄
    fitness_funcs.f1 = @f1_fitness;
    fitness_funcs.f2 = @f2_fitness;
    fitness_funcs.f3 = @f3_fitness;
    
    % 1.4 初始特征重要性计算
    disp('  > 正在计算初始特征重要性 (LGBM & Relief-F)...');
    W_LGBM = getLGBMImportance(X, Y);
    W_ReliefF = getReliefFImportance(X, Y);
    
    % 1.5 初始化种群
    disp('  > 正在初始化三任务种群...');
    [Pop1_init, ~, ~] = initialFeatureSelection(X, Y, W_LGBM, params, @evaluateSubset, 1);
    [Pop2_init, ~, F2_domain] = initialFeatureSelection(X, Y, W_LGBM, params, @evaluateSubset, 2); 
    [Pop3_init, ~, F3_domain] = initialFeatureSelection(X, Y, W_ReliefF, params, @evaluateSubset, 3);
    
    Population1 = Pop1_init;
    Population2 = Pop2_init;
    Population3 = Pop3_init;
    
    % 1.6 初始化知识库 (KB)
    % 初始阶段：使用 Union (并集) 确保覆盖面
    Initial_Domain_Indices = union(F2_domain, F3_domain);
    KB = KnowledgeBase(D_total, Initial_Domain_Indices, params.Knowledge.IM_SV_InitValue);
    
    % 1.7 初始评估
    disp('  > 正在执行初始种群评估...');
    for ind = Population2
        ind.evaluate(X, Y, fitness_funcs, params);
    end
    for ind = Population3
        ind.evaluate(X, Y, fitness_funcs, params);
    end
    
    % --- 2. 协同进化主循环 ---
    
    MaxGen = params.MaxGenerations;
    
    % =======================================================
    % ★★★ 核心修改1：参数同步耦合策略 ★★★
    % =======================================================
    % 不再使用随机数，而是将 K_Refresh 和 T_Transfer 设为相等的 Interaction_Period
    Interaction_Period = 20; % 或者从 params.Knowledge.K_Refresh 读取
    K_Refresh = Interaction_Period;
    T_Transfer = Interaction_Period;
    disp(['  > [参数策略] 交互周期已同步设定为: ', num2str(Interaction_Period), ' 代。']);
    
    ParetoFront_History = {}; 
    Elite2 = Population2(1).clone(); 
    Elite3 = Population3(1).clone();
    Experiment_History = struct('Gen', {}, 'Acc_Elite2', {}, 'Count_Elite2', {}, ...
                            'Acc_Elite3', {}, 'Count_Elite3', {}, ...
                            'Mean_Fit1', {}, 'Mean_Count1', {}, ...
                            'KB_DomainSize', {}, ...
                            'TimePerGen', {}); 
    
    % 初始化全局归档 (Global Archive)
    Global_Archive = []; 
    
    disp(['--- 协同进化主循环开始，最大代数: ', num2str(MaxGen), ' ---']);
    
    for Gen = 1:MaxGen
        t_gen_start = tic; 
        
        % --- 2.1 任务独立进化 ---
        
        % 任务一 (CSO 主任务)
        [Population1, ParetoFront] = CSO_Optimizer(Population1, KB, X, Y, params, fitness_funcs, Gen);
% =======================================================
        % ★★★ 核心修改：智能版 - 重要性引导断层填充 (Guided GFLS) ★★★
        % =======================================================
        % 改进点：利用 W_LGBM 先验知识，优先选择高分特征进行填补，
        % 大幅提高生成中间解的质量，修复 9->14 这种大跨度断层。
        
        CurrentPF = ParetoFront; 
        if length(CurrentPF) > 1
            % 按特征数量排序
            [~, idx_pf] = sort([CurrentPF.FeatureCount]);
            SortedPF = CurrentPF(idx_pf);
            
            % 遍历寻找断层
            for k_gap = 1:length(SortedPF)-1
                Sol_Small = SortedPF(k_gap);
                Sol_Large = SortedPF(k_gap+1);
                
                % 计算特征差值
                diff_count = Sol_Large.FeatureCount - Sol_Small.FeatureCount;
                
                % 阈值自适应 (至少为2，或者总特征的3%)
                gap_threshold = max(2, ceil(D_total * 0.03)); 
                
                if diff_count > gap_threshold
                    % === 发现断层，执行智能填补 ===
                    
                    % 1. 找出差异特征 (Large 有但 Small 没有的)
                    diff_mask = Sol_Large.FeaturesSubset & (~Sol_Small.FeaturesSubset);
                    diff_indices = find(diff_mask);
                    
                    if ~isempty(diff_indices)
                        % 获取这些差异特征的重要性分数
                        diff_scores = W_LGBM(diff_indices);
                        [~, score_sort_idx] = sort(diff_scores, 'descend');
                        sorted_diff_indices = diff_indices(score_sort_idx);
                        
                        % 尝试多次生成
                        attempts = 10; % 增加尝试次数
                        
                        for try_i = 1:attempts
                            % 随机决定填补的数量
                            num_to_add = randi([1, max(1, length(diff_indices)-1)]);
                            
                            % --- 核心策略：混合选择机制 ---
                            if rand() < 0.7 
                                % 策略 A (70%): 精英主义 - 选分数最高的 Top N
                                % 这样最容易生成高质量的中间解
                                features_to_add = sorted_diff_indices(1:num_to_add);
                            else
                                % 策略 B (30%): 随机主义 - 保持多样性
                                perm_idx = randperm(length(diff_indices), num_to_add);
                                features_to_add = diff_indices(perm_idx);
                            end
                            
                            % 生成基础掩码
                            NewGapMask = Sol_Small.FeaturesSubset;
                            NewGapMask(features_to_add) = true;
                            
                            % 轻微扰动：以 20% 的概率再随机翻转一个位 (跳出局部最优)
                            if rand() < 0.2
                                mutate_pos = randi(D_total);
                                NewGapMask(mutate_pos) = ~NewGapMask(mutate_pos);
                            end
                            
                            % 创建并评估
                            TempInd = Individual(NewGapMask, 1);
                            TempInd.evaluate(X, Y, fitness_funcs, params);
                            
                            % 注入策略：只要解不是特别差，就注入种群增加多样性
                            % 替换种群中随机的一个较差解（后 10% 中随机选一个，避免每次都杀同一个）
                            [~, sorted_fit_idx] = sort([Population1.Fitness]);
                            replace_range = sorted_fit_idx(1:max(1, round(params.PopSize * 0.1)));
                            replace_target = replace_range(randi(length(replace_range)));
                            
                            Population1(replace_target) = TempInd;
                            
                            % 如果这个解是非支配的（或者接近非支配），加入当前 PF 列表以便归档
                            % 简单判定：如果它的精度比 Sol_Small 并没有差太多
                             if TempInd.Accuracy >= Sol_Small.Accuracy * 0.9 
                                if isempty(CurrentPF)
                                    CurrentPF = TempInd;
                                else
                                    CurrentPF = [CurrentPF, TempInd];
                                end
                            end
                        end
                    end
                end
            end
        end
        % =======================================================  
        % =======================================================
        % ★★★ 核心修改：将当代 ParetoFront (含修复解) 加入全局归档 ★★★
        % =======================================================
        Current_Pareto_Clones = Individual.empty(0, length(CurrentPF));
        for k = 1:length(CurrentPF)
            Current_Pareto_Clones(k) = CurrentPF(k).clone();
        end
        
        if isempty(Global_Archive)
            Global_Archive = Current_Pareto_Clones;
        else
            Global_Archive = [Global_Archive, Current_Pareto_Clones];
        end
        
        % 任务二/三 (EDA 辅助任务)
        [Population2, Elite2] = EDA_Optimizer(Population2, KB, X, Y, params, fitness_funcs, 2);
        [Population3, Elite3] = EDA_Optimizer(Population3, KB, X, Y, params, fitness_funcs, 3);
        
        % =======================================================
        % ★★★ 核心策略：加大力度，强制注入 Top 3 精英 ★★★
        % =======================================================
        
        [~, sorted_idx] = sort([Population1.Fitness]); 
        worst_indices = sorted_idx(1:3); 
        
        for k = 1:3
            New_Individual = Elite2.clone(); 
            if k > 1
                mutation_idx = randi(length(New_Individual.FeaturesSubset), 1, randi(2));
                New_Individual.FeaturesSubset(mutation_idx) = ~New_Individual.FeaturesSubset(mutation_idx);
            end
            New_Individual.TaskID = 1;
            New_Individual.evaluate(X, Y, fitness_funcs, params);
            Population1(worst_indices(k)) = New_Individual;
        end
        % =======================================================
        % --- 2.2 知识更新 ---
        KB = updateIM_SV(KB, Elite2, Elite3, params);
        
        % --- 2.3 周期性检查与知识迁移 (同步周期策略) ---
        
        % a. 知识域刷新
        if mod(Gen, K_Refresh) == 0
            % 使用 triggerDomainRefresh 执行【交集】策略，并带有空集兜底
            KB = triggerDomainRefresh(KB, Elite2, Elite3);
        end
        % b. 知识迁移策略
        if mod(Gen, T_Transfer) == 0 
            [Population2, Population3] = transferMainToAux(ParetoFront, Population2, Population3);
        end
        % --- 2.4 记录与监控 ---
        ParetoFront_History{Gen} = ParetoFront; %#ok<AGROW>
        
        TimePerGen = toc(t_gen_start); 
        History.Gen = Gen;
        History.Acc_Elite2 = Elite2.Accuracy;
        History.Count_Elite2 = Elite2.FeatureCount;
        History.Acc_Elite3 = Elite3.Accuracy;
        History.Count_Elite3 = Elite3.FeatureCount;
        History.KB_DomainSize = KB.DomainSize;
        History.TimePerGen = TimePerGen;
        P1_Features = [Population1.FeatureCount];
        P1_Fitness = [Population1.Fitness];
        History.Mean_Fit1 = mean(P1_Fitness);
        History.Mean_Count1 = mean(P1_Features);
        Experiment_History(Gen) = History;
        
        fprintf('[Gen %d] E2(A/C): %.4f/%d | E3(A/C): %.4f/%d | KB_Domain: %d | Time: %.2fs\n', ...
                Gen, History.Acc_Elite2, History.Count_Elite2, History.Acc_Elite3, History.Count_Elite3, History.KB_DomainSize, History.TimePerGen);
    end
    
    % --- 3. 最终输出 ---
    % --- 3. 最终输出 ---
    disp('--- 算法执行完毕。---');
    
    % =======================================================
    % ★★★ 核心修改：自动创建数据集同名文件夹 ★★★
    % =======================================================
    % 1. 获取基础路径 (例如 D:\...\Results\)
    base_path = params.Output.Path;
    
    % 2. 拼接新路径 (例如 D:\...\Results\SONAR\)
    % 使用 fullfile 保证路径分隔符在不同系统下都正确
    new_folder_path = fullfile(base_path, DATASET_TO_RUN);
    
    % 3. 检查文件夹是否存在，不存在则创建
    if ~exist(new_folder_path, 'dir')
        mkdir(new_folder_path);
        disp(['  > 已创建结果文件夹: ', new_folder_path]);
    else
        disp(['  > 结果将保存至: ', new_folder_path]);
    end
    
    % 4. 关键一步：更新内存中的 params 参数
    % 加上 filesep 确保路径最后有一个斜杠 (例如 / 或 \)
    params.Output.Path = [new_folder_path, filesep];
    
    % =======================================================
    
    % *** 传入精英，调用模块化输出函数 ***
    % 传入 Global_Archive 而不是 ParetoFront
    Output_Final_Results(Global_Archive, Elite2, Elite3, Experiment_History, t_start, params, DATASET_TO_RUN);
end