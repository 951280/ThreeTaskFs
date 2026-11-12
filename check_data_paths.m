% check_data_paths.m
% 极速测试：完整版 (包含所有特定路径映射)

clc; clear;

% =======================================================
% 1. 定义数据集列表 (15个)
% =======================================================
dataset_list = { 
   % --- 原有 9 个 ---
   'SONAR'              
   'Gait'             
   'Colon'            
   'Leukemia'         
   'Lung_Cancer'      
   'Toxicity'         
   'Period_Changer'   
   'Micro_Mass'       
   'Internet_Ads'
   
   % --- 新增 6 个 (高维/多样本) ---
   'BASEHOCK'    
   'RELATHE'     
   'PCMAC'       
   'warpPIE10P'      
   'TOX-171'         
   'ISOLET'          
};

disp('>>> 开始极速路径检查 (完整路径版) <<<');

% 定义基础路径 (根据你的实际情况)
BASE_DIR = 'D:\learn\yjs\paper\data\';

for i = 1:length(dataset_list)
    name = dataset_list{i};
    fprintf('正在检查 [%d/%d] %-15s ... ', i, length(dataset_list), name);
    
    % 初始化路径变量
    DataPath = '';
    LabelPath = '';
    
    % =======================================================
    % ★★★ 核心修复：这里必须照搬 main 函数的路径逻辑 ★★★
    % =======================================================
    try
        switch name
            case 'SONAR'
                DataPath = fullfile(BASE_DIR, 'sonar\sonar.all-data');
                
            case 'Gait'
                DataPath = fullfile(BASE_DIR, 'gait+classification\PersonGaitDataSet.mat');
                
            case 'Colon'
                DataPath = fullfile(BASE_DIR, 'colon.mat');
                
            case 'Leukemia'
                DataPath = fullfile(BASE_DIR, 'leukemia.mat');
                
            case 'Lung_Cancer'
                DataPath = fullfile(BASE_DIR, 'lung.mat');
                
            case 'Toxicity'
                DataPath = fullfile(BASE_DIR, 'toxicity\data.csv');
                
            case 'Period_Changer'
                DataPath = fullfile(BASE_DIR, 'period+changer-2\data.csv');
                
            case 'Micro_Mass'
                DataPath = fullfile(BASE_DIR, 'micromass\pure_spectra_matrix.csv');
                LabelPath = fullfile(BASE_DIR, 'micromass\pure_spectra_metadata.csv');
                
            case 'Internet_Ads'
                DataPath = fullfile(BASE_DIR, 'internet+advertisements\ad.data');
                
            % --- 下面是 6 个通用的 .mat 数据集 ---
            case {'BASEHOCK', 'RELATHE', 'PCMAC', 'warpPIE10P', 'TOX-171', 'ISOLET'}
                DataPath = fullfile(BASE_DIR, [name, '.mat']);
                
            otherwise
                error('未知的测试数据集名称: %s', name);
        end
        
        % 开始计时加载
        t_start = tic;
        
        % 调用加载器
        if isempty(LabelPath)
            [X, Y, ~] = data_loader(DataPath, '', name); 
        else
            [X, Y, ~] = data_loader(DataPath, LabelPath, name);
        end
        
        t_cost = toc(t_start);
        fprintf('[成功] (N=%d, D=%d) 耗时: %.2fs\n', size(X,1), size(X,2), t_cost);
        
    catch ME
        fprintf('\n!!! [失败] 路径: %s\n', DataPath);
        fprintf('!!! [错误信息]: %s\n', ME.message);
    end
end
disp('>>> 检查完成 <<<');