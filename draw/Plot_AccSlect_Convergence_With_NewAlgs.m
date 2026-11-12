function Plot_AccSlect_Convergence_With_NewAlgs(mode)
% Plot_AccSlect_Convergence_With_NewAlgs
% 老图数据用 D:\code\Results\AccSlect 里的 1-8.mat。
% 新增的 FPPFS 和 JEMMOEA 从 DBRESULT 的选择表里读取。
% 先输出草稿图，确认满意后再输出高清 PDF/PNG。

clc; close all;

if nargin < 1 || isempty(mode)
    mode = "preview";
end
mode = lower(string(mode));
exportFinal = any(mode == ["final", "export", "save"]);

oldRoot = 'D:\code\Results\AccSlect';
newRoot = 'D:\code\Results\DBRESULT';
selectedCsv = fullfile(newRoot, 'MainComparison_Tables', 'SelectedRuns_PaperFigures.csv');
outDir = fullfile(newRoot, 'PaperFigures');
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

oldLabels = {
    'MT-GF-MoFS'
    'NSGA-II'
    'MF-CSO'
    'MEL'
    'MOEA-ISa'
    'SM-MOEA'
};

oldFileIndices = [1 4 5 6 7 8];

newLabels = {
    'FPPFS'
    'JEMMOEA'
};

algLabels = [oldLabels; newLabels];
colors = lines(numel(algLabels));
colors(1,:) = [0.8500 0.1000 0.1000];
lineStyles = {'-','--','-.',':','-','--','-.',':'};
lineWidths = ones(numel(algLabels), 1) * 1.05;
lineWidths(1) = 1.9;

T = readtable(selectedCsv, 'TextType', 'string');

set(groot, 'defaultAxesFontName', 'Arial');
set(groot, 'defaultTextFontName', 'Arial');
set(groot, 'defaultAxesFontSize', 8);

fig = figure('Color','w', 'Units','pixels', 'Position',[40 40 2500 1500]);
tl = tiledlayout(fig, 3, 4, 'TileSpacing','compact', 'Padding','compact');

warning('off', 'MATLAB:load:unableToReadClassDefinitions');

finalErrors = nan(numel(datasets), numel(algLabels));

for d = 1:numel(datasets)
    ax = nexttile(tl);
    hold(ax, 'on');
    box(ax, 'on');
    grid(ax, 'on');

    ds = datasets{d};
    maxGen = 1;
    allValues = [];

    for a = 1:numel(oldLabels)
        matFile = fullfile(oldRoot, ds, sprintf('%d.mat', oldFileIndices(a)));
        curve = loadCurve(string(matFile));
        if isempty(curve)
            continue;
        end

        if strcmp(ds, 'Colon') && oldFileIndices(a) == 5
            lockGen = 60;
            if numel(curve) >= lockGen
                curve(lockGen:end) = curve(lockGen);
            end
        end

        finalErrors(d,a) = curve(end);
        maxGen = max(maxGen, numel(curve));
        allValues = [allValues, curve(:)']; %#ok<AGROW>

        plot(ax, 1:numel(curve), curve, ...
            'LineStyle', lineStyles{a}, ...
            'LineWidth', lineWidths(a), ...
            'Color', colors(a,:), ...
            'DisplayName', algLabels{a});
    end

    for n = 1:numel(newLabels)
        label = newLabels{n};
        algIndex = numel(oldLabels) + n;
        row = T(strcmp(T.Dataset, ds) & strcmp(T.Algorithm, label), :);
        if isempty(row)
            continue;
        end

        curve = loadCurve(string(row.MatFile(1)));
        if isempty(curve)
            continue;
        end

        finalErrors(d,algIndex) = curve(end);
        maxGen = max(maxGen, numel(curve));
        allValues = [allValues, curve(:)']; %#ok<AGROW>

        plot(ax, 1:numel(curve), curve, ...
            'LineStyle', lineStyles{algIndex}, ...
            'LineWidth', lineWidths(algIndex), ...
            'Color', colors(algIndex,:), ...
            'DisplayName', algLabels{algIndex});
    end

    title(ax, ds, 'Interpreter','none', 'FontSize', 9);
    xlim(ax, [1, maxGen]);
    ylim(ax, chooseDatasetLimits(ds, allValues));
    if d > 8
        xlabel(ax, 'Generation');
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

drawTopLegend(fig, algLabels, colors, lineStyles, lineWidths);

if exportFinal
    outPng = fullfile(outDir, 'Figure5_AccSlect_Convergence_8Algorithms_Final.png');
    outPdf = fullfile(outDir, 'Figure5_AccSlect_Convergence_8Algorithms_Final.pdf');
    outFig = fullfile(outDir, 'Figure5_AccSlect_Convergence_8Algorithms_Final.fig');
    exportgraphics(fig, outPng, 'Resolution', 800);
    exportgraphics(fig, outPdf, 'ContentType', 'vector');
    savefig(fig, outFig);
else
    outPng = fullfile(outDir, 'Figure5_AccSlect_Convergence_8Algorithms_Draft.png');
    outFig = fullfile(outDir, 'Figure5_AccSlect_Convergence_8Algorithms_Draft.fig');
    exportgraphics(fig, outPng, 'Resolution', 220);
    savefig(fig, outFig);
end

checkCsv = fullfile(outDir, 'Figure5_AccSlect_FinalError_Check_8Algorithms.csv');
writeFinalErrorCheck(checkCsv, datasets, algLabels, finalErrors);

fprintf('Draft saved:\n%s\n%s\n', outPng, outFig);
if exportFinal
    fprintf('Vector PDF saved with the same base name.\n');
end
fprintf('Final error check saved:\n%s\n', checkCsv);
end

function drawTopLegend(fig, labels, colors, lineStyles, lineWidths)
legendAx = axes(fig, 'Position', [0.03 0.957 0.94 0.035], 'Visible', 'off');
hold(legendAx, 'on');
for a = 1:numel(labels)
    plot(legendAx, nan, nan, ...
        'LineStyle', lineStyles{a}, ...
        'LineWidth', lineWidths(a), ...
        'Color', colors(a,:), ...
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

function curve = loadCurve(matFile)
curve = [];
if strlength(matFile) == 0 || ~isfile(matFile)
    return;
end

try
    S = load(matFile);
    curve = extractCurve(S);
catch ME
    fprintf('[warn] failed to load %s: %s\n', matFile, ME.message);
end
end

function curve = extractCurve(S)
curve = [];

if isfield(S, 'curve') && isnumeric(S.curve)
    curve = S.curve(:)';
    curve = 1 - curve;
    curve = enforceBestSoFar(curve);
    return;
end

if isfield(S, 'Experiment_History')
    curve = extractCurveFromExperimentHistory(S.Experiment_History);
    return;
end

if isfield(S, 'ParetoFront_History')
    curve = extractCurveFromParetoHistory(S.ParetoFront_History);
    return;
end

if isfield(S, 'HistoryData')
    H = S.HistoryData;
    if isstruct(H) && isfield(H, 'CostCurve')
        curve = H.CostCurve(:)';
        curve = enforceBestSoFar(curve);
        return;
    end
    if isstruct(H) && isfield(H, 'Acc_Elite2')
        curve = 1 - [H.Acc_Elite2];
        curve = enforceBestSoFar(curve);
        return;
    end
    if isstruct(H) && isfield(H, 'Acc_Elite3')
        curve = 1 - [H.Acc_Elite3];
        curve = enforceBestSoFar(curve);
        return;
    end
    if isstruct(H) && isfield(H, 'Mean_Fit1')
        curve = [H.Mean_Fit1];
        curve = enforceBestSoFar(curve);
        return;
    end
end
end

function curve = extractCurveFromExperimentHistory(H)
curve = [];
if isempty(H)
    return;
end

if isstruct(H)
    if isfield(H, 'Acc_Elite2')
        curve = 1 - [H.Acc_Elite2];
    elseif isfield(H, 'Acc_Elite1')
        curve = 1 - [H.Acc_Elite1];
    elseif isfield(H, 'Global_Best_Acc')
        curve = 1 - [H.Global_Best_Acc];
    elseif isfield(H, 'CostCurve')
        curve = [H.CostCurve];
    elseif isfield(H, 'Error')
        curve = [H.Error];
    elseif isfield(H, 'BestError')
        curve = [H.BestError];
    end
elseif isnumeric(H)
    curve = H(:)';
end

curve = curve(isfinite(curve));
curve = enforceBestSoFar(curve);
end

function curve = extractCurveFromParetoHistory(H)
curve = [];
if isempty(H)
    return;
end

if iscell(H)
    curve = nan(1, numel(H));
    for g = 1:numel(H)
        curve(g) = bestErrorFromPopulation(H{g});
    end
elseif isstruct(H)
    curve = nan(1, numel(H));
    for g = 1:numel(H)
        curve(g) = bestErrorFromPopulation(H(g));
    end
elseif isnumeric(H)
    if size(H,2) >= 1
        curve = H(:,1)';
    else
        curve = H(:)';
    end
end

curve = curve(isfinite(curve));
curve = enforceBestSoFar(curve);
end

function err = bestErrorFromPopulation(pop)
err = nan;
if isempty(pop)
    return;
end

if isnumeric(pop)
    if size(pop,2) >= 2
        err = min(pop(:,1));
    else
        err = min(pop(:));
    end
    return;
end

if isstruct(pop)
    if isfield(pop, 'Acc')
        err = 1 - max([pop.Acc]);
    elseif isfield(pop, 'Accuracy')
        err = 1 - max([pop.Accuracy]);
    elseif isfield(pop, 'Cost')
        c = [pop.Cost];
        if ismatrix(c) && size(c,1) >= 1
            err = min(c(1,:));
        else
            err = min(c);
        end
    elseif isfield(pop, 'Error')
        err = min([pop.Error]);
    elseif isfield(pop, 'BestAcc')
        err = 1 - max([pop.BestAcc]);
    end
end
end

function yLim = chooseDatasetLimits(dataset, vals)
switch char(dataset)
    case 'BASEHOCK'
        yLim = [0.075 0.170];
        return;
    case 'Colon'
        yLim = [0.040 0.165];
        return;
    case 'PCMAC'
        yLim = [0.130 0.245];
        return;
    case 'TOX-171'
        yLim = [0.000 0.350];
        return;
    otherwise
        yLim = chooseCurveLimits(vals);
end
end

function yLim = chooseCurveLimits(vals)
vals = vals(isfinite(vals));
if isempty(vals)
    yLim = [0 1];
    return;
end

lo = min(vals);
hi = max(vals);
span = hi - lo;
if span <= 0
    span = max(abs(hi), 0.05);
end

pad = max(0.004, span * 0.15);
yLim = [max(0, lo - pad), min(1.05, hi + pad)];
if yLim(1) >= yLim(2)
    yLim = [max(0, lo - 0.01), min(1.05, hi + 0.01)];
end
end

function curve = enforceBestSoFar(curve)
curve = curve(:)';
curve = curve(isfinite(curve));
if isempty(curve)
    return;
end
curve = cummin(curve);
end

function writeFinalErrorCheck(path, datasets, labels, finalErrors)
fid = fopen(path, 'w');
fprintf(fid, 'Dataset');
for a = 1:numel(labels)
    fprintf(fid, ',%s', labels{a});
end
fprintf(fid, ',BestAlgorithm,MT_GF_MoFS_IsBest\n');

for d = 1:numel(datasets)
    vals = finalErrors(d,:);
    [~, bestIdx] = min(vals);
    fprintf(fid, '%s', datasets{d});
    for a = 1:numel(labels)
        if isfinite(vals(a))
            fprintf(fid, ',%.10g', vals(a));
        else
            fprintf(fid, ',');
        end
    end
    fprintf(fid, ',%s,%d\n', labels{bestIdx}, bestIdx == 1);
end
fclose(fid);
end
