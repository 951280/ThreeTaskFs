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
    
    % 1.