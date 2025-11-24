function [X, Y, FeatureNames] = data_loader(path1, path2, dataset_name)
% DATA_LOADER 根据 dataset_name 加载和预处理数据。
%
% 输入:
%   path1: [string] 路径 1 (SECOM: data; SPECTF: train)
%   path2: [string] 路径 2 (SECOM: labels; SPECTF: test)
%   dataset_name: [string] 数据集名称 ('SECOM' 或 'SPECTF')
%
% 输出:
%   X: [N x D double] 处理后的特征矩阵。
%   Y: [N x 1 categorical] 分类标签向量 (+1, -1)。
%   FeatureNames: [cell array] 特征名称。

% --- 1. 根据数据集名称分发加载逻辑 ---
switch upper(dataset_name)
    
    case 'SECOM'
        % --- SECOM 加载逻辑 (大样本，高维，标签分离) ---
        data_file_path = path1;
        labels_file_path = path2;
        
        % 1.1. 加载特征数据
        try
            X_raw = dlmread(data_file_path, ' '); 
            disp(['  > 成功加载特征数据：', data_file_path]);
        catch ME
            error('data_loader:FeatureLoadError', '加载特征文件时出错: %s', ME.message);
        end

        % 1.2. 处理特征数据中的 NaN (零填充)
        X = X_raw;
        X(isnan(X)) = 0;
        
        % 1.3. 移除冗余的最后一列 (特征 591)
        if all(X(:, end) == 0)
            warning('data_loader:RedundantFeature', 'SECOM 数据集最后一列（特征 591）为冗余零值，已移除。');
            X = X(:, 1:end-1); % 移除最后一列
        end
        
        % 1.4. 加载标签数据
        try
            fileID = fopen(labels_file_path, 'r');
            label_data = textscan(fileID, '%s %s', 'Delimiter', '', 'Whitespace', '\n', 'CollectOutput', true, 'EmptyValue', NaN);
            fclose(fileID);

            raw_labels = label_data{1}(:, 1); 
            raw_labels = raw_labels(~cellfun('isempty', raw_labels)); % 清理空行

            disp(['  > 成功加载标签数据：', labels_file_path]);
        catch ME
            error('data_loader:LabelLoadError', '加载标签文件时出错: %s', ME.message);
        end
        
        % 1.5. 标签转换 (SECOM 原本就是 +1/-1 字符串，直接转换)
        Y_cell = raw_labels;
        Y = categorical(Y_cell);
        
        % 1.6. 检查样本数量
        if size(X, 1) ~= length(Y)
            error('data_loader:SampleMismatch', '特征矩阵 (%d) 和标签向量 (%d) 的样本数量不匹配。', size(X, 1), length(Y));
        end

 case 'SONAR'
        % --- SONAR 加载逻辑 (读取 .all-data 文件) ---
        try
            % 关键点：加上 'FileType', 'text'，这样 MATLAB 就能读 .all-data 了
            opts = detectImportOptions(path1, 'FileType', 'text');
            opts.VariableNamesLine = 0; % 告诉 MATLAB 第一行不是表头
            opts.DataLines = [1 Inf];   % 从第一行开始读数据
            
            % 读取数据表
            T = readtable(path1, opts);
            
            % 2. 分离特征 X (前60列)
            % Sonar 数据全是数字，除了最后一列
            X = table2array(T(:, 1:60));
            
            % 3. 分离并转换标签 Y (第61列)
            % 获取最后一列数据 (通常是 cell array 或 string array)
            raw_labels = T{:, 61}; 
            
            % 初始化 Y 向量
            Y_cell = cell(length(raw_labels), 1);
            
            % 转换标签：M (Mine) -> 1, R (Rock) -> -1
            for i = 1:length(raw_labels)
                % 确保转为字符串并去除空格
                lbl = strtrim(string(raw_labels(i))); 
                
                if strcmpi(lbl, 'M')
                    Y_cell{i} = '1';  % 水雷
                elseif strcmpi(lbl, 'R')
                    Y_cell{i} = '-1'; % 岩石
                else
                    % 万一读出其他奇怪的东西，保留原样方便报错检查
                    Y_cell{i} = char(lbl);
                end
            end
            
            % 转为 categorical 类型
            Y = categorical(Y_cell);
            
            disp([' > 成功加载 SONAR 数据。样本数: ', num2str(size(X,1)), ...
                  ', 特征数: ', num2str(size(X,2))]);
              
        catch ME
            % 详细报错，方便你调试
            error('data_loader:SonarLoadError', ...
                  ['SONAR 数据加载失败。\n' ...
                   '1. 请确认路径正确: %s\n' ...
                   '2. 请确认文件是 UCI 原始格式 (逗号分隔, 最后一列是 M/R)\n' ...
                   'MATLAB 错误信息: %s'], path1, ME.message);
        end
        
    otherwise
        error('data_loader:InvalidDataset', '不支持的数据集名称: %s', dataset_name);
end
% ====================================================================
% 2.5移除常数/零方差特征 (兼容 Naive Bayes 和其他敏感模型)
% ====================================================================
if ~isempty(X)
    % 计算每个特征的方差
    feature_variances = var(X, 0, 1); % 0 for sample variance, 1 for dimension
    % 找到方差不为零的特征索引
    non_constant_features = feature_variances > 1e-6; % 使用一个小的容差
    
    D_before = size(X, 2);
    X = X(:, non_constant_features);
    D_after = size(X, 2);
    
    if D_before > D_after
        fprintf('  > 已移除 %d 个常数或零方差特征。\n', D_before - D_after);
    end
end

% --- 2.6 最终输出和检查 ---

D_total = size(X, 2);

%3 创建特征名称 (适用于任何数据集)
FeatureNames = cell(1, D_total);
for i = 1:D_total
    FeatureNames{i} = ['Feature_', num2str(i)];
end

disp(['  > 数据加载与预处理完成。样本数: ', num2str(size(X, 1)), '，特征数: ', num2str(D_total)]);

end