% 文件: main_CoEvolutionFS.m
function main_CoEvolutionFS(target_dataset_name, params_override)
% MAIN_COEVOLUTIONFS 三任务协同进化特征选择算法的主控制函数。
% 包含：强力精英注入 + 最终结果融合 + 断层填充局部搜索(GFLS) + 参数同步策略
% [已修改] 支持消融实验控制 (单任务/无断层填充)

    t_start = clock; 

    % Make the project self-contained when launched directly from MATLAB
    % batch mode instead of through the .prj project file.
    project_root = fileparts(mfilename('fullpath'));
    addpath(genpath(project_root));
    
    % --- 1. 初始化和配置 ---
    if ~exist('params', 'var')
        run('config_parameters.m');
    end
    if nargin >= 2 && ~isempty(params_override)
        params = params_override;
    end
    
    % 接收外部参数
    if nargin < 1
        DATASET_TO_RUN = 'SONAR'; 
    else
        DATASET_TO_RUN = target_dataset_name;
    end
    
    fprintf('>>> 正在启动任务，当前数据集: %s <<<\n', DATASET_TO_RUN);

    % 数据根目录。服务器上使用 params.Data.BaseDir = 'C:\data'。
    % 本机如果没有 C:\data，则自动回退到旧的数据路径，方便调试。
    if isfield(params, 'Data') && isfield(params.Data, 'BaseDir')
        DATA_ROOT = params.Data.BaseDir;
    else
        DATA_ROOT = 'C:\data';
    end
    if ~exist(DATA_ROOT, 'dir') && exist('D:\learn\yjs\paper\data', 'dir')
        DATA_ROOT = 'D:\learn\yjs\paper\data';
    end
    
    % =======================================================
    % ★★★ 数据集路径配置 (含通用入口) ★★★
    % =======================================================
    if strcmp(DATASET_TO_RUN, 'SECOM')
        disp('  > 正在加载 SECOM 数据集 (N=1567, D=590)...');
        DATA_PATH   = fullfile(DATA_ROOT, 'secom', 'secom.data'); 
        LABELS_PATH = fullfile(DATA_ROOT, 'secom', 'secom_labels.data');
        [X, Y, ~] = data_loader(DATA_PATH, LABELS_PATH, DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'SPECTF')
        disp('  > 正在加载 SPECTF Heart 数据集 (N=267, D=22)...');
        TRAIN_PATH = fullfile(DATA_ROOT, 'spect+heart', 'SPECT.train');  
        TEST_PATH  = fullfile(DATA_ROOT, 'spect+heart', 'SPECT.test');   
        [X, Y, ~] = data_loader(TRAIN_PATH, TEST_PATH, DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'SONAR')
        disp(' > 正在加载 SONAR 数据集 (N=208, D=60)...');
        DATA_PATH = fullfile(DATA_ROOT, 'sonar', 'sonar.all-data'); 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);

    elseif strcmp(DATASET_TO_RUN, 'Gait')
        disp(' > 正在加载 Gait Classification 数据集...');
        DATA_PATH = fullfile(DATA_ROOT, 'gait+classification', 'PersonGaitDataSet.mat'); 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
 
    elseif strcmp(DATASET_TO_RUN, 'Madelon')
        disp(' > 正在加载 Madelon 数据集 (N=2000, D=500)...');
        DATA_PATH = fullfile(DATA_ROOT, 'madelon', 'MADELON', 'madelon_train.data'); 
        LABELS_PATH = fullfile(DATA_ROOT, 'madelon', 'MADELON', 'madelon_train.labels');
        [X, Y, ~] = data_loader(DATA_PATH, LABELS_PATH, DATASET_TO_RUN);
        
     elseif strcmp(DATASET_TO_RUN, 'Period_Changer')
        disp(' > 正在加载 Period Changer 数据集 (N=90, D=1177)...');
        DATA_PATH = fullfile(DATA_ROOT, 'period+changer-2', 'data.csv'); 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
      elseif strcmp(DATASET_TO_RUN, 'Toxicity')
        disp(' > 正在加载 Toxicity 数据集 (N=171, D=1203)...');     
        DATA_PATH = fullfile(DATA_ROOT, 'toxicity', 'data.csv'); 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
       elseif strcmp(DATASET_TO_RUN, 'Micro_Mass')
        disp(' > 正在加载 Micro-Mass (Pure Spectra) 数据集...');
        DATA_PATH = fullfile(DATA_ROOT, 'micromass', 'pure_spectra_matrix.csv'); 
        LABELS_PATH = fullfile(DATA_ROOT, 'micromass', 'pure_spectra_metadata.csv');
        [X, Y, ~] = data_loader(DATA_PATH, LABELS_PATH, DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'Internet_Ads')
        disp(' > 正在加载 Internet Advertisements 数据集 (N=3279, D=1558)...');
        DATA_PATH = fullfile(DATA_ROOT, 'internet+advertisements', 'ad.data'); 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'Colon')
        disp(' > 正在加载 Colon Tumor 数据集 (N=62, D=2000)...');
        DATA_PATH = fullfile(DATA_ROOT, 'colon.mat'); 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'Lung_Cancer')
        disp(' > 正在加载 Lung Cancer 数据集 (N=203, D=3312)...');
        DATA_PATH = fullfile(DATA_ROOT, 'lung.mat'); 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'Gisette')
        disp(' > 正在加载 Gisette 数据集 (Train Set, N=6000, D=5000)...');
        DATA_PATH = fullfile(DATA_ROOT, 'gisette', 'gisette_train.data'); 
        LABELS_PATH = fullfile(DATA_ROOT, 'gisette', 'gisette_train.labels');
        [X, Y, ~] = data_loader(DATA_PATH, LABELS_PATH, DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'Leukemia')
        disp(' > 正在加载 Leukemia 数据集 (N=72, D=7070)...');
        DATA_PATH = fullfile(DATA_ROOT, 'leukemia.mat'); 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'Musk')
        disp(' > 正在加载 Musk (Version 2) 数据集 (N=6598, D=166)...');
        DATA_PATH = fullfile(DATA_ROOT, 'musk+version+2', 'clean2.data'); 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'LSVT')
        disp(' > 正在加载 LSVT Voice Rehabilitation 数据集 (N=126, D=309)...');
        DATA_PATH = fullfile(DATA_ROOT, 'lsvt+voice+rehabilitation', 'LSVT_voice_rehabilitation.xlsx'); 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'Arrhythmia')
        disp(' > 正在加载 Arrhythmia 数据集 (N=452, D=279)...');
        DATA_PATH = fullfile(DATA_ROOT, 'arrhythmia', 'arrhythmia.data'); 
        [X, Y, ~] = data_loader(DATA_PATH, '', DATASET_TO_RUN);
    
    % =========================================================================
    % ★★★ 新增：Github/ASU 通用入口 (适配那 6 个新数据) ★★★
    % =========================================================================
    elseif ismember(DATASET_TO_RUN, {'BASEHOCK', 'RELATHE', 'PCMAC', 'warpPIE10P', 'TOX-171', 'ISOLET', ...
                                     'GLIOMA', 'CLL_SUB_111', 'ORL', 'COIL20'})
        disp([' > 正在加载通用数据集: ', DATASET_TO_RUN, ' ...']);
        
        % 使用绝对路径，确保最稳妥
        base_dir = DATA_ROOT; 
        DATA_PATH = fullfile(base_dir, [DATASET_TO_RUN, '.mat']); 
        
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
    
    % =======================================================
    % ★★★ 修复：类型转换 (Categorical -> Double) ★★★
    % =======================================================
    disp('  > 正在计算初始特征重要性 (LGBM & Relief-F)...');
    Y_num = double(Y); 
    W_LGBM = getLGBMImportance(X, Y_num);
    W_ReliefF = getReliefFImportance(X, Y_num);
    % =======================================================
    
    % 1.5 初始化种群
    disp('  > 正在初始化 Task 1 (主任务) 种群...');
    [Pop1_init, ~, ~] = initialFeatureSelection(X, Y, W_LGBM, params, @evaluateSubset, 1);
    Population1 = Pop1_init;

    % Normalize ablation switches. Older configs only have Enable_MultiTask,
    % so the fine-grained switches default to true for backward compatibility.
    if ~isfield(params, 'Ablation')
        params.Ablation.Enable_MultiTask = true;
    end
    if ~isfield(params.Ablation, 'Enable_Task2')
        params.Ablation.Enable_Task2 = true;
    end
    if ~isfield(params.Ablation, 'Enable_Task3')
        params.Ablation.Enable_Task3 = true;
    end
    Enable_Task2 = params.Ablation.Enable_MultiTask && params.Ablation.Enable_Task2;
    Enable_Task3 = params.Ablation.Enable_MultiTask && params.Ablation.Enable_Task3;
    Enable_AnyAux = Enable_Task2 || Enable_Task3;
    
    % =======================================================
    % ★★★ 核心修改：多任务/单任务模式切换 ★★★
    % =======================================================
    if Enable_AnyAux
        disp('  > [Mode: auxiliary ablation] Initializing enabled auxiliary tasks and knowledge base...');
        Population2 = [];
        Population3 = [];
        F2_domain = [];
        F3_domain = [];
        Elite2 = [];
        Elite3 = [];

        if Enable_Task2
            disp('    - Task 2 enabled: accuracy-oriented auxiliary task.');
            [Pop2_init, ~, F2_domain] = initialFeatureSelection(X, Y, W_LGBM, params, @evaluateSubset, 2);
            Population2 = Pop2_init;
            for ind = Population2
                ind.evaluate(X, Y, fitness_funcs, params);
            end
            [~, best2_idx] = max([Population2.Fitness]);
            Elite2 = Population2(best2_idx).clone();
        end

        if Enable_Task3
            disp('    - Task 3 enabled: compactness-oriented auxiliary task.');
            [Pop3_init, ~, F3_domain] = initialFeatureSelection(X, Y, W_ReliefF, params, @evaluateSubset, 3);
            Population3 = Pop3_init;
            for ind = Population3
                ind.evaluate(X, Y, fitness_funcs, params);
            end
            [~, best3_idx] = max([Population3.Fitness]);
            Elite3 = Population3(best3_idx).clone();
        end

        % Seed the knowledge base with domains from the enabled auxiliary tasks.
        Initial_Domain_Indices = union(F2_domain, F3_domain);
        if isempty(Initial_Domain_Indices)
            Initial_Domain_Indices = 1:D_total;
        end
        KB = KnowledgeBase(D_total, Initial_Domain_Indices, params.Knowledge.IM_SV_InitValue);
    else
        disp('  > [Mode: single-task CSO] Skipping auxiliary tasks and knowledge base.');
        Population2 = [];
        Population3 = [];
        KB = [];
        Elite2 = [];
        Elite3 = [];
    end
    % =======================================================
    
    % --- 2. 协同进化主循环 ---
    
    MaxGen = params.MaxGenerations;
    
    % 参数同步耦合策略
    Interaction_Period = 20; 
    K_Refresh = Interaction_Period;
    T_Transfer = Interaction_Period;
    disp(['  > [参数策略] 交互周期已同步设定为: ', num2str(Interaction_Period), ' 代。']);
    
    ParetoFront_History = {}; 
    
    Experiment_History = struct('Gen', {}, 'Acc_Elite2', {}, 'Count_Elite2', {}, ...
                            'Acc_Elite3', {}, 'Count_Elite3', {}, ...
                            'Mean_Fit1', {}, 'Mean_Count1', {}, ...
                            'KB_DomainSize', {}, ...
                            'TimePerGen', {}); 
    
    % 初始化全局归档 (Global Archive)
    Global_Archive = []; 
    
    disp(['--- 进化主循环开始，最大代数: ', num2str(MaxGen), ' ---']);
    
    for Gen = 1:MaxGen
        t_gen_start = tic; 
        
        % --- 2.1 任务独立进化 ---
        
        % 任务一 (CSO 主任务)
        [Population1, ParetoFront] = CSO_Optimizer(Population1, KB, X, Y, params, fitness_funcs, Gen);
        
        % =======================================================
        % ★★★ 核心修改：断层填充策略 (可开关) ★★★
        % =======================================================
        CurrentPF = ParetoFront; 
        
        if params.Ablation.Enable_GapFilling
            % disp('  > [GFLS] 执行断层填充策略...');
            if length(CurrentPF) > 1
                [~, idx_pf] = sort([CurrentPF.FeatureCount]);
                SortedPF = CurrentPF(idx_pf);
                
                for k_gap = 1:length(SortedPF)-1
                    Sol_Small = SortedPF(k_gap);
                    Sol_Large = SortedPF(k_gap+1);
                    diff_count = Sol_Large.FeatureCount - Sol_Small.FeatureCount;
                    gap_threshold = max(2, ceil(D_total * 0.03)); 
                    
                    if diff_count > gap_threshold
                        diff_mask = Sol_Large.FeaturesSubset & (~Sol_Small.FeaturesSubset);
                        diff_indices = find(diff_mask);
                        
                        if ~isempty(diff_indices)
                            diff_scores = W_LGBM(diff_indices);
                            [~, score_sort_idx] = sort(diff_scores, 'descend');
                            sorted_diff_indices = diff_indices(score_sort_idx);
                            
                            attempts = 10;
                            for try_i = 1:attempts
                                num_to_add = randi([1, max(1, length(diff_indices)-1)]);
                                
                                if rand() < 0.7 
                                    features_to_add = sorted_diff_indices(1:num_to_add);
                                else
                                    perm_idx = randperm(length(diff_indices), num_to_add);
                                    features_to_add = diff_indices(perm_idx);
                                end
                                
                                NewGapMask = Sol_Small.FeaturesSubset;
                                NewGapMask(features_to_add) = true;
                                
                                if rand() < 0.2
                                    mutate_pos = randi(D_total);
                                    NewGapMask(mutate_pos) = ~NewGapMask(mutate_pos);
                                end
                                
                                TempInd = Individual(NewGapMask, 1);
                                TempInd.evaluate(X, Y, fitness_funcs, params);
                                
                                [~, sorted_fit_idx] = sort([Population1.Fitness]);
                                replace_range = sorted_fit_idx(1:max(1, round(params.PopSize * 0.1)));
                                replace_target = replace_range(randi(length(replace_range)));
                                Population1(replace_target) = TempInd;
                                
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
        else
            % disp('  > [消融] 跳过断层填充策略。');
        end
        % =======================================================
        
        % 将当代 ParetoFront (含修复解) 加入全局归档
        Current_Pareto_Clones = Individual.empty(0, length(CurrentPF));
        for k = 1:length(CurrentPF)
            Current_Pareto_Clones(k) = CurrentPF(k).clone();
        end
        
        if isempty(Global_Archive)
            Global_Archive = Current_Pareto_Clones;
        else
            Global_Archive = [Global_Archive, Current_Pareto_Clones];
        end
        
        % =======================================================
        % ★★★ 核心修改：辅助任务与协同进化 (可开关) ★★★
        % =======================================================
        if Enable_AnyAux
            % Evolve only the enabled auxiliary task(s). This supports the two
            % ablation modes: CSO+Task2 and CSO+Task3.
            if Enable_Task2
                [Population2, Elite2] = EDA_Optimizer(Population2, KB, X, Y, params, fitness_funcs, 2);
            end
            if Enable_Task3
                [Population3, Elite3] = EDA_Optimizer(Population3, KB, X, Y, params, fitness_funcs, 3);
            end

            % Inject the best available auxiliary elite into weak CSO individuals.
            % Full mode keeps the original behavior by preferring Task 2 elite;
            % Task3-only mode injects the Task 3 elite instead.
            InjectionElite = [];
            if Enable_Task2 && ~isempty(Elite2)
                InjectionElite = Elite2;
            elseif Enable_Task3 && ~isempty(Elite3)
                InjectionElite = Elite3;
            end

            if ~isempty(InjectionElite)
                [~, sorted_idx] = sort([Population1.Fitness]);
                inject_count = min(3, length(sorted_idx));
                worst_indices = sorted_idx(1:inject_count);
                for k = 1:inject_count
                    New_Individual = InjectionElite.clone();
                    if k > 1
                        mutation_idx = randi(length(New_Individual.FeaturesSubset), 1, randi(2));
                        New_Individual.FeaturesSubset(mutation_idx) = ~New_Individual.FeaturesSubset(mutation_idx);
                    end
                    New_Individual.TaskID = 1;
                    New_Individual.evaluate(X, Y, fitness_funcs, params);
                    Population1(worst_indices(k)) = New_Individual;
                end
            end

            % Knowledge update. Full mode uses the original two-auxiliary-task
            % competition. Single-auxiliary ablations strengthen the enabled
            % auxiliary elite's selected features, producing a clean one-helper
            % signal for CSO without introducing the missing auxiliary objective.
            if Enable_Task2 && Enable_Task3
                KB = updateIM_SV(KB, Elite2, Elite3, params);
            elseif Enable_Task2
                KB = updateKBFromSingleAux(KB, Elite2, params);
            elseif Enable_Task3
                KB = updateKBFromSingleAux(KB, Elite3, params);
            end

            % Periodic domain refresh and main-to-auxiliary transfer.
            if mod(Gen, K_Refresh) == 0
                if Enable_Task2 && Enable_Task3
                    KB = triggerDomainRefresh(KB, Elite2, Elite3);
                elseif Enable_Task2
                    KB = refreshKBFromSingleAux(KB, Elite2);
                elseif Enable_Task3
                    KB = refreshKBFromSingleAux(KB, Elite3);
                end
            end
            if mod(Gen, T_Transfer) == 0
                if Enable_Task2 && Enable_Task3
                    [Population2, Population3] = transferMainToAux(ParetoFront, Population2, Population3);
                elseif Enable_Task2
                    Population2 = transferMainToSingleAux(ParetoFront, Population2, 'Precision');
                elseif Enable_Task3
                    Population3 = transferMainToSingleAux(ParetoFront, Population3, 'Compactness');
                end
            end

            if Enable_Task2 && ~isempty(Elite2)
                History.Acc_Elite2 = Elite2.Accuracy;
                History.Count_Elite2 = Elite2.FeatureCount;
            else
                History.Acc_Elite2 = NaN;
                History.Count_Elite2 = NaN;
            end
            if Enable_Task3 && ~isempty(Elite3)
                History.Acc_Elite3 = Elite3.Accuracy;
                History.Count_Elite3 = Elite3.FeatureCount;
            else
                History.Acc_Elite3 = NaN;
                History.Count_Elite3 = NaN;
            end
            History.KB_DomainSize = KB.DomainSize;
        else
            % [修复] 单任务模式下，提取 Task 1 的最佳指标用于记录
            % 这样绘图函数才能画出 Task 1 的收敛过程，而不是直线
            
            % 1. 寻找 Task 1 中“精度最高”的个体 (模拟 Elite2)
            [~, best_acc_idx] = max([Population1.Accuracy]);
            BestAccP1 = Population1(best_acc_idx);
            
            History.Acc_Elite2 = BestAccP1.Accuracy;     % 存入 Task 1 的最高精度
            History.Count_Elite2 = BestAccP1.FeatureCount;
            
            % 2. 寻找 Task 1 中“特征最少”的个体 (模拟 Elite3)
            % (如果想简单点，也可以直接都存 BestAccP1 的数据)
            [~, min_feat_idx] = min([Population1.FeatureCount]);
            CompactP1 = Population1(min_feat_idx);
            
            History.Acc_Elite3 = CompactP1.Accuracy;
            History.Count_Elite3 = CompactP1.FeatureCount;
            
            History.KB_DomainSize = 0; % 单任务无知识域，保持 0
        end
        % =======================================================
        
        % --- 2.4 记录与监控 ---
        ParetoFront_History{Gen} = ParetoFront; %#ok<AGROW>
        
        TimePerGen = toc(t_gen_start); 
        History.Gen = Gen;
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
    disp('--- 算法执行完毕。---');
    
    % =======================================================
    % ★★★ 核心修改：自动创建带后缀的结果文件夹 ★★★
    % =======================================================
    base_path = params.Output.Path;
    
    % 根据模式添加后缀，区分不同实验。
    if ~Enable_AnyAux
        suffix = '_SingleTask';
    elseif Enable_Task2 && ~Enable_Task3
        suffix = '_CSO_Task2';
    elseif ~Enable_Task2 && Enable_Task3
        suffix = '_CSO_Task3';
    elseif ~params.Ablation.Enable_GapFilling
        suffix = '_NoGapFill';
    else
        suffix = '_Full';
    end
    
    new_folder_path = fullfile(base_path, [DATASET_TO_RUN, suffix]);
    
    if ~exist(new_folder_path, 'dir')
        mkdir(new_folder_path);
        disp(['  > 已创建结果文件夹: ', new_folder_path]);
    else
        disp(['  > 结果将保存至: ', new_folder_path]);
    end
    params.Output.Path = [new_folder_path, filesep];
    
    Output_Final_Results(Global_Archive, Elite2, Elite3, Experiment_History, t_start, params, DATASET_TO_RUN);
