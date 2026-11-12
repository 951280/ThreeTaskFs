% config_parameters.m
% 算法的全局配置参数文件。
% 使用结构体 params 存储所有配置，方便在主程序和函数中传递和访问。

% 算法版本信息 (可选)
params.AlgorithmName = 'MultiTaskCoEvolutionaryFS';
params.MATLABVersion = version;

%% 0. 调试/子集抽样参数 (Phase 1 之前)
% 区域：调试/抽样
% 含义：调试运行时抽取的数据集比例 (0-1)。 1 表示全部数据。
params.Debug.Enable = false;          % 是否启用调试子集抽取 (true/false)。【正式跑实验设为 false】
params.Debug.Subset_Ratio = 0.2;      % 抽取的数据集比例 (0-1)。

% 输出路径配置
params.Output.Path = 'C:\code\ThreeTaskFs\Results\'; % <--- 设定输出文件夹基础路径
params.Output.NamePrefix = 'CoEvoFS_';               % 结果文件前缀

% Server data root. Put the whole data folder at C:\data on the VM/server.
params.Data.BaseDir = 'C:\data';

%% 1. 种群和迭代参数 (Phase 4, 5)
params.PopSize = 50;            % 种群大小 (所有任务统一为 50)
params.MaxGenerations = 100;    % 最大进化代数 (标准设定 100)
params.StopPatience = 10;       % 连续多代适应度未提升的停止代数 (早停机制)

%% 2. 分类器和评估参数 (Phase 1, 4)
% 在 evaluateSubset.m 中使用
params.Evaluation.KFold = 5;            % K-折交叉验证的 K
params.Evaluation.KNN_K = 5;            % K-近邻分类器的 K 值

%% 3. 适应度函数参数 (Phase 2, 5)
% --- Task 1 (主任务: 平衡) f1 ---
% f1(S) = alpha * Acc(S) + (1 - alpha) * (1 - |S|/N)
params.Fitness.Alpha = 0.8;             % 平衡因子：[0, 1]。0.8 表示更看重分类精度。

% --- Task 2 (辅助任务 1: 精度优化器) f2 ---
% f2(S) = Acc - lambda * (|S|/N)
params.Fitness.Lambda = 0.01;           % 特征数量惩罚项。
params.Fitness.Lambda_Range = [0.05, 0.2]; % (备忘：论文建议范围)

% --- Task 3 (辅助任务 2: 紧凑性优化器) f3 ---
% f3(S) = (1 - |S|/N), if Acc(S) >= theta_acc
params.Fitness.ThetaAcc = 0.80;         % 最低可接受精度阈值

%% 4. 知识共享与迁移参数 (Phase 3, 4)
% =======================================================
% ★★★ 参数同步策略：K 和 T 保持一致 ★★★
% =======================================================

% --- 知识共享/刷新 ---
params.Knowledge.K_Refresh = 20;        % IM/SV 域刷新的周期 K (建议与 T 保持一致)20
params.Knowledge.IM_SV_InitValue = 0.01; % IM 和 SV 的初始值/小常数

% --- 知识迁移 ---
params.Knowledge.T_Transfer = 20;       % 知识迁移的周期 T (建议与 K 保持一致)

% (以下动态参数已废弃/暂不使用，注释掉以保持整洁，若旧代码有调用也不会报错，因为结构体字段还在只是被注释了)
% params.Knowledge.T_DynamicRatio = 0.9;  
% params.Knowledge.GenRatioForEarlyTransfer = 0.3; 

% --- 迁移策略 TOP M/K ---
params.Knowledge.TopM_SV = 10;          % 历史 SV 高值保留数量 M
params.Knowledge.TopK_IM = 10;          % 历史 IM 高值保留数量 K

%% 5. 初始特征选择参数 (Phase 2)
% K1 数量由膝点法决定，此处仅作为辅助参数
% ★★★ 关键修正：此处必须等于 PopSize (50)，否则 initialFeatureSelection 会报错 ★★★
params.InitialSelect.MaxInitialPop = 50; 
params.InitialSelect.SampleRate = 0.2;  % 概率抽样中，特征子集的最大比例

%% 6. 学习率参数
params.LearningRate.ChangeFactor = 0.01; % IM/SV 每次更新的学习率 Delta (Δ)
%% 7. 消融实验控制 (Ablation Study Flags)
% =======================================================
% 核心开关：控制是否启用多任务协同与断层填充
% =======================================================

% 开关1: 是否启用多任务协同 (Task 2 & 3 + 知识迁移)
% true = 完整算法 (MT-GF-MoFS) 或 无断层版 (MT-MoFS)
% false = 单任务 CSO (Single-Task CSO)
params.Ablation.Enable_MultiTask = false;
% Fine-grained auxiliary task switches for ablation studies.
% Task 2 is the accuracy-oriented auxiliary task (f2).
% Task 3 is the compactness-oriented auxiliary task (f3).
% Valid modes:
%   Single CSO       : Enable_MultiTask=false
%   CSO + Task 2     : Enable_MultiTask=true, Enable_Task2=true,  Enable_Task3=false
%   CSO + Task 3     : Enable_MultiTask=true, Enable_Task2=false, Enable_Task3=true
%   Full three-task  : Enable_MultiTask=true, Enable_Task2=true,  Enable_Task3=true
params.Ablation.Enable_Task2 = true;
params.Ablation.Enable_Task3 = true;

% 开关2: 是否启用断层填充策略 (Gap-Filling)
% true = 完整算法 (MT-GF-MoFS)
% false = 无断层版 (MT-MoFS) 或 单任务 CSO
params.Ablation.Enable_GapFilling = true;

% 保存参数结构体
save('algorithm_parameters.mat', 'params');
disp('全局参数已写入 config_parameters.m 并保存到 algorithm_parameters.mat.');
