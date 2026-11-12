% 文件: run_local_batch_repeated.m
% 功能: 批量运行本地数据集 (每个数据集重复运行多次)
clear; clc;

% =========================================================================
% ★★★ 核心配置 ★★★
% =========================================================================
REPEAT_TIMES = 1;  % 每个数据集跑几遍？(建议设为 5 以进行统计分析)

% ★★★ 黄金数据集列表 (High Dimension & Safe Sample Size) ★★★
% 请确保这些 .mat 文件位于代码目录下的 data/ 文件夹中
% 1. 定义数据集列表
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

% (已跑过的旧数据集，已注释)
% old_list = {'SONAR', 'Colon', 'Lung_Cancer', 'Internet_Ads'};

disp('==========================================================');
disp(['      开始批量实验: 共 ', num2str(length(dataset_list)), ' 个新数据集']);
disp(['      每个数据集重复: ', num2str(REPEAT_TIMES), ' 次']);
disp('=========================================================='); 

% 外层循环：遍历不同数据集
for i = 1:length(dataset_list)
    this_dataset = dataset_list{i};
    disp(['>>> 进入数据集: ', this_dataset, ' <<<']);
    
    % 内层循环：重复运行多次 (Run 1 ~ Run 5)
    for run_idx = 1:REPEAT_TIMES
        
        fprintf('\n    > [%s] 正在执行第 %d / %d 次运行 ...\n', this_dataset, run_idx, REPEAT_TIMES);
        
        try
            % ★★★ 核心命令：调用主函数 ★★★
            % 主函数会自动去 data/ 文件夹下找同名的 .mat 文件
            main_CoEvolutionFS(this_dataset);
            
            disp(['      [成功] Run ', num2str(run_idx), ' 完成。']);
            
            % ★ 关键操作：暂停 2 秒，防止结果文件名时间戳冲突 ★
            pause(2); 
            
        catch ME
            % 错误捕获
            fprintf('      !!! [失败] Run %d 发生错误 !!!\n', run_idx);
            fprintf('      错误信息: %s\n', ME.message);
            disp('      >>> 跳过本次运行，继续下一次...');
        end
    end
    
    disp('----------------------------------------------------------');
end
disp('所有数据集的所有轮次均已执行完毕！');
disp('请前往 Results 文件夹整理数据。');