end

function KB = updateKBFromSingleAux(KB, EliteAux, params)
% updateKBFromSingleAux updates the knowledge base for CSO+single-auxiliary
% ablations. With only one auxiliary task, there is no second auxiliary elite
% to act as a loser, so the selected features of the enabled auxiliary elite
% are strengthened directly in SV. IM is left unchanged because pairwise
% winner/loser contrast is not available in this ablation.
    if isempty(KB) || isempty(EliteAux)
        return;
    end

    Delta = params.LearningRate.ChangeFactor;
    Init_Value = params.Knowledge.IM_SV_InitValue;
    domain_indices = KB.FeatureDomainIndices;
    elite_mask = EliteAux.FeaturesSubset(domain_indices);

    if isempty(elite_mask)
        return;
    end

    KB.SV(elite_mask) = KB.SV(elite_mask) + Delta;
    KB.SV(~elite_mask) = max(KB.SV(~elite_mask) - 0.5 * Delta, Init_Value);
end

function KB = refreshKBFromSingleAux(KB, EliteAux)
% refreshKBFromSingleAux refreshes the knowledge domain from the enabled
% auxiliary task alone. If the elite subset is unexpectedly empty, the old
% domain is kept to avoid losing all guidance.
    if isempty(KB) || isempty(EliteAux)
        return;
    end

    new_domain = find(EliteAux.FeaturesSubset);
    if isempty(new_domain)
        new_domain = KB.FeatureDomainIndices;
    end
    KB = KB.refreshDomain(new_domain);
