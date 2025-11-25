function [X, Y, FeatureNames] = data_loader(path1, path2, dataset_name)
% DATA_LOADER 统一数据加载接口
% 修复版：确保 SONAR 使用 readtable，防止 fopen 错误

switch upper(dataset_name)
    
    case 'SECOM'
        try
            X = dlmread(path1, ' '); 
            X(isnan(X)) = 0;
            if all(X(:, end) == 0), X = X(:, 1:end-1); end
            
            fileID = fopen(path2, 'r');
            % 如果路径错误，fopen 返回 -1，这里加个检查防止报错难懂
            if fileID == -1
                error('无法打开标签文件，请检查路径: %s', path2);
            end
            label_data = textscan(fileID, '%s %s', 'Delimiter', '', 'Whitespace', '\n', 'CollectOutput', true, 'EmptyValue', NaN);
            fclose(fileID);
            
            raw_labels = label_data{1}(:, 1); 
            raw_labels = raw_labels(~cellfun('isempty', raw_labels));
            Y = categorical(raw_labels);
            if size(X, 1) ~= length(Y), error('样本数不匹配'); end
            disp([' > SECOM 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:SecomError', ME.message); end

    case 'SPECTF'
        try
             train = dlmread(path1, ',');
             test = dlmread(path2, ',');
             data = [train; test];
             Y = categorical(cellstr(num2str(data(:,1))));
             X = data(:, 2:end);
             disp([' > SPECTF 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:SpectfError', ME.message); end

    case 'SONAR'
        % ★★★ 修复重点：使用 readtable，不使用 fopen ★★★
        try
            disp(['   正在读取: ', path1]);
            opts = detectImportOptions(path1, 'FileType', 'text');
            opts.VariableNamesLine = 0; 
            T = readtable(path1, opts);
            
            % 分离特征和标签
            X = table2array(T(:, 1:60));
            raw_labels = T{:, 61}; 
            
            Y_cell = cell(length(raw_labels), 1);
            for i = 1:length(raw_labels)
                lbl = strtrim(string(raw_labels(i))); 
                if strcmpi(lbl, 'M'), Y_cell{i} = '1'; 
                elseif strcmpi(lbl, 'R'), Y_cell{i} = '-1';
                else, Y_cell{i} = char(lbl); end
            end
            Y = categorical(Y_cell);
            disp([' > SONAR 加载成功。N=', num2str(size(X,1))]);
        catch ME
            error('data_loader:SonarError', ['加载失败，请检查路径是否存在。\n错误详情: ' ME.message]); 
        end

    case 'GAIT'
        try
            file_content = load(path1);
            vars = fieldnames(file_content);
            X=[]; Y=[];
            for i = 1:length(vars)
                val = file_content.(vars{i});
                [r, c] = size(val);
                if r == 48 && c == 321, X = val;
                elseif (r == 48 && c == 1) || (r == 1 && c == 48)
                    Y = val; if r==1, Y=Y'; end
                end
            end
            if isempty(X) || isempty(Y), error('Gait 变量未找到'); end
            X = double(X); Y = categorical(Y);
            disp([' > Gait 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:GaitError', ME.message); end

    case 'MADELON'
        try
            X = dlmread(path1); 
            Y_raw = dlmread(path2);
            if size(X, 1) ~= size(Y_raw, 1)
                if size(X, 2) == size(Y_raw, 1), X = X'; else, error('维度不匹配'); end
            end
            Y = categorical(Y_raw);
            disp([' > Madelon 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:MadelonError', ME.message); end
        
    case 'PERIOD_CHANGER'
        try
            opts = detectImportOptions(path1, 'FileType', 'text');
            T = readtable(path1, opts);
            X = table2array(T(:, 1:end-1));
            Y = categorical(T{:, end});
            if size(X, 2) ~= 1177, warning('特征数异常'); end
            disp([' > Period Changer 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:PeriodError', ME.message); end

    case 'TOXICITY'
        try
            opts = detectImportOptions(path1, 'FileType', 'text');
            opts.VariableNamesLine = 0;
            T = readtable(path1, opts);
            X = table2array(T(:, 1:end-1));
            Y = categorical(T{:, end});
            if size(X, 2) == 1204, X(:,1)=[]; end 
            disp([' > Toxicity 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:ToxicityError', ME.message); end

    case 'MICRO_MASS'
        try
            opts = detectImportOptions(path1, 'FileType', 'text');
            if length(opts.VariableNames) <= 1, opts.Delimiter = ';'; end
            T_X = readtable(path1, opts);
            if iscell(T_X{1,1}) || isstring(T_X{1,1}), X = table2array(T_X(:, 2:end));
            else, X = table2array(T_X); end
            
            opts_y = detectImportOptions(path2, 'FileType', 'text');
            if length(opts_y.VariableNames) <= 1, opts_y.Delimiter = ';'; end
            T_Y = readtable(path2, opts_y);
            if ismember('Species', T_Y.Properties.VariableNames), raw = T_Y.Species;
            else, raw = T_Y{:, end}; end
            Y = categorical(raw);
            if size(X, 2) > 1300, X = X(:, 1:1300); end
            disp([' > Micro-Mass 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:MicroMassError', ME.message); end

    case 'INTERNET_ADS'
        try
            opts = detectImportOptions(path1, 'FileType', 'text', 'TreatAsEmpty', {'?'});
            opts.VariableNamesLine = 0; 
            T = readtable(path1, opts);
            X = table2array(T(:, 1:end-1));
            if any(isnan(X(:))), X(isnan(X)) = 0; end
            Y = categorical(T{:, end});
            disp([' > Internet Ads 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:AdsError', ME.message); end

    case 'COLON'
        try
            file = load(path1); vars = fieldnames(file); X=[]; Y=[];
            for i=1:length(vars)
                val=file.(vars{i}); [r,c]=size(val);
                if r==62&&c==2000, X=val; elseif r==2000&&c==62, X=val'; end
                if ((r==62&&c==1)||(r==1&&c==62))&&numel(val)==62, Y=val; if r==1, Y=Y'; end; end
            end
            if isempty(X)||isempty(Y), if isfield(file,'X'),X=file.X; end; if isfield(file,'Y'),Y=file.Y; end; end
            X=double(X); Y=categorical(Y);
            disp([' > Colon 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:ColonError', ME.message); end

    case 'LUNG_CANCER'
        try
            file = load(path1); vars = fieldnames(file); X=[]; Y=[];
            for i=1:length(vars)
                val=file.(vars{i}); [r,c]=size(val);
                if r==203&&c==3312, X=val; elseif r==3312&&c==203, X=val'; end
                if ((r==203&&c==1)||(r==1&&c==203))&&numel(val)==203, Y=val; if r==1, Y=Y'; end; end
            end
            X=double(X); Y=categorical(Y);
            disp([' > Lung Cancer 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:LungError', ME.message); end

    case 'GISETTE'
        try
            X = dlmread(path1); 
            Y = categorical(dlmread(path2));
            if size(X,1)~=size(Y,1), error('维度不符'); end
            disp([' > Gisette 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:GisetteError', ME.message); end

    case 'LEUKEMIA'
        try
            file = load(path1); vars = fieldnames(file); X=[]; Y=[];
            for i=1:length(vars)
                val=file.(vars{i}); [r,c]=size(val);
                if r==72&&c>1000, X=val; elseif c==72&&r>1000, X=val'; end
                if ((r==72&&c==1)||(r==1&&c==72)), Y=val; if r==1, Y=Y'; end; end
            end
            X=double(X); Y=categorical(Y);
            disp([' > Leukemia 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:LeukemiaError', ME.message); end

    case 'MUSK'
        try
            opts = detectImportOptions(path1, 'FileType', 'text');
            opts.VariableNamesLine = 0; 
            T = readtable(path1, opts);
            X = table2array(T(:, 3:end-1)); % 去除前2列ID
            Y = categorical(T{:, end});
            disp([' > Musk 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:MuskError', ME.message); end

    case 'LSVT'
        try
            optsX = detectImportOptions(path1, 'Sheet', 'Data');
            X = table2array(readtable(path1, optsX));
            optsY = detectImportOptions(path1, 'Sheet', 'Binary response');
            Y = categorical(table2array(readtable(path1, optsY)));
            disp([' > LSVT 加载成功。N=', num2str(size(X,1))]);
        catch ME, error('data_loader:LSVTError', ME.message); end

    case 'ARRHYTHMIA'
        try
            opts = detectImportOptions(path1, 'FileType', 'text', 'TreatAsEmpty', {'?'});
            opts.VariableNamesLine = 0; 
            T = readtable(path1, opts);
            
            % 提取特征
            X = table2array(T(:, 1:end-1));
            
            % 处理缺失值
            if any(isnan(X(:)))
                X(isnan(X)) = 0; 
            end
            
            % --- 提取标签并转为二分类 ---
            % Arrhythmia 原始标签是 1~16
            raw_labels = T{:, end};
            if ~isnumeric(raw_labels)
                % 如果读出来是字符串，先转数字
                raw_labels = str2double(string(raw_labels));
            end
            
            % 初始化新的二元标签
            Y_binary = cell(length(raw_labels), 1);
            
            for i = 1:length(raw_labels)
                if raw_labels(i) == 1
                    % Class 1 是正常
                    Y_binary{i} = 'Normal'; 
                else
                    % Class 2-16 都是异常
                    Y_binary{i} = 'Arrhythmia'; 
                end
            end
            
            Y = categorical(Y_binary);
            % ---------------------------
            
            disp([' > Arrhythmia 加载成功 (已转为二分类)。N=', num2str(size(X,1))]);
            
        catch ME
            error('data_loader:ArrhythmiaError', ME.message); 
        end

    otherwise
        error('data_loader:InvalidDataset', '不支持的数据集名称: %s', dataset_name);
end

% --- 后处理：移除常数特征 ---
if ~isempty(X)
    feature_variances = var(X, 0, 1);
    non_constant_features = feature_variances > 1e-6;
    X = X(:, non_constant_features);
    D_total = size(X, 2);
    FeatureNames = cell(1, D_total);
    for i = 1:D_total, FeatureNames{i} = ['Feature_', num2str(i)]; end
end

end