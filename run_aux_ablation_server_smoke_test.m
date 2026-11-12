% run_aux_ablation_server_smoke_test.m
% 上服务器前用的小冒烟实验：检查两个新消融模式能不能正常读取数据并跑通。
% 参数故意设得很小，只验证流程，不看结果好坏。

clear; clc;

dataset_list = {
   'SONAR'
   'Gait'
   'Colon'
   'Leukemia'
   'Lung_Cancer'
   'Toxicity'
   'Period_Changer'
   'Micro_Mass'
   'Internet_Ads'
   'BASEHOCK'
   'RELATHE'
   'PCMAC'
   'warpPIE10P'
   'TOX-171'
   'ISOLET'
};

mode_list = {
    struct('Name', 'CSO_Task2', 'Enable_Task2', true,  'Enable_Task3', false)
    struct('Name', 'CSO_Task3', 'Enable_Task2', false, 'Enable_Task3', true)
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
rec_idx = 0;

for m = 1:numel(mode_list)
    mode_cfg = mode_list{m};
    fprintf('\n================ %s ================\n', mode_cfg.Name);

    for d = 1:numel(dataset_list)
        dataset_name = dataset_list{d};
        fprintf('\n>>> [%s] %s\n', mode_cfg.Name, dataset_name);
        t_one = tic;

        params_run = base_params;
        params_run.Ablation.Enable_MultiTask = true;
        params_run.Ablation.Enable_Task2 = mode_cfg.Enable_Task2;
        params_run.Ablation.Enable_Task3 = mode_cfg.Enable_Task3;
        params_run.Ablation.Enable_GapFilling = true;

        rec_idx = rec_idx + 1;
        records(rec_idx).Dataset = dataset_name;
        records(rec_idx).Mode = mode_cfg.Name;

        try
            main_CoEvolutionFS(dataset_name, params_run);
            records(rec_idx).Status = 'OK';
            records(rec_idx).Message = '';
            fprintf('    [OK] %s %s passed.\n', mode_cfg.Name, dataset_name);
        catch ME
            records(rec_idx).Status = 'FAILED';
            records(rec_idx).Message = ME.message;
            fprintf('    [FAILED] %s %s: %s\n', mode_cfg.Name, dataset_name, ME.message);
            for s = 1:numel(ME.stack)
                fprintf('      at %s:%d\n', ME.stack(s).file, ME.stack(s).line);
            end
        end

        records(rec_idx).Seconds = toc(t_one);
    end
end

if ~exist(base_params.Output.Path, 'dir')
    mkdir(base_params.Output.Path);
end
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
summary_file = fullfile(base_params.Output.Path, ['AuxAblationSmokeSummary_', timestamp, '.csv']);
writetable(struct2table(records), summary_file);

disp(' ');
disp('================ Smoke test summary ================');
T = struct2table(records);
disp(T);
fprintf('Summary saved to: %s\n', summary_file);