end

function Population = transferMainToSingleAux(ParetoFront, Population, goal)
% transferMainToSingleAux transfers one guiding solution from the CSO Pareto
% front to the enabled auxiliary task. It is the single-task counterpart of
% transferMainToAux and keeps the same Precision/Compactness criteria.
    if isempty(ParetoFront) || isempty(Population)
        return;
    end

    all_fitness = [Population.Fitness];
    [~, elite_idx] = max(all_fitness);
    EliteAux = Population(elite_idx);

    BestGuide = [];
    MinDistance = inf;
    for k = 1:length(ParetoFront)
        Guide = ParetoFront(k);
        hamming_distance = sum(EliteAux.FeaturesSubset ~= Guide.FeaturesSubset);

        is_superior = false;
        if strcmp(goal, 'Precision')
            is_superior = Guide.Accuracy > EliteAux.Accuracy;
        elseif strcmp(goal, 'Compactness')
            is_superior = Guide.FeatureCount < EliteAux.FeatureCount;
        end

        if is_superior && hamming_distance < MinDistance
            MinDistance = hamming_distance;
            BestGuide = Guide;
        end
    end

    if ~isempty(BestGuide)
        [~, loser_idx] = min(all_fitness);
        GuidedIndividual = BestGuide.clone();
        GuidedIndividual.TaskID = EliteAux.TaskID;
        Population(loser_idx) = GuidedIndividual;
    end
end
