function Plot_ParetoFront_Comparison_With_NewAlgs(mode)
% Plot the final Pareto fronts for the proposed method and comparison methods.
% The first six algorithms follow the old AccSlect mapping used by the
% convergence figure. FPPFS and JEMMOEA are read from the selected-run table.

clc; close all;

if nargin < 1 || isempty(mode)
    mode = "preview";
end
mode = lower(string(mode));
exportFinal = any(mode == ["final", "export", "save"]);

oldRoot = 'D:\code\Results\PSlect';
newRoot = 'D:\code\Results\DBRESULT';
selectedCsv = fullfile(newRoot, 'MainComparison_Tables', 'SelectedRuns_PaperFigures.csv');
outDir = 'D:\\code\\Results\\PaperFigures\\f6';
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

datasets = {
    'BASEHOCK'
    'Colon'
    'Internet_Ads'
    'ISOLET'
    'Lung_Cancer'
    'Micro_Mass'
    'PCMAC'
    'Period_Changer'
    'Sonar'
    'TOX-171'
    'Toxicity'
    'warpPIE10P'
};

algLabels = {
    'MT-GF-MoFS'
    'NSGA-II'
    'MF-CSO'
    'MEL'
    'MOEA-ISa'
    'SM-MOEA'
    'FPPFS'
    'JEMMOEA'
};

oldFileIndices = containers.Map( ...
    {'MT-GF-MoFS', 'NSGA-II', 'MF-CSO', 'MEL', 'MOEA-ISa', 'SM-MOEA'}, ...
    {1, 4, 5, 6, 7, 8});

newLabels = ["FPPFS", "JEMMOEA"];
T = readtable(selectedCsv, 'TextType', 'string');

colors = lines(numel(algLabels));
colors(1,:) = [0.8500 0.1000 0.1000];
lineStyles = {'-','--','-.',':','-','--','-.',':'};
markers = {'o','s','^','d','v','>','p','h'};
lineWidths = ones(numel(algLabels), 1) * 1.05;
lineWidths(1) = 1.8;
markerSizes = ones(numel(algLabels), 1) * 3.2;
markerSizes(1) = 4.5;

set(groot, 'defaultAxesFontName', 'Arial');
set(groot, 'defaultTextFontName', 'Arial');
set(groot, 'defaultAxesFontSize', 8);
warning('off', 'MATLAB:load:unableToReadClassDefinitions');

fig = figure('Color','w', 'Units','pixels', 'Position',[40 40 2500 1500], 'Visible','off');
tl = tiledlayout(fig, 3, 4, 'TileSpacing','compact', 'Padding','compact');

statDataset = strings(0,1);
statAlgorithm = strings(0,1);
statMatFile = strings(0,1);
statNumPoints = zeros(0,1);
statMinError = zeros(0,1);
statMinRatio = zeros(0,1);

for d = 1:numel(datasets)
    ds = datasets{d};
    ax = nexttile(tl);
    hold(ax, 'on');
    box(ax, 'on');
    grid(ax, 'on');

    allX = [];
    allY = [];
    mtX = [];
    mtY = [];

    for a = 1:numel(algLabels)
        alg = algLabels{a};
        matFile = resolveMatFile(ds, alg, oldRoot, oldFileIndices, newLabels, T);
        if strlength(matFile) == 0 || ~isfile(matFile)
            fprintf('[warn] missing MAT: %s / %s\n', ds, alg);
            continue;
        end

        pf = loadParetoFront(matFile, ds);
        if isempty(pf)
            fprintf('[warn] empty PF: %s / %s\n', ds, alg);
            continue;
        end

        pf = sortrows(pf, 1);
        x = pf(:, 1);
        y = pf(:, 2);
        allX = [allX; x]; %#ok<AGROW>
        allY = [allY; y]; %#ok<AGROW>
        if strcmp(alg, 'MT-GF-MoFS')
            mtX = x;
            mtY = y;
        end

        plot(ax, x, y, ...
            'LineStyle', 'none', ...
            'LineWidth', lineWidths(a), ...
            'Color', colors(a,:), ...
            'Marker', markers{a}, ...
            'MarkerSize', markerSizes(a), ...
            'MarkerFaceColor', 'w', ...
            'DisplayName', alg);

        statDataset(end+1, 1) = string(ds); %#ok<AGROW>
        statAlgorithm(end+1, 1) = string(alg); %#ok<AGROW>
        statMatFile(end+1, 1) = string(matFile); %#ok<AGROW>
        statNumPoints(end+1, 1) = size(pf, 1); %#ok<AGROW>
        statMinError(end+1, 1) = min(y); %#ok<AGROW>
        statMinRatio(end+1, 1) = min(x); %#ok<AGROW>
    end

    title(ax, ds, 'Interpreter','none', 'FontSize', 9);
    [xLim, yLim] = chooseParetoLimits(ds, allX, allY, mtX, mtY);
    xlim(ax, xLim);
    ylim(ax, yLim);

    if d > 8
        xlabel(ax, 'Selected Feature Ratio');
    else
        xlabel(ax, '');
    end
    if mod(d-1, 4) == 0
        ylabel(ax, 'Classification Error Rate');
    else
        ylabel(ax, '');
    end
    ax.FontSize = 7;
end

drawTopLegend(fig, algLabels, colors, lineStyles, lineWidths, markers, markerSizes);

if exportFinal
    outPng = fullfile(outDir, 'Figure6_PSlect_ParetoFront_8Algorithms_Final.png');
    outPdf = fullfile(outDir, 'Figure6_PSlect_ParetoFront_8Algorithms_Final.pdf');
    outFig = fullfile(outDir, 'Figure6_PSlect_ParetoFront_8Algorithms_Final.fig');
    exportgraphics(fig, outPng, 'Resolution', 800);
    exportgraphics(fig, outPdf, 'ContentType', 'vector');
    savefig(fig, outFig);
else
    outPng = fullfile(outDir, 'Figure6_PSlect_ParetoFront_8Algorithms_Draft.png');
    outFig = fullfile(outDir, 'Figure6_PSlect_ParetoFront_8Algorithms_Draft.fig');
    exportgraphics(fig, outPng, 'Resolution', 260);
    savefig(fig, outFig);
end

statTable = table(statDataset, statAlgorithm, statNumPoints, statMinError, statMinRatio, statMatFile, ...
    'VariableNames', {'Dataset','Algorithm','NumPoints','MinError','MinFeatureRatio','MatFile'});
writetable(statTable, fullfile(outDir, 'Figure6_PSlect_ParetoFront_Source_Check.csv'), 'Encoding', 'UTF-8');

fprintf('Pareto figure saved:\n%s\n%s\n', outPng, outFig);
if exportFinal
    fprintf('Vector PDF saved with the same base name.\n');
end
fprintf('Source check saved:\n%s\n', fullfile(outDir, 'Figure6_PSlect_ParetoFront_Source_Check.csv'));
end

function matFile = resolveMatFile(ds, alg, oldRoot, oldFileIndices, newLabels, T)
    matFile = "";
    algStr = string(alg);
    if any(newLabels == algStr)
        row = T(strcmp(T.Dataset, ds) & strcmp(T.Algorithm, algStr), :);
        if ~isempty(row)
            matFile = string(row.MatFile(1));
        end
        return;
    end

    if isKey(oldFileIndices, alg)
        matFile = string(fullfile(oldRoot, ds, sprintf('%d.mat', oldFileIndices(alg))));
    end
end

function drawTopLegend(fig, labels, colors, lineStyles, lineWidths, markers, markerSizes)
    legendAx = axes(fig, 'Position', [0.03 0.957 0.94 0.035], 'Visible', 'off');
    hold(legendAx, 'on');
    for a = 1:numel(labels)
        plot(legendAx, nan, nan, ...
            'LineStyle', 'none', ...
            'LineWidth', lineWidths(a), ...
            'Color', colors(a,:), ...
            'Marker', markers{a}, ...
            'MarkerSize', markerSizes(a), ...
            'MarkerFaceColor', 'w', ...
            'DisplayName', labels{a});
    end
    lgd = legend(legendAx, 'show', ...
        'Orientation','horizontal', ...
        'NumColumns', numel(labels), ...
        'FontSize', 8, ...
        'Box','off');
    lgd.Units = 'normalized';
    lgd.Position = [0.05 0.972 0.90 0.025];
end

function pf = loadParetoFront(matFile, dataset)
    pf = [];
    try
        preferred = {'Final_Pareto_Solutions','Final_PF','Final_Pareto', ...
            'Strict_Pareto_Points','Pareto_Front_Points','All_Unique_Points', ...
            'ParetoFront','PF','Archive','Global_Archive','ParetoFront_History'};
        info = whos('-file', matFile);
        names = {info.name};
        for k = 1:numel(preferred)
            if any(strcmp(names, preferred{k}))
                S = load(matFile, preferred{k});
                obj = S.(preferred{k});
                if strcmp(preferred{k}, 'ParetoFront_History')
                    obj = lastHistoryPF(obj);
                end
                pf = convertPF(obj, dataset);
                if ~isempty(pf)
                    break;
                end
            end
        end
        pf = cleanPF(pf);
    catch ME
        fprintf('[warn] failed to read PF from %s: %s\n', matFile, ME.message);
        pf = [];
    end
end

function item = lastHistoryPF(history)
    item = [];
    if iscell(history)
        for i = numel(history):-1:1
            if ~isempty(history{i})
                item = history{i};
                return;
            end
        end
    elseif isstruct(history)
        item = history(end);
    elseif isnumeric(history)
        item = history;
    end
end

function pf = convertPF(obj, dataset)
    pf = [];
    if isempty(obj)
        return;
    end

    if isnumeric(obj)
        pf = numericPF(obj, dataset);
        return;
    end

    if iscell(obj)
        parts = cellfun(@(x) convertPF(x, dataset), obj, 'UniformOutput', false);
        parts = parts(~cellfun(@isempty, parts));
        if ~isempty(parts)
            pf = vertcat(parts{:});
        end
        return;
    end

    if isstruct(obj)
        names = fieldnames(obj);
        lowerNames = lower(names);
        n = numel(obj);
        ratio = nan(n, 1);
        err = nan(n, 1);

        for i = 1:n
            err(i) = readError(obj(i), names, lowerNames);
            ratio(i) = readFeatureRatio(obj(i), names, lowerNames, dataset);
        end

        if any(isfinite(err)) && any(isfinite(ratio))
            pf = [ratio, err];
            return;
        end

        preferred = {'Final_Pareto_Solutions','Final_PF','Final_Pareto','PF','ParetoFront','Archive'};
        for k = 1:numel(preferred)
            if isfield(obj, preferred{k})
                pf = convertPF(obj.(preferred{k}), dataset);
                return;
            end
        end
    end
end

function err = readError(s, names, lowerNames)
    err = nan;
    idx = find(strcmp(lowerNames, 'error'), 1);
    if ~isempty(idx)
        err = double(s.(names{idx}));
        return;
    end

    idx = find(strcmp(lowerNames, 'acc') | strcmp(lowerNames, 'accuracy'), 1);
    if ~isempty(idx)
        err = 1 - double(s.(names{idx}));
        return;
    end

    idx = find(strcmp(lowerNames, 'cost'), 1);
    if ~isempty(idx)
        cost = double(s.(names{idx}));
        if numel(cost) >= 1
            err = cost(1);
        end
    end
end

function ratio = readFeatureRatio(s, names, lowerNames, dataset)
    ratio = nan;
    dim = getFeatureDim(dataset);

    count = nan;
    idx = find(strcmp(lowerNames, 'count') | strcmp(lowerNames, 'featcount') | ...
        strcmp(lowerNames, 'numfeatures') | strcmp(lowerNames, 'featurecount'), 1);
    if ~isempty(idx)
        count = double(s.(names{idx}));
    end

    idx = find(strcmp(lowerNames, 'features') | strcmp(lowerNames, 'position') | strcmp(lowerNames, 'x'), 1);
    if ~isempty(idx)
        feat = s.(names{idx});
        if isnumeric(feat) || islogical(feat)
            featVec = feat(:);
            if numel(featVec) > 1 && all(featVec == 0 | featVec == 1)
                dim = numel(featVec);
                if isnan(count)
                    count = nnz(featVec);
                end
            elseif isnan(count)
                count = numel(featVec);
            end
        end
    end

    if isfinite(count)
        if count <= 1
            ratio = count;
        elseif isfinite(dim) && dim > 0
            ratio = count / dim;
        else
            ratio = count;
        end
        return;
    end

    idx = find(strcmp(lowerNames, 'cost'), 1);
    if ~isempty(idx)
        cost = double(s.(names{idx}));
        if numel(cost) >= 2
            if cost(2) <= 1
                ratio = cost(2);
            elseif isfinite(dim) && dim > 0
                ratio = cost(2) / dim;
            else
                ratio = cost(2);
            end
        end
    end
end

function pf = numericPF(x, dataset)
    pf = [];
    if isempty(x)
        return;
    end
    x = double(x);
    if isvector(x)
        x = x(:)';
    end
    if size(x, 2) < 2
        return;
    end

    c1 = x(:, 1);
    c2 = x(:, 2);
    dim = getFeatureDim(dataset);

    if all(c1 >= 0 & c1 <= 1.1) && all(c2 >= 0 & c2 <= 1.1)
        pf = [c2, c1];
    elseif all(c1 >= 0 & c1 <= 1.1) && isfinite(dim) && dim > 0
        pf = [c2 ./ dim, c1];
    elseif all(c2 >= 0 & c2 <= 1.1) && isfinite(dim) && dim > 0
        pf = [c1 ./ dim, c2];
    else
        pf = [c1, c2];
    end
end

function pf = cleanPF(pf)
    if isempty(pf)
        return;
    end
    pf = double(pf(:, 1:2));
    pf = pf(all(isfinite(pf), 2), :);
    pf = pf(pf(:,1) >= 0 & pf(:,2) >= 0, :);
    pf = pf(pf(:,1) <= 1.05 & pf(:,2) <= 1.05, :);
    pf = unique(pf, 'rows', 'stable');
    pf = pf(nondominatedMin(pf), :);
end

function nd = nondominatedMin(points)
    n = size(points, 1);
    nd = true(n, 1);
    for i = 1:n
        if ~nd(i)
            continue;
        end
        dominatedByJ = all(points <= points(i,:), 2) & any(points < points(i,:), 2);
        dominatedByJ(i) = false;
        if any(dominatedByJ)
            nd(i) = false;
        end
    end
end

function [xLim, yLim] = chooseParetoLimits(dataset, allX, allY, mtX, mtY)
    manual = manualParetoLimits(dataset);
    if ~isempty(manual)
        xLim = manual(1:2);
        yLim = manual(3:4);
        return;
    end

    if isempty(allX) || isempty(allY)
        xLim = [0, 1];
        yLim = [0, 1];
        return;
    end

    xMax = robustUpper(allX, mtX, 1);
    yMax = robustUpper(allY, mtY, 1);
    xLim = [0, max(0.03, xMax)];
    yLow = max(0, min(allY) - 0.06 * rangeSafe(allY));
    yLim = [yLow, max(yLow + 0.01, yMax)];
end

function lim = manualParetoLimits(dataset)
    % 这张图是给论文看的，坐标范围按数据集微调，避免远端点把主体前沿压扁。
    switch lower(strrep(dataset, '-', '_'))
        case 'basehock'
            lim = [0, 0.18, 0.06, 0.52];
        case 'colon'
            lim = [0, 0.06, 0.00, 0.30];
        case 'internet_ads'
            lim = [0, 0.18, 0.00, 0.46];
        case 'isolet'
            lim = [0, 0.22, 0.06, 0.45];
        case 'lung_cancer'
            lim = [0, 0.08, 0.00, 0.18];
        case 'micro_mass'
            lim = [0, 0.20, 0.22, 0.86];
        case 'pcmac'
            lim = [0, 0.10, 0.12, 0.50];
        case 'period_changer'
            lim = [0, 0.08, 0.16, 0.36];
        case 'sonar'
            lim = [0, 0.25, 0.07, 0.28];
        case 'tox_171'
            lim = [0, 0.08, 0.08, 0.72];
        case 'toxicity'
            lim = [0, 0.05, 0.23, 0.37];
        case 'warppie10p'
            lim = [0, 0.06, 0.00, 0.66];
        otherwise
            lim = [];
    end
end

function upper = robustUpper(values, focusValues, hardMax)
    values = values(isfinite(values));
    focusValues = focusValues(isfinite(focusValues));
    if isempty(values)
        upper = hardMax;
        return;
    end

    sortedVals = sort(values(:));
    idx = max(1, min(numel(sortedVals), ceil(0.94 * numel(sortedVals))));
    p94 = sortedVals(idx);
    if isempty(focusValues)
        focusMax = 0;
    else
        focusMax = max(focusValues);
    end
    upper = max([p94 * 1.12, focusMax * 1.25, 0.03]);
    upper = min(hardMax, upper);
end

function r = rangeSafe(v)
    if isempty(v)
        r = 1;
    else
        r = max(v) - min(v);
        if r <= 0
            r = max(0.01, max(v) * 0.1);
        end
    end
end

function dim = getFeatureDim(dataset)
    switch lower(strrep(dataset, '-', '_'))
        case 'sonar'
            dim = 60;
        case 'isolet'
            dim = 617;
        case 'period_changer'
            dim = 1177;
        case 'toxicity'
            dim = 1203;
        case 'micro_mass'
            dim = 1300;
        case 'internet_ads'
            dim = 1558;
        case 'colon'
            dim = 2000;
        case 'warppie10p'
            dim = 2420;
        case 'pcmac'
            dim = 3289;
        case 'lung_cancer'
            dim = 3312;
        case 'basehock'
            dim = 4862;
        case 'tox_171'
            dim = 5748;
        otherwise
            dim = nan;
    end
end
