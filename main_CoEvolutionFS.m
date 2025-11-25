% 文件: main_CoEvolutionFS.m

function main_CoEvolutionFS(target_dataset_name)
% MAIN_COEVOLUTIONFS 三任务协同进化特征选择算法的主控制函数。
% 强力精英注入 + 最终结果融合 + 最小化错误率输出

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
    K_Refresh = params.Knowledge.K_Refresh;
    T_Transfer = params.Knowledge.T_Transfer;
    
    ParetoFront_History = {}; 
    Elite2 = Population2(1).clone(); 
    Elite3 = Population3(1).clone();

    Experiment_History = struct('Gen', {}, 'Acc_Elite2', {}, 'Count_Elite2', {}, ...
                            'Acc_Elite3', {}, 'Count_Elite3', {}, ...
                            'Mean_Fit1', {}, 'Mean_Count1', {}, ...
                            'KB_DomainSize', {}, ...
                            'TimePerGen', {}); 
    
    disp(['--- 协同进化主循环开始，最大代数: ', num2str(MaxGen), ' ---']);
    
    for Gen = 1:MaxGen
        t_gen_start = tic; 
        disp(['[Gen ', num2str(Gen), '] ------------------------------------']);
        
        % --- 2.1 任务独立进化 ---
        
        % 任务一 (CSO 主任务)
        [Population1, ParetoFront] = CSO_Optimizer(Population1, KB, X, Y, params, fitness_funcs, Gen);

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
        
        % --- 2.3 周期性检查与知识迁移 ---
        
        % a. 知识域刷新
        if mod(Gen, K_Refresh) == 0
            F1_Domain_Mask = Elite2.FeaturesSubset & Elite3.FeaturesSubset; 
            F1_Domain_Indices = find(F1_Domain_Mask);
            if isempty(F1_Domain_Indices)
                 warning('Main:EmptyIntersectionRefresh', 'IM/SV 知识域交集为空，跳过本次刷新。');
            else
                KB = KB.refreshDomain(F1_Domain_Indices);
            end
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
    disp('--- 算法执行完毕。---');
    
    % *** 传入精英，准备输出 ***
   Output_Final_Results(ParetoFront, Elite2, Elite3, Experiment_History, t_start, params, DATASET_TO_RUN);

end

