% config_parameters.m
% 算法的全局配置参数文件。
% 使用结构体 params 存储所有配置，方便在主程序和函数中传递和访问。

% 算法版本信息 (可选)
params.AlgorithmName = 'MultiTaskCoEvolutionaryFS';
params.MATLABVersion = version;

%% 0. 调试/子集抽样参数 (Phase 1 之前)
% 区域：调试/抽样
% 参数名称：Debug_Subset_Ratio
% 含义：调试运行时抽取的数据集比例 (0-1)。 1 表示全部数据。
% 算法的应用：main_CoEvolutionFS.m

params.Debug.Enable = true;          % 是否启用调试子集抽取 (true/false)。调试时设为 true。
params.Debug.Subset_Ratio = 0.2;     % 抽取的数据集比例 (0-1)。 0.2 表示 20% 数据进行调试。


%% 1. 种群和迭代参数 (Phase 4, 5)
params.PopSize = 25;            % 种群大小 (所有任务统一)
params.MaxGenerations = 200;    % 最大进化代数
params.StopPatience = 20;       % 连续多代适应度未提升的停止代数 (Stopping Condition)

%% 2. 分类器和评估参数 (Phase 1, 4)
% 在 evaluateSubset.m 中使用
params.Evaluation.KFold = 1;            % K-折交叉验证的 K
params.Evaluation.KNN_K = 5;            % K-近邻分类器的 K 值

%% 3. 适应度函数参数 (Phase 2, 5)

% --- Task 1 (主任务: 平衡) f1 ---
% f1(S) = alpha * Acc(S) + (1 - alpha) * (1 - |S|/N)
% alpha 用于平衡 Accuracy 和 Feature Compression Ratio。
params.Fitness.Alpha = 0.5;             % 平衡因子：[0, 1]。0.5 表示平均权重。

% --- Task 2 (辅助任务 1: 精度优化器) f2 ---
% f2(S) = Acc - lambda * (|S|/N)
% lambda 用于惩罚特征数量。
params.Fitness.Lambda = 0.1;            % 特征数量惩罚项。论文建议 0.05 ~ 0.2。
params.Fitness.Lambda_Range = [0.05, 0.2]; % 论文建议范围备忘

% --- Task 3 (辅助任务 2: 紧凑性优化器) f3 ---
% f3(S) = (1 - |S|/N), if Acc(S) >= theta_acc
% f3(S) = Acc(S) * (1 - |S|/N), otherwise
% theta_acc 是最低可接受精度阈值。
params.Fitness.ThetaAcc = 0.8;          % 最低可接受精度阈值。论文建议 0.8。

%% 4. 知识共享与迁移参数 (Phase 3, 4)

% --- 知识共享/刷新 ---
params.Knowledge.K_Refresh = 10;        % IM/SV 域刷新的周期 K (每 K 代刷新一次域)
params.Knowledge.IM_SV_InitValue = 0.01; % IM 和 SV 的初始值/小常数

% --- 知识迁移 ---
params.Knowledge.T_Transfer = 20;       % 知识迁移的初始周期 T (每 T 代迁移一次)
params.Knowledge.T_DynamicRatio = 0.9;  % 迁移周期动态缩小的比例 (如 T = T * 0.9)
params.Knowledge.GenRatioForEarlyTransfer = 0.3; % 早期迁移阶段的代数比例 (如 Gen < 0.3*MaxGen 迁移少)

% --- 迁移策略 TOP M/K ---
params.Knowledge.TopM_SV = 10;          % 历史 SV 高值保留数量 M
params.Knowledge.TopK_IM = 10;          % 历史 IM 高值保留数量 K

%% 5. 初始特征选择参数 (Phase 2)
% K1 数量由膝点法决定，此处仅作为辅助参数
params.InitialSelect.MaxInitialPop = 50; % 初始种群生成数量 (应等于 PopSize)
params.InitialSelect.SampleRate = 0.2;  % 概率抽样中，特征子集的最大比例 (例如不超过总特征的 20%)

%% 6. 学习率参数
params.LearningRate.ChangeFactor = 0.01; % IM/SV 每次更新的学习率 Delta (Δ)

% 保存参数结构体
save('algorithm_parameters.mat', 'params');
disp('全局参数已写入 config_parameters.m 并保存到 algorithm_parameters.mat.');