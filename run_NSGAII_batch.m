% 文件: run_NSGAII_batch.m
% 自动化脚本：运行 NSGA-II 对比实验
% 配置：15 个数据集 x 5 次独立运行

clc; clear; close all;

% 1. 定义数据集列表 (根据你提供的列表)
% 请确保这些名字能被 data_loader 正确识别
% 1. 定义数据集列表
% 1. 定义数据集列表
dataset_list = { 
 %  % --- 原有 9 个 ---
  % 'SONAR'              
 %  'Gait'             
 %  'Colon'            
 %  'Leukemia'         
 %  'Lung_Cancer'      
 %  'Toxicity'         
  % 'Period_Changer'   
 %  'Micro_Mass'    %   
 % 'Internet_Ads'
   
   % --- 新增 6 个 (高维/多样本) ---
 %  'BASEHOCK'    
  % 'RELATHE'     
  % 'PCMAC'       
  % 'warpPIE10P'      
  % 'TOX-171'         
   'ISOLET'          
};

% 2. 实验配置
Run_Times = 5; % 每个数据集跑 5 遍

disp('================================================');
disp('      开始运行 NSGA-II 批量对比实验');
disp(['      数据集数量: ', num2str(length(dataset_list))]);
disp(['      每集运行次数: ', num2str(Run_Times)]);
disp('================================================');

total_start = tic;

% 3. 双重循环：数据集 -> 运行次数
for d_idx = 1:length(dataset_list)
    dataset_name = dataset_list{d_idx};
    disp(['>>> 正在处理数据集 [', num2str(d_idx), '/', num2str(length(dataset_list)), ']: ', dataset_name, ' ...']);
    
    for r = 1:Run_Times
        try
            % 调用主函数
            main_NSGAII(dataset_name, r);
            
        catch ME
            % 容错处理：如果某个数据集报错，不要通过断整个程序，记录并继续
            fprintf(2, '!!! 错误: 数据集 %s 在第 %d 次运行时失败 !!!\n', dataset_name, r);
            fprintf(2, '    错误信息: %s\n', ME.message);
            % continue; 
        end
    end
    disp(['--- 数据集 ', dataset_name, ' 全部 5 次运行结束 ---']);
    disp(' '); % 空行
end

disp('================================================');
disp(['所有任务执行完毕！总耗时: ', num2str(toc(total_start)/60, '%.1f'), ' 分钟']);
disp('================================================');