% 文件名: Output_Final_Results.m
function Output_Final_Results(Global_Archive, Elite2, Elite3, Experiment_History, t_start, params, dataset_name)
% OUTPUT_FINAL_RESULTS 算法结束后的数据处理、融合与保存模块 (无绘图版)
%
% 输入:
%   Global_Archive: 全局归档（包含每一代的 Pareto 前沿解）
%   Elite2/3: 辅助任务最终精英解
%   Experiment_History: 迭代历史记录
%   t_start: 开始时间句柄
%   params: 参数结构体
%   dataset_name: 数据集名称

    % 0. 定义文件名和路径
    % 为了兼容 run_local_batch.m，如果 main 函数传入了 run_id，这里会被覆盖
    % 如果是独立运行，这里生成带时间戳的文件名
    
    timestamp = datestr(now,'yyyymmdd_HHMMSS'); % 加了秒，防止覆盖
    prefix = params.Output.NamePrefix;
    save_path = params.Output.Path;
    
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    
    % 基础文件名
    base_name = [dataset_name, '_', prefix]; 
    
    % 检查是否通过 main 函数传入了指定的文件名逻辑 (通过 params.Output.Path 传递)
    % 这里我们统一使用时间戳保存，确保每次运行都不覆盖
    FileName_mat = fullfile(save_path, [base_name, 'Result_', timestamp, '.mat']);
    FileName_csv = fullfile(save_path, [base_name, 'History_', timestamp, '.csv']);
    
    disp(' ');
    fprintf('--- 正在融合多任务解集 [%s] ---\n', dataset_name);
    
    % =======================================================
    % 1. 融合与筛选 (去重 & 最小化错误率 & 最小化特征数)
    % =======================================================
    
    % 将全局归档和最后一代精英放入原始池。
    % 消融实验可能只启用 Task2 或 Task3，因此这里要跳过空精英。
    Raw_Pool = Global_Archive;
    if ~isempty(Elite2)
        Raw_Pool = [Raw_Pool, Elite2];
    end
    if ~isempty(Elite3)
        Raw_Pool = [Raw_Pool, Elite3];
    end
    
    fprintf(' > 原始候选解数量 (含重复): %d\n', length(Raw_Pool));
    
    % --- 去重逻辑 (Remove Duplicates) ---
    % 使用特征子集的字符串形式作为 Key，防止重复计算
    unique_map = containers.Map();
    Candidate_Pool = [];
    
    for i = 1:length(Raw_Pool)
        % 将逻辑数组转为字符串作为唯一标识
        key = mat2str(double(Raw_Pool(i).FeaturesSubset));
        
        if ~isKey(unique_map, key)
            unique_map(key) = 1;
            if isempty(Candidate_Pool)
                Candidate_Pool = Raw_Pool(i);
            else
                Candidate_Pool = [Candidate_Pool, Raw_Pool(i)];
            end
        end
    end
    
    fprintf(' > 去重后候选解数量: %d\n', length(Candidate_Pool));
    
    Final_Indices = [];
    % 双重循环进行非支配排序筛选
    for i = 1:length(Candidate_Pool)
        dominated = false;
        Sol_A = Candidate_Pool(i);
        Error_A = 1 - Sol_A.Accuracy; 
        
        for j = 1:length(Candidate_Pool)
            if i == j, continue; end
            Sol_B = Candidate_Pool(j);
            Error_B = 1 - Sol_B.Accuracy; 
            
            % 检查 B 是否支配 A (错误率更低且特征更少，或者其中一项更好另一项相等)
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
    
    % 转换结构体以便保存
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
        % 寻找最佳压缩解
        all_counts = [Final_Pareto_Solutions.Count];
        [~, min_count_idx] = min(all_counts);
        Best_Comp_Solution = Final_Pareto_Solutions(min_count_idx);
        
        % 寻找最佳性能解 (最小错误率)
        all_errors = [Final_Pareto_Solutions.Error];
        [~, min_err_idx] = min(all_errors);
        Best_Perf_Solution = Final_Pareto_Solutions(min_err_idx);
        
        Total_Gen = length(Experiment_History);
        Total_Time_Sec = etime(clock, t_start); 
        
        % 保存历史记录到 CSV
        History_Table = struct2table(Experiment_History);
        writetable(History_Table, FileName_csv);
        
        % 生成摘要文本
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
        
        % 保存基础摘要到 TXT
        txt_filename = fullfile(save_path, [base_name, 'Summary_', timestamp, '.txt']);
        fid = fopen(txt_filename, 'w');
        fprintf(fid, '%s', output_str);
        fclose(fid);
        
        % =======================================================
        % 2.1 ★★★ 计算 HV 指标 (Hypervolume) ★★★
        % =======================================================
        
        % 获取总特征维度 D_total (用于归一化)
        if ~isempty(Final_Pareto_Solutions)
            D_total = length(Final_Pareto_Solutions(1).Features);
        elseif exist('params', 'var') && isfield(params.InitialSelect, 'W')
             D_total = size(params.InitialSelect.W, 1);
        else
             D_total = 1000; % 兜底防止报错
        end
        
        Obtained_PF = zeros(NumSolutions, 2);
        for i = 1:NumSolutions
            Obtained_PF(i, 1) = Final_Pareto_Solutions(i).Error;
            Obtained_PF(i, 2) = Final_Pareto_Solutions(i).Count / D_total;
        end
        
        % 2. 计算 HV
        RefPoint = [1.1, 1.1]; 
        HV_Value = Calculate_HV(Obtained_PF, RefPoint);
        
        % 3. 打印并追加记录
        fprintf(' > [指标计算] Hypervolume (HV): %.4f (参考点: [1.1, 1.1])\n', HV_Value);
        
        % 追加写入 TXT 文件
        fid = fopen(txt_filename, 'a'); 
        fprintf(fid, 'Hypervolume (HV): %.4f\n', HV_Value);
        fclose(fid);
        
    end
    
    % =======================================================
    % 3. 保存完整工作区数据 (绝不画图)
    % =======================================================
    disp(['  > [保存] 正在保存 .mat 数据至: ', FileName_mat]);
    save(FileName_mat, 'Final_Pareto_Solutions', 'Experiment_History', 'Global_Archive', 'params', 't_start', 'dataset_name');
    disp('  > [完成] 结果已保存。绘图请在本地运行 Plot_Paper_Comparison.m');
    disp(' ');
end

% =======================================================
% 4. 辅助函数
% =======================================================
% --- 辅助函数：计算二维 Hypervolume ---
function score = Calculate_HV(PopObj, RefPoint)
    % PopObj: [N x 2] 矩阵，第一列为Error，第二列为FeatureRatio
    % RefPoint: [1.1, 1.1] 参考点
    
    % 1. 按第一维(错误率)升序排序
    [~, idx] = sort(PopObj(:,1));
    SortedObj = PopObj(idx, :);
    
    % 2. 过滤掉被参考点支配的劣解(即超过 1.1 的)
    valid = all(SortedObj <= RefPoint, 2);
    SortedObj = SortedObj(valid, :);
    
    if isempty(SortedObj)
        score = 0; return;
    end
    
    % 3. 再次去重 (防止非支配排序漏网之鱼，X相同取Y最小)
    [~, unique_idx] = unique(SortedObj(:,1));
    SortedObj = SortedObj(unique_idx, :);
    
    % 4. 计算并集面积 (切条法)
    score = 0;
    
    for i = 1:size(SortedObj, 1)-1
        width = SortedObj(i+1, 1) - SortedObj(i, 1);
        height = RefPoint(2) - SortedObj(i, 2);
        if width > 0 && height > 0
            score = score + width * height;
        end
    end
    
    % 加上最后一块
    width = RefPoint(1) - SortedObj(end, 1);
    height = RefPoint(2) - SortedObj(end, 2);
    if width > 0 && height > 0
        score = score + width * height;
    end
end