% --- 辅助输出函数 (修改版：输出分类错误率，做最小化问题) ---
% --- 辅助输出函数 (最终版：包含自动绘图与保存) ---
function Output_Final_Results(ParetoFront, Elite2, Elite3, Experiment_History, t_start, params, dataset_name)
    
    % 0. 定义文件名和路径
    timestamp = datestr(now,'yyyymmdd_HHMM');
    prefix = params.Output.NamePrefix;
    save_path = params.Output.Path;
    
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    
    % 基础文件名 (包含数据集名称)
    base_name = [dataset_name, '_', prefix]; 
    
    FileName_mat = [save_path, base_name, 'Results_', timestamp, '.mat'];
    FileName_csv = [save_path, base_name, 'History_', timestamp, '.csv'];
    
    disp(' ');
    fprintf('--- 正在融合多任务解集 [%s] ---\n', dataset_name);
    
    % =======================================================
    % 1. 融合与筛选 (最小化错误率 & 最小化特征数)
    % =======================================================
    Candidate_Pool = [ParetoFront, Elite2, Elite3];
    
    Final_Indices = [];
    for i = 1:length(Candidate_Pool)
        dominated = false;
        Sol_A = Candidate_Pool(i);
        Error_A = 1 - Sol_A.Accuracy; 
        
        for j = 1:length(Candidate_Pool)
            if i == j, continue; end
            Sol_B = Candidate_Pool(j);
            Error_B = 1 - Sol_B.Accuracy; 
            
            % 检查 B 是否支配 A
            if (Error_B <= Error_A) && (Sol_B.FeatureCount <= Sol_A.FeatureCount) && ...
               ((Error_B < Error_A) || (Sol_B.FeatureCount < Sol_A.FeatureCount))
                dominated = true;
                break;
            end
        end
        
        if ~dominated
            Final_Indices = [Final_Indices, i];
        end
    end
    
    Filtered_Solutions = Candidate_Pool(Final_Indices);
    NumSolutions = length(Filtered_Solutions);
    disp(['最终帕累托前沿 (融合后) 包含 ', num2str(NumSolutions), ' 个非支配解。']);
    
    % 转换结构体
    Final_Pareto_Solutions = struct('Acc', {}, 'Error', {}, 'Count', {}, 'Features', {});
    for i = 1:NumSolutions
        Ind = Filtered_Solutions(i);
        Final_Pareto_Solutions(i).Acc = Ind.Accuracy;
        Final_Pareto_Solutions(i).Error = 1 - Ind.Accuracy;
        Final_Pareto_Solutions(i).Count = Ind.FeatureCount;
        Final_Pareto_Solutions(i).Features = Ind.FeaturesSubset;
    end

    % =======================================================
    % 2. 文本输出与记录
    % =======================================================
    if ~isempty(Final_Pareto_Solutions)
        all_counts = [Final_Pareto_Solutions.Count];
        [~, min_count_idx] = min(all_counts);
        Best_Comp_Solution = Final_Pareto_Solutions(min_count_idx);
        
        all_errors = [Final_Pareto_Solutions.Error];
        [~, min_err_idx] = min(all_errors);
        Best_Perf_Solution = Final_Pareto_Solutions(min_err_idx);
        
        Total_Gen = length(Experiment_History);
        Total_Time_Sec = etime(clock, t_start); 
        
        History_Table = struct2table(Experiment_History);
        writetable(History_Table, FileName_csv);
        
        output_str = sprintf('\n========================================\n');
        output_str = [output_str, sprintf(' 运行结果摘要: %s\n', dataset_name)];
        output_str = [output_str, sprintf('========================================\n')];
        output_str = [output_str, sprintf('KFold=%d, Gen=%d\n', params.Evaluation.KFold, Total_Gen)];
        output_str = [output_str, sprintf('总运行时间: %.2f 秒\n', Total_Time_Sec)];
        output_str = [output_str, sprintf('\n--- 最佳解 (最小化问题) ---\n')];
        output_str = [output_str, sprintf('[最低错误率] 特征数: %d, 错误率: %.4f (精度: %.4f)\n', ...
            Best_Perf_Solution.Count, Best_Perf_Solution.Error, Best_Perf_Solution.Acc)];
        output_str = [output_str, sprintf('[最佳压缩率] 特征数: %d, 错误率: %.4f (精度: %.4f)\n', ...
            Best_Comp_Solution.Count, Best_Comp_Solution.Error, Best_Comp_Solution.Acc)];
        
        disp(output_str);
        
        txt_filename = [save_path, base_name, 'Summary_', timestamp, '.txt'];
        fid = fopen(txt_filename, 'w');
        fprintf(fid, '%s', output_str);
        fclose(fid);
        
        % =======================================================
        % 3. ★★★ 自动绘图并保存 (Auto Plotting) ★★★
        % =======================================================
        disp('正在生成并保存结果图...');
        
        % --- 图1: 帕累托前沿 (Pareto Front) ---
        % 'Visible', 'off' 保证后台运行不弹窗，适合批量跑
        fig1 = figure('Visible', 'off'); 
        scatter(all_counts, all_errors, 80, 'filled', 'MarkerFaceColor', [0.85 0.32 0.09]);
        
        xlabel('Number of Selected Features'); 
        ylabel('Classification Error Rate');
        title(['Pareto Front - ', dataset_name]);
        grid on;
        
        % 保存为 PNG 和 FIG (方便后续修改)
        saveas(fig1, [save_path, base_name, 'Pareto.png']);
        savefig(fig1, [save_path, base_name, 'Pareto.fig']);
        close(fig1); % 关闭图形释放内存
        
        % --- 图2: 收敛曲线 (Convergence) ---
        fig2 = figure('Visible', 'off');
        
        % 提取数据
        history_error = 1 - [Experiment_History.Acc_Elite2]; % Task 2 最佳错误率
        history_feat = [Experiment_History.Mean_Count1];     % Task 1 平均特征数
        
        yyaxis left
        plot(1:length(history_error), history_error, '-o', 'LineWidth', 1.5);
        ylabel('Best Error Rate (Task 2)');
        
        yyaxis right
        plot(1:length(history_feat), history_feat, '--', 'LineWidth', 1.5);
        ylabel('Avg Feature Count (Task 1)');
        
        xlabel('Generation');
        title(['Convergence Curve - ', dataset_name]);
        legend({'Best Error', 'Avg Features'}, 'Location', 'best');
        grid on;
        
        saveas(fig2, [save_path, base_name, 'Convergence.png']);
        savefig(fig2, [save_path, base_name, 'Convergence.fig']);
        close(fig2);
        
        disp(['图片已保存至: ', save_path]);
    end
    
    save(FileName_mat, 'Final_Pareto_Solutions', 'Experiment_History', 'ParetoFront', 'params', 't_start', 'dataset_name');
    disp(['MATLAB 数据已保存: ', FileName_mat]);
    disp(' ');
end