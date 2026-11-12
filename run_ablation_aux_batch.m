% run_ablation_aux_batch.m
% Batch runner for the two auxiliary-task ablation experiments:
%   1) CSO + Task 2: main CSO with the accuracy-oriented auxiliary task.
%   2) CSO + Task 3: main CSO with the compactness-oriented auxiliary task.
%
% Results are saved under params.Output.Path with folders named:
%   <DatasetName>_CSO_Task2
%   <DatasetName>_CSO_Task3

clear; clc;

REPEAT_TIMES = 1;
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

ablation_modes = {
    struct('Name', 'CSO_Task2', 'Enable_Task2', true,  'Enable_Task3', false)
    struct('Name', 'CSO_Task3', 'Enable_Task2', false, 'Enable_Task3', true)
};

run('config_parameters.m');
base_params = params;

disp('==========================================================');
disp('      Auxiliary-task ablation batch started');
disp(['      Datasets: ', num2str(length(dataset_list))]);
disp(['      Repeats : ', num2str(REPEAT_TIMES)]);
disp('==========================================================');

for mode_idx = 1:length(ablation_modes)
    mode_cfg = ablation_modes{mode_idx};
    disp(['>>> Mode: ', mode_cfg.Name, ' <<<']);

    for i = 1:length(dataset_list)
        this_dataset = dataset_list{i};
        disp(['  > Dataset: ', this_dataset]);

        for run_idx = 1:REPEAT_TIMES
            fprintf('\n    [%s][%s] Run %d/%d...\n', mode_cfg.Name, this_dataset, run_idx, REPEAT_TIMES);

            try
                params_run = base_params;
                params_run.Ablation.Enable_MultiTask = true;
                params_run.Ablation.Enable_Task2 = mode_cfg.Enable_Task2;
                params_run.Ablation.Enable_Task3 = mode_cfg.Enable_Task3;
                params_run.Ablation.Enable_GapFilling = true;

                main_CoEvolutionFS(this_dataset, params_run);
                disp('      [OK] Run finished.');
                pause(2);
            catch ME
                fprintf('      [FAILED] Run %d failed.\n', run_idx);
                fprintf('      Message: %s\n', ME.message);
                for s = 1:length(ME.stack)
                    fprintf('        at %s:%d\n', ME.stack(s).file, ME.stack(s).line);
                end
            end
        end
    end
end

disp('All auxiliary-task ablation runs finished.');
