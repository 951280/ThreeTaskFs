% 文件: main_NSGAII.m
function main_NSGAII(target_dataset_name, current_run_id)
% MAIN_NSGAII 经典 NSGA-II 算法用于特征选择 (Benchmark)
% 调用方式: main_NSGAII('SONAR', 1)  <-- 跑 SONAR 第 1 遍

    % 默认参数处理
    if nargin < 1, target_dataset_name = 'SONAR'; end
    if nargin < 2, current_run_id = 1; end % 默认为第 1 遍
    
    % 1. 加载配置
    if ~exist('params', 'var')
        run('config_parameters.m');
    end
    
    % 强制覆盖为标准对比参数 (保证公平性)
    params.PopSize = 50; 
    params.MaxGenerations = 100;
    
    % 2. 加载数据 (逻辑与主程序保持一致)
    % [重要] 这里复用你的通用加载逻辑，确保读取数据无误
    disp(['>>> [NSGA-II Run ', num2str(current_run_id), '] Loading: ', target_dataset_name, ' <<<']);
    
    try
        % 尝试调用 data_loader (前提是你目录下有这个文件)
        % 如果是特定的路径，请保留你在 main_CoEvolutionFS 里的写法
        base_dir = params.Output.Path; % 或者你写死的 'D:\learn\yjs\paper\data\'
        
        % 简易路由 (根据你之前的代码片段)
        if strcmp(target_dataset_name, 'SONAR')
             [X, Y, ~] = data_loader('D:\learn\yjs\paper\data\sonar\sonar.all-data', '', 'SONAR');
        elseif strcmp(target_dataset_name, 'SPECTF')
             [X, Y, ~] = data_loader('D:\learn\yjs\paper\data\spect+heart\SPECT.train', 'D:\learn\yjs\paper\data\spect+heart\SPECT.test', 'SPECTF');
        % ... (这里可以简略，只要 data_loader 能处理通用路径即可) ...
        else
             % 通用尝试 (适配那 6 个新数据集)
             % 假设 data_loader 内部有处理逻辑，或者直接传路径
             full_path = fullfile('D:\learn\yjs\paper\data\', [target_dataset_name, '.mat']);
             if exist(full_path, 'file')
                 [X, Y, ~] = data_loader(full_path, '', target_dataset_name);
             else
                 % 如果 data_loader 自己能搞定名字映射，就直接传名字
                 [X, Y, ~] = data_loader('', '', target_dataset_name); 
             end
        end
    catch ME
        warning(['数据加载失败: ', ME.message]);
        return;
    end

    D_total = size(X, 2);
    
    % 3. 初始化种群 (Binary)
    Population = repmat(struct('Position', [], 'Cost', [], 'Rank', [], 'CD', [], 'Acc', [], 'FeatCount', []), params.PopSize, 1);
    for i = 1:params.PopSize
        Population(i).Position = rand(1, D_total) > 0.5;
        if sum(Population(i).Position) == 0, Population(i).Position(randi(D_total)) = 1; end
        [acc, count] = Evaluate_Ind(Population(i).Position, X, Y, params);
        Population(i).Cost = [(1-acc), (count/D_total)];
        Population(i).Acc = acc;
        Population(i).FeatCount = count;
    end
    
    % 4. 进化主循环
    ParetoFront_History = cell(params.MaxGenerations, 1);
    t_start = tic;
    
    for Gen = 1:params.MaxGenerations
        Population = NSGAII_Optimizer(Population, X, Y, params);
        ParetoMask = [Population.Rank] == 1;
        ParetoFront_History{Gen} = Population(ParetoMask);
        
        % 仅在第一遍运行时打印详细日志，避免刷屏
        if mod(Gen, 20) == 0 && current_run_id == 1
            fprintf('   > [Run %d] Gen %d finished.\n', current_run_id, Gen);
        end
    end
    runtime = toc(t_start);
    
    % 5. 保存结果 (区分 Run ID)
    % 文件夹结构: Results/SONAR_NSGAII/Run_1.mat
    SaveDir = fullfile('Results', [target_dataset_name, '_NSGAII']);
    if ~exist(SaveDir, 'dir'), mkdir(SaveDir); end
    
    FileName = fullfile(SaveDir, sprintf('Result_Run%d.mat', current_run_id));
    
    % 提取最终 PF
    Final_PF = Population([Population.Rank] == 1);
    
    save(FileName, 'Final_PF', 'ParetoFront_History', 'runtime', 'params');
    fprintf('   > [完成] %s (Run %d) 已保存. 耗时: %.2fs\n', target_dataset_name, current_run_id, runtime);
end

% 辅助函数
function [acc, count] = Evaluate_Ind(mask, X, Y, params)
    acc = evaluateSubset(X, Y, mask, params);
    count = sum(mask);
end