% run_aux_ablation_server_smoke_test_remaining_task3.m
% 上一次整批本地冒烟测试被外层超时截断后，用这个脚本只补跑剩余的 Task3 数据集。

clear; clc;

dataset_list = {
   'RELATHE'
   'PCMAC'
   'warpPIE10P'
   'TOX-171'
   'ISOLET'
};

run('config_parameters.m');
base_params = params;
base_params.PopSize = 4;
base_params.MaxGenerations = 1;
base_params.InitialSelect.MaxInitialPop = base_params.PopSize;
base_params.Evaluation.KFold = 2;
base_params.Evaluation.KNN_K = 3;
base_params.Output.Path = fullfile('D:\code\ThreeTaskFs\Results', '服务器前冒烟测试');

records = struct('Dataset', {}, 'Mode', {}, 'Status', {}, 'Message', {}, 'Seconds', {});

for d = 1:numel(dataset_list)
    dataset_name = dataset_list{d};
    fprintf('\n>>> [CSO_Task3] %s\n', dataset_name);
    t_one = tic;

    params_run = base_params;
    params_run.Ablation.Enable_MultiTask = true;
    params_run.Ablation.Enable_Task2 = false;
    params_run.Ablation.Enable_Task3 = true;
    params_run.Ablation.Enable_GapFilling = true;

    records(d).Dataset = dataset_name;
    records(d).Mode = 'CSO_Task3';
    try
        main_CoEvolutionFS(dataset_name, params_run);
        records(d).Status = 'OK';
        records(d).Message = '';
    catch ME
        records(d).Status = 'FAILED';
        records(d).Message = ME.message;
        fprintf('[FAILED] %s: %s\n', dataset_name, ME.message);
        for s = 1:numel(ME.stack)
            fprintf('  at %s:%d\n', ME.stack(s).file, ME.stack(s).line);
        end
    end
    records(d).Seconds = toc(t_one);
end

if ~exist(base_params.Output.Path, 'dir')
    mkdir(base_params.Output.Path);
end
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
summary_file = fullfile(base_params.Output.Path, ['AuxAblationSmokeSummary_RemainingTask3_', timestamp, '.csv']);
writetable(struct2table(records), summary_file);
disp(struct2table(records));
fprintf('Summary saved to: %s\n', summary_file);
