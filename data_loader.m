% data_loader.m

function [X, Y, FeatureNames] = data_loader(data_file_path, labels_file_path)
% DATA_LOADER 加载 SECOM 数据集和标签，并进行基本预处理。
%
% 输入:
%   data_file_path: [string] SECOM 数据集文件 (.data) 的路径。
%   labels_file_path: [string] SECOM 标签文件 (.data) 的路径。
%
% 输出:
%   X: [N x D double] 处理后的特征矩阵 (N=1567, D=590，去除最后一列 NaN 特征)。
%   Y: [N x 1 categorical] 分类标签向量 (+1, -1)。
%   FeatureNames: [cell array] 特征名称 (例如：{'Feature_1', 'Feature_2', ...})。

    % 1. 加载特征数据 (SECOM 数据集文件)
    try
        % 使用 dlmread 读取纯文本数据。SECOM 文件通常使用空格作为分隔符。
        X_raw = dlmread(data_file_path, ' '); 
        disp(['  > 成功加载特征数据：', data_file_path]);
    catch ME
        error('data_loader:FeatureLoadError', '加载特征文件时出错: %s', ME.message);
    end

    % 2. 处理特征数据中的 NaN (缺失值)
    % SECOM 数据集包含大量 NaN，通常使用行均值或零填充。
    % 这里我们使用一个简单的零填充策略，因为 NaN 在特征选择中通常被视为信息。
    X = X_raw;
    X(isnan(X)) = 0;
    
    % 检查 SECOM 的特点：原始矩阵是 1567x591。但最后一列通常是全零/全NaN
    % 发现最后一列数据通常是冗余的 (全零或全 Nan)，在很多实现中被移除。
    % 检查最后一列是否都是 0
    if all(X(:, end) == 0)
        warning('data_loader:RedundantFeature', 'SECOM 数据集最后一列（特征 591）为冗余零值，已移除。');
        X = X(:, 1:end-1); % 移除最后一列
    end
    
 % 3. 加载标签数据 (SECOM 标签文件)
    try
        % 标签文件格式：[标签] [日期时间戳]
        % MATLAB 的 textscan 更适合读取混合了数值和字符串的文本文件
        fileID = fopen(labels_file_path, 'r');
        % 注意：这里读取两列字符串
        label_data = textscan(fileID, '%s %s', 'Delimiter', '', 'Whitespace', '\n', 'CollectOutput', true, 'EmptyValue', NaN);
        fclose(fileID);

        % 标签本身是第一列
        raw_labels = label_data{1}(:, 1); 
        
        % 额外的清理：去除可能来自文件末尾的空字符串，确保与数据行数匹配
        raw_labels = raw_labels(~cellfun('isempty', raw_labels));

        disp(['  > 成功加载标签数据：', labels_file_path]);
    catch ME
        error('data_loader:LabelLoadError', '加载标签文件时出错: %s', ME.message);
    end
    
    % 4. 处理标签数据
    % SECOM 标签是 +1 (通过) 和 -1 (失败)。
    Y_cell = raw_labels;
    
    % 转换为 MATLAB 的 categorical 类型（分类器评估需要）
    % 确保 Y 是列向量
    Y = categorical(Y_cell);

    % 检查 X 和 Y 的样本数量是否一致 (现在 Y 的长度应该已经修正为 1567)
    if size(X, 1) ~= length(Y)
        error('data_loader:SampleMismatch', '特征矩阵 (%d) 和标签向量 (%d) 的样本数量不匹配。', size(X, 1), length(Y));
    end

    % 5. 创建特征名称 (可选，但推荐)
    D = size(X, 2);
    FeatureNames = cell(1, D);
    for i = 1:D
        FeatureNames{i} = ['Feature_', num2str(i)];
    end

    disp(['  > 数据加载与预处理完成。样本数: ', num2str(size(X, 1)), '，特征数: ', num2str(D)]);

end