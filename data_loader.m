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

        
    case 'SPECTF'
        % --- SPECTF 加载逻辑 (小样本，低维，训练/测试集分离，标签是 0/1) ---
        train_file_path = path1;
        test_file_path = path2;
        
        % 2.1. 加载训练集和测试集数据 (假设分隔符是逗号或空格)
        
        % 辅助加载函数，用于尝试不同的分隔符
        load_func = @(file_path) dlmread(file_path, ',');
        try Train_Data = load_func(train_file_path);
        catch, load_func = @(file_path) dlmread(file_path, ' '); Train_Data = load_func(train_file_path); end
        
        try Test_Data = load_func(test_file_path);
        catch, Test_Data = load_func(test_file_path); end
        
        disp(['  > 成功加载 SPECTF 训练集：', train_file_path]);
        disp(['  > 成功加载 SPECTF 测试集：', test_file_path]);
        
        % 2.2. 合并数据
        Combined_Data = [Train_Data; Test_Data]; % 垂直合并

        % 2.3. 划分特征 X 和标签 Y (SPECTF 标签在第一列, 0/1)
        Y_raw = Combined_Data(:, 1);        % 标签是第一列 (0 或 1)
        X = Combined_Data(:, 2:end);        % 特征是第二列到最后一列
        
        % 2.4. 标签转换 (将 0/1 转换为 +1/-1 categorical)
        Y_cell = cell(length(Y_raw), 1);
        for i = 1:length(Y_raw)
            if Y_raw(i) == 1
                Y_cell{i} = '+1'; % 标签 1
            else
                Y_cell{i} = '-1'; % 标签 0
            end
        end
        Y = categorical(Y_cell);
        
    otherwise
        error('data_loader:InvalidDataset', '不支持的数据集名称: %s', dataset_name);
end


% --- 2. 最终输出和检查 ---

D_total = size(X, 2);

% 5. 创建特征名称 (适用于任何数据集)
FeatureNames = cell(1, D_total);
for i = 1:D_total
    FeatureNames{i} = ['Feature_', num2str(i)];
end

disp(['  > 数据加载与预处理完成。样本数: ', num2str(size(X, 1)), '，特征数: ', num2str(D_total)]);

end