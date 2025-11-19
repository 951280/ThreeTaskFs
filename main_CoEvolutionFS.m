% 文件: main_CoEvolutionFS.m

function main_CoEvolutionFS()
% MAIN_COEVOLUTIONFS 三任务协同进化特征选择算法的主控制函数。
    t_start = clock; % <--- 新增: 记录算法开始时间
    % --- 1. 初始化和配置 ---
    
    % 1.1 加载配置参数 (确保 config_parameters.m 已运行或参数已加载)
    if ~exist('params', 'var')
        run('config_parameters.m');
    end
    
    % --- 数据集切换配置 (只需修改这一个标志) ---
    DATASET_TO_RUN = 'SPECTF'; % 可选值: 'SECOM' 或 'SPECTF'
    
    if strcmp(DATASET_TO_RUN, 'SECOM')
        % --- SECOM 配置 (原始大样本) ---
        disp('  > 正在加载 SECOM 数据集 (N=1567, D=590)...');
        % ***************************************************************
        % *** SECOM 文件路径 ***
        DATA_PATH   = 'D:\code\ThreeTaskFs\data\secom\secom.data'; 
        LABELS_PATH = 'D:\code\ThreeTaskFs\data\secom\secom_labels.data';
        % ***************************************************************
        
        % 注意: data_loader 在 SECOM 模式下需要两个路径
        [X, Y, ~] = data_loader(DATA_PATH, LABELS_PATH, DATASET_TO_RUN);
        
    elseif strcmp(DATASET_TO_RUN, 'SPECTF')
        % --- SPECTF 配置 (小样本调试) ---
        disp('  > 正在加载 SPECTF Heart 数据集 (N=267, D=22)...');
        % ***************************************************************
        % *** SPECTF 文件路径 ***
        TRAIN_PATH = 'D:\code\ThreeTaskFs\data\spect+heart\SPECT.train';  
        TEST_PATH  = 'D:\code\ThreeTaskFs\data\spect+heart\SPECT.test';   
        % ***************************************************************
        
        % 注意: data_loader 在 SPECTF 模式下需要两个路径 (训练集和测试集)
        [X, Y, ~] = data_loader(TRAIN_PATH, TEST_PATH, DATASET_TO_RUN);
    
    else
        error('main_CoEvolutionFS:InvalidDataset', '请设置 DATASET_TO_RUN 为有效的配置名称。');
    end
    
    
    % ====================================================================
    % 1.2.1. 抽取小规模子集 (加速调试)
    % ====================================================================
    % 确保 params.Debug.Enable 在 config_parameters.m 中被定义
    if isfield(params, 'Debug') && params.Debug.Enable
        subset_ratio = params.Debug.Subset_Ratio;
        
        disp('------------------------------------------------');
        fprintf('  DEBUG MODE: 已启用子集抽样 (Ratio: %.2f)\n', subset_ratio);
        
        try
            % 使用分层抽样 (Stratified Sampling)
            cv = cvpartition(Y, 'Holdout', 1 - subset_ratio); 
        catch ME
            % 回退到非分层抽样
            warning('Main:CVPartitionFailed', ...
                '无法进行分层抽样: %s。尝试非分层抽样。', ME.message);
            N = size(X, 1);
            cv = cvpartition(N, 'Holdout', 1 - subset_ratio); 
        end
        
        % 获取抽样后的索引
        subset_indices = training(cv); 
        
        % 更新数据为子集
        X = X(subset_indices, :);
        Y = Y(subset_indices, :);
        
        % 显示更新后的维度
        N_subset = size(X, 1);
        D_total_after_subset = size(X, 2);
        fprintf('  数据维度已更新: 样本数 N=%d, 特征数 D=%d\n', N_subset, D_total_after_subset);
        disp('------------------------------------------------');
    end
    % ====================================================================
    
    D_total = size(X, 2);
    
    % 1.3 初始化函数句柄 (用于评估)
    fitness_funcs.f1 = @f1_fitness;
    fitness_funcs.f2 = @f2_fitness;
    fitness_funcs.f3 = @f3_fitness;

    % 1.4 初始特征重要性计算 (用于初始化种群和知识库域)
    disp('  > 正在计算初始特征重要性 (LGBM & Relief-F)...');
    W_LGBM = getLGBMImportance(X, Y);
    W_ReliefF = getReliefFImportance(X, Y);
    
    % 1.5 初始化种群 (个体需要 D_total 维度来初始化 Position/Velocity)
    disp('  > 正在初始化三任务种群...');
    % Pop1 (CSO) 使用 LGBM 的重要性 W 作为 Position 的初始化参考
    [Pop1_init, ~, ~] = initialFeatureSelection(X, Y, W_LGBM, params, @evaluateSubset, 1);
    % Pop2 (EDA) 使用 LGBM 的重要性 W 
    [Pop2_init, ~, F2_domain] = initialFeatureSelection(X, Y, W_LGBM, params, @evaluateSubset, 2); 
    % Pop3 (EDA) 使用 ReliefF 的重要性 W 
    [Pop3_init, ~, F3_domain] = initialFeatureSelection(X, Y, W_ReliefF, params, @evaluateSubset, 3);
    
    Population1 = Pop1_init;
    Population2 = Pop2_init;
    Population3 = Pop3_init;
    
    % 1.6 初始化知识库 (KB) - 使用并集 F2 U F3 (符合高维特征集初始探索的策略)
    % F2_domain 和 F3_domain 已经是特征索引向量
    Initial_Domain_Indices = union(F2_domain, F3_domain); % <--- 初始化改为并集
    KB = KnowledgeBase(D_total, Initial_Domain_Indices, params.Knowledge.IM_SV_InitValue);
    
    % 1.7 初始评估 (Pop2 和 Pop3 的 Position/Velocity 不用于第一次评估)
    disp('  > 正在执行初始种群评估...');
    for ind = Population2
        ind.evaluate(X, Y, fitness_funcs, params);
    end
    for ind = Population3
        ind.evaluate(X, Y, fitness_funcs, params);
    end
    % Pop1 的评估在 CSO_Optimizer 内部完成
    
    % --- 2. 协同进化主循环 ---
    
    MaxGen = params.MaxGenerations;
    K_Refresh = params.Knowledge.K_Refresh;
    T_Transfer = params.Knowledge.T_Transfer;
    
    ParetoFront_History = {}; % 存储每代的 F1，用于停止条件检查
    Elite2 = Population2(1).clone(); % 初始化 Elite2/3
    Elite3 = Population3(1).clone();

    % *** 初始化实验历史记录结构体 (用于实验数据记录) ***
    Experiment_History = struct('Gen', {}, 'Acc_Elite2', {}, 'Count_Elite2', {}, ...
                            'Acc_Elite3', {}, 'Count_Elite3', {}, ...
                            'Mean_Fit1', {}, 'Mean_Count1', {}, ...
                            'KB_DomainSize', {}, ...
                            'TimePerGen', {}); 
    
    disp(['--- 协同进化主循环开始，最大代数: ', num2str(MaxGen), ' ---']);
    
    for Gen = 1:MaxGen
        t_gen_start = tic; % 记录本代开始时间
        disp(['[Gen ', num2str(Gen), '] ------------------------------------']);
        
        % --- 2.1 任务独立进化 ---
        
        % 任务一 (CSO 主任务: 多目标)
        [Population1, ParetoFront] = CSO_Optimizer(Population1, KB, X, Y, params, fitness_funcs, Gen);

        % 任务二/三 (EDA 辅助任务: 单目标)
        [Population2, Elite2] = EDA_Optimizer(Population2, KB, X, Y, params, fitness_funcs, 2);
        [Population3, Elite3] = EDA_Optimizer(Population3, KB, X, Y, params, fitness_funcs, 3);

        % --- 2.2 知识更新 (学习) ---

        % 更新共享 IM/SV 知识库 (使用任务二/三的 Elite 竞争结果)
        KB = updateIM_SV(KB, Elite2, Elite3, params);
        
        % --- 2.3 周期性检查与知识迁移 ---
        
        % a. 知识域刷新 (每 K 代)
        if mod(Gen, K_Refresh) == 0
            % 计算新的知识域 F1_Domain (只保留 Elite2.S 和 Elite3.S 的交集)
            % 目的: 强制知识域收缩，聚焦于被两个任务共同认可的特征子空间 (高维数据优化)
            F1_Domain_Mask = Elite2.FeaturesSubset & Elite3.FeaturesSubset; % <--- 刷新改为交集
            F1_Domain_Indices = find(F1_Domain_Mask);
            
            % 检查交集是否为空，如果为空则避免域清空导致崩溃
            if isempty(F1_Domain_Indices)
                 warning('Main:EmptyIntersectionRefresh', 'IM/SV 知识域交集为空，跳过本次刷新。');
            else
                KB = KB.refreshDomain(F1_Domain_Indices);
            end
        end

        % b. 知识迁移策略 (每 T 代)
        if mod(Gen, T_Transfer) == 0 
            
            % b.1 辅助任务 -> 主任务迁移 (IM/SV 引导 CSO)
            % P_KB 在 CSO_Optimizer 内部被 GenerateKnowledgeVector 获取/隐式调用
            % transferAuxToMain(KB, Population1, params); % 此函数仅生成 P_KB，CSO_Optimizer 已直接调用

            % b.2 主任务 -> 辅助任务迁移 (F1 指导 EDA)
            [Population2, Population3] = transferMainToAux(ParetoFront, Population2, Population3);
        end


        % --- 2.4 停止条件检查 ---
        ParetoFront_History{Gen} = ParetoFront; %#ok<AGROW>
        
        % (此处省略 StopCondition_is_met 的详细实现，该函数检查 ParetoFront_History)
        % IF StopCondition_is_met(ParetoFront_History, params.StopPatience):
        %     disp('--- 停止条件触发，进化停止。---');
        %     break

        
        % ******************************************************************
        % *** 实验数据记录和实时打印 ***
        % ******************************************************************
        TimePerGen = toc(t_gen_start); % 计算本代耗时
        History.Gen = Gen;
        History.Acc_Elite2 = Elite2.Accuracy;
        History.Count_Elite2 = Elite2.FeatureCount;
        History.Acc_Elite3 = Elite3.Accuracy;
        History.Count_Elite3 = Elite3.FeatureCount;
        History.KB_DomainSize = KB.DomainSize;
        History.TimePerGen = TimePerGen; % <将本代时间加入 History 结构体

        % 计算 Task 1 种群的平均值
        P1_Features = [Population1.FeatureCount];
        P1_Fitness = [Population1.Fitness];
        History.Mean_Fit1 = mean(P1_Fitness);
        History.Mean_Count1 = mean(P1_Features);

        % 将记录追加到历史结构体
        Experiment_History(Gen) = History;
        
        % 打印关键 Elite 性能（实时监控）
        fprintf('[Gen %d] E2(A/C): %.4f/%d | E3(A/C): %.4f/%d | KB_Domain: %d | Time: %.2fs\n', ... % 打印每代时间
                Gen, History.Acc_Elite2, History.Count_Elite2, History.Acc_Elite3, History.Count_Elite3, History.KB_DomainSize, History.TimePerGen);
        % ******************************************************************

        
    end
    
    % --- 3. 最终输出 ---
    
    disp('--- 算法执行完毕。---');
    
    % *** 最终输出和保存 ***
    Output_Final_Results(ParetoFront, Experiment_History, t_start, params); 

end

% --- 辅助输出函数 ---
function Output_Final_Results(ParetoFront, Experiment_History, t_start, params)
    
    % 0. 定义文件名和路径
    timestamp = datestr(now,'yyyymmdd_HHMM');
    prefix = params.Output.NamePrefix;
    save_path = params.Output.Path;
    
    % 确保路径存在
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    
    FileName_mat = [save_path, prefix, 'Experiment_Results_', timestamp, '.mat'];
    FileName_csv = [save_path, prefix, 'History_Table_', timestamp, '.csv']; % <--- 新增：历史记录表格文件
    
    % 1. 打印最终帕累托前沿 F1 的信息
    NumSolutions = length(ParetoFront);
    disp(' ');
    disp('--- 最终结果汇总 ---');
    disp(['最终帕累托前沿 F1 包含 ', num2str(NumSolutions), ' 个非支配解。']);
    
    % 2. 提取 F1 解集数据
    Final_Pareto_Solutions = struct('Acc', {}, 'Count', {}, 'Features', {});
    for i = 1:NumSolutions
        Ind = ParetoFront(i);
        Final_Pareto_Solutions(i).Acc = Ind.Accuracy;
        Final_Pareto_Solutions(i).Count = Ind.FeatureCount;
        Final_Pareto_Solutions(i).Features = Ind.FeaturesSubset;
    end

    
    % 3. 提取并输出关键对比属性 (例如：最佳解)
    if ~isempty(Final_Pareto_Solutions)
        
        % 找到 ParetoFront 中特征数量最少的解作为代表 (Best Compression)
        all_counts = [Final_Pareto_Solutions.Count];
        [~, min_count_idx] = min(all_counts);
        Best_Comp_Solution = Final_Pareto_Solutions(min_count_idx);
        
        % 计算总运行时间
        Total_Gen = length(Experiment_History);
        Total_Time_Sec = etime(clock, t_start); 
        
        % ***************************************************************
        % 新增：生成表格文件 (CSV/Excel)
        % ***************************************************************
        
        % 转换历史记录结构体为 MATLAB 表格
        History_Table = struct2table(Experiment_History);
        
        % 写入 CSV 文件
        writetable(History_Table, FileName_csv);
        
        % 构造要输出的表格字符串 (控制台/txt)
        output_str = sprintf('\n--- 关键性能指标 (KFold=%d, Gen=%d) ---\n', params.Evaluation.KFold, Total_Gen);
        output_str = [output_str, sprintf('总运行时间: %.2f 秒\n', Total_Time_Sec)];
        output_str = [output_str, sprintf('平均每代时间: %.3f 秒/代\n', Total_Time_Sec / Total_Gen)];
        output_str = [output_str, sprintf('\n--- 最佳压缩解摘要 ---\n')];
        output_str = [output_str, sprintf('特征数量: %d\n', Best_Comp_Solution.Count)];
        output_str = [output_str, sprintf('分类准确率: %.4f\n', Best_Comp_Solution.Acc)];
        
        disp(output_str);
        
        % 将性能摘要写入文本文件
        txt_filename = [save_path, prefix, 'Summary_', timestamp, '.txt'];
        fid = fopen(txt_filename, 'w');
        fprintf(fid, '%s', output_str);
        fprintf(fid, 'Selected Feature Indices: %s\n', num2str(find(Best_Comp_Solution.Features)));
        fclose(fid);
        
        disp(['每代历史记录已保存到文件: ', FileName_csv]);
        disp(['性能摘要已保存到文件: ', txt_filename]);
    end
    
    % 保存最终帕累托解集和每代历史记录 (.mat 文件)
    save(FileName_mat, 'Final_Pareto_Solutions', 'Experiment_History', 'ParetoFront');
    disp(['MATLAB 历史数据已保存到文件: ', FileName_mat]);
    disp(' ');
end