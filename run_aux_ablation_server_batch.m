function run_aux_ablation_server_batch(varargin)
% run_aux_ablation_server_batch.m
% 服务器/虚拟机正式跑新增消融实验用。
%
% 用法：
%   1. 先在下面“手动设置区”改好 RUN_MODE、REPEAT_TIMES 和 dataset_list。
%   2. 在 MATLAB 里运行：
%        cd('C:\code\ThreeTaskFs')
%        run_aux_ablation_server_batch
%
% 说明：
%   这个版本不再用 1/2/3 自动分组。要跑哪些数据集，就在 dataset_list 里手动保留；
%   暂时不跑的数据集，直接在那一行前面加 % 注释掉即可。

    if nargin > 0
        fprintf('[提示] 现在这个脚本已经改成手动配置版，不再需要输入 1/2/3 分组编号。\n');
        fprintf('       本次会忽略输入参数，直接读取脚本开头的手动设置。\n\n');
    end

    clearvars -except varargin; clc;

    %% ====================== 手动设置区 ======================
    % 选择要跑哪个新增消融实验：
    %   'CSO_Task2' = 主任务 CSO + 辅助任务 1（精度导向辅助任务）
    %   'CSO_Task3' = 主任务 CSO + 辅助任务 2（紧凑性导向辅助任务）
    %   'BOTH'      = 两个新增消融都跑
    RUN_MODE = 'CSO_Task2';

    % 每个数据集重复跑几轮。
    % 比如先看效果就设 10；正式大量重复实验时再按论文需要改。
    REPEAT_TIMES = 10;

    % 数据根目录。虚拟机上把整个 data 文件夹放在 D 盘下，也就是这里。
    DATA_ROOT = 'C:\data';

    % 结果保存位置。默认写到当前代码文件夹下面的 Results 里。
    % 这样本机是 D:\code\ThreeTaskFs，服务器是 C:\code\ThreeTaskFs，都不用额外改。
    PROJECT_ROOT = fileparts(mfilename('fullpath'));
    OUTPUT_ROOT = fullfile(PROJECT_ROOT, 'Results', 'Server_AuxAblation');

    % 要跑哪些数据集，就保留哪些行；不想跑的行直接在前面加 %。
    % 下面 12 个按论文表里的顺序排好，后面注释是：样本数 / 特征数 / 类别数。
    dataset_list = {
       'SONAR'           % 208 / 60   / 2
       'ISOLET'          % 1560 / 617 / 26
       'Period_Changer'  % 90 / 1177  / 2
       'Toxicity'        % 171 / 1203 / 2
       'Micro_Mass'      % 571 / 1300 / 20
       'Internet_Ads'    % 3279 / 1558 / 2
       'Colon'           % 62 / 2000  / 2
       'warpPIE10P'      % 210 / 2420 / 10
       'PCMAC'           % 1943 / 3289 / 2
       'Lung_Cancer'     % 203 / 3312 / 5
       'BASEHOCK'        % 1993 / 4862 / 2
       'TOX-171'         % 171 / 5748 / 4
    };
    %% ========================================================

    run('config_parameters.m');
    base_params = params;

    % 正式实验参数。这里和老代码的正式设置保持一致。
    base_params.PopSize = 50;                  % 每个任务的种群数
    base_params.MaxGenerations = 100;          % 总迭代代数
    base_params.InitialSelect.MaxInitialPop = base_params.PopSize;
    base_params.Evaluation.KFold = 5;          % 五折交叉验证
    base_params.Evaluation.KNN_K = 5;          % KNN 的 K
    base_params.Data.BaseDir = DATA_ROOT;

    mode_list = build_mode_list(RUN_MODE);

    time_tag = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    run_folder_name = sprintf('%s_%s', upper(RUN_MODE), time_tag);
    base_params.Output.Path = fullfile(OUTPUT_ROOT, run_folder_name);

    if ~exist(base_params.Output.Path, 'dir')
        mkdir(base_params.Output.Path);
    end

    records = struct('Dataset', {}, 'Mode', {}, 'Run', {}, 'Status', {}, ...
        'Message', {}, 'Seconds', {});
    rec_idx = 0;
    total_jobs = numel(mode_list) * numel(dataset_list) * REPEAT_TIMES;
    finished_jobs = 0;
    batch_tic = tic;

    fprintf('==========================================================\n');
    fprintf(' 新增消融实验正式批处理\n');
    fprintf(' RUN_MODE     : %s\n', RUN_MODE);
    fprintf(' Repeat times : %d\n', REPEAT_TIMES);
    fprintf(' Mode count   : %d\n', numel(mode_list));
    fprintf(' Dataset count: %d\n', numel(dataset_list));
    fprintf(' Total jobs   : %d\n', total_jobs);
    fprintf(' Datasets     : %s\n', strjoin(dataset_list', ', '));
    fprintf(' PopSize=%d, MaxGenerations=%d, KFold=%d, KNN_K=%d\n', ...
        base_params.PopSize, base_params.MaxGenerations, ...
        base_params.Evaluation.KFold, base_params.Evaluation.KNN_K);
    fprintf(' Alpha=%.2f, Lambda=%.4f, ThetaAcc=%.2f\n', ...
        base_params.Fitness.Alpha, base_params.Fitness.Lambda, ...
        base_params.Fitness.ThetaAcc);
    fprintf(' K_Refresh=%d, T_Transfer=%d, ChangeFactor=%.4f, GapFilling=%d\n', ...
        base_params.Knowledge.K_Refresh, base_params.Knowledge.T_Transfer, ...
        base_params.LearningRate.ChangeFactor, base_params.Ablation.Enable_GapFilling);
    fprintf(' Data root    : %s\n', base_params.Data.BaseDir);
    fprintf(' Output       : %s\n', base_params.Output.Path);
    fprintf('==========================================================\n');

    for m = 1:numel(mode_list)
        mode_cfg = mode_list{m};

        for d = 1:numel(dataset_list)
            dataset_name = dataset_list{d};

            fprintf('\n----------------------------------------------------------\n');
            fprintf(' 准备开始数据集：%s\n', dataset_name);
            fprintf(' 当前消融模式：%s  (%d/%d)\n', mode_cfg.Name, m, numel(mode_list));
            fprintf(' 当前数据集序号：%d/%d\n', d, numel(dataset_list));
            fprintf(' 这个数据集要重复：%d 轮\n', REPEAT_TIMES);
            fprintf('----------------------------------------------------------\n');

            for run_idx = 1:REPEAT_TIMES
                next_job = finished_jobs + 1;
                elapsed_before = toc(batch_tic);
                fprintf('\n>>> 总进度 %d/%d | 模式 %d/%d | 数据集 %d/%d | 重复 %d/%d\n', ...
                    next_job, total_jobs, m, numel(mode_list), d, numel(dataset_list), ...
                    run_idx, REPEAT_TIMES);
                fprintf('    当前任务：[%s] 数据集 [%s]\n', mode_cfg.Name, dataset_name);
                fprintf('    已用时间：%s\n', format_seconds(elapsed_before));
                fprintf('    参数：PopSize=%d, MaxGen=%d, KFold=%d, KNN_K=%d\n', ...
                    base_params.PopSize, base_params.MaxGenerations, ...
                    base_params.Evaluation.KFold, base_params.Evaluation.KNN_K);
                fprintf('    结果目录：%s\n', base_params.Output.Path);

                params_run = base_params;
                params_run.Ablation.Enable_MultiTask = true;
                params_run.Ablation.Enable_Task2 = mode_cfg.Enable_Task2;
                params_run.Ablation.Enable_Task3 = mode_cfg.Enable_Task3;
                params_run.Ablation.Enable_GapFilling = true;

                rec_idx = rec_idx + 1;
                records(rec_idx).Dataset = dataset_name;
                records(rec_idx).Mode = mode_cfg.Name;
                records(rec_idx).Run = run_idx;
                t_one = tic;

                try
                    main_CoEvolutionFS(dataset_name, params_run);
                    records(rec_idx).Status = 'OK';
                    records(rec_idx).Message = '';
                    fprintf('    [OK] Finished.\n');
                catch ME
                    records(rec_idx).Status = 'FAILED';
                    records(rec_idx).Message = ME.message;
                    fprintf('    [FAILED] %s\n', ME.message);
                    for s = 1:numel(ME.stack)
                        fprintf('      at %s:%d\n', ME.stack(s).file, ME.stack(s).line);
                    end
                end

                records(rec_idx).Seconds = toc(t_one);
                finished_jobs = finished_jobs + 1;
                elapsed_total = toc(batch_tic);
                avg_seconds = elapsed_total / finished_jobs;
                remain_jobs = total_jobs - finished_jobs;
                eta_seconds = avg_seconds * remain_jobs;

                fprintf('    本轮耗时：%s\n', format_seconds(records(rec_idx).Seconds));
                fprintf('    已完成：%d/%d，还剩：%d\n', finished_jobs, total_jobs, remain_jobs);
                fprintf('    累计用时：%s，预计剩余：%s\n', ...
                    format_seconds(elapsed_total), format_seconds(eta_seconds));

                % 每跑完一轮就刷新进度表。服务器中途停了，也能看到已经跑到哪里。
                summary_file = fullfile(base_params.Output.Path, ...
                    sprintf('ServerAuxAblation_%s_Progress.csv', upper(RUN_MODE)));
                % records 是结构体数组；只有一条记录时也要按“一行一轮实验”来写表。
                % 不加 AsArray 的话，MATLAB 可能会把字段内容当成列数据拆开，遇到空 Message 就报错。
                writetable(struct2table(records, 'AsArray', true), summary_file);
                fprintf('    进度表已更新：%s\n', summary_file);
                pause(2);
            end
        end
    end

    fprintf('\n==========================================================\n');
    fprintf(' 本次批处理结束\n');
    fprintf(' 总任务数：%d，成功/失败请看进度表 Status 列\n', total_jobs);
    fprintf(' 总耗时：%s\n', format_seconds(toc(batch_tic)));
    fprintf(' 结果和进度表保存在：\n%s\n', base_params.Output.Path);
    fprintf('==========================================================\n');
end

function mode_list = build_mode_list(run_mode)
% 根据手动设置的 RUN_MODE 生成要跑的消融实验列表。

    run_mode = upper(strtrim(run_mode));

    switch run_mode
        case 'CSO_TASK2'
            mode_list = {
                struct('Name', 'CSO_Task2', 'Enable_Task2', true,  'Enable_Task3', false)
            };
        case 'CSO_TASK3'
            mode_list = {
                struct('Name', 'CSO_Task3', 'Enable_Task2', false, 'Enable_Task3', true)
            };
        case 'BOTH'
            mode_list = {
                struct('Name', 'CSO_Task2', 'Enable_Task2', true,  'Enable_Task3', false)
                struct('Name', 'CSO_Task3', 'Enable_Task2', false, 'Enable_Task3', true)
            };
        otherwise
            error('RUN_MODE 只能写 CSO_Task2、CSO_Task3 或 BOTH。当前值是：%s', run_mode);
    end
end

function text_out = format_seconds(seconds_value)
% 把秒数转成 HH:MM:SS，窗口里看进度更直观。

    if ~isfinite(seconds_value) || seconds_value < 0
        seconds_value = 0;
    end

    seconds_value = round(seconds_value);
    hours_value = floor(seconds_value / 3600);
    minutes_value = floor(mod(seconds_value, 3600) / 60);
    seconds_left = mod(seconds_value, 60);
    text_out = sprintf('%02d:%02d:%02d', hours_value, minutes_value, seconds_left);
end
