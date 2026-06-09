%% summarize_platemo_results_m5_modified.m
% Summarize PlatEMO M = 5 MAT files and export CSV + PNG figures.
% Run after run_platemo_experiments_m5_modified.m.

clear; clc;

algorithms = {'NSGAIII','MOEAD','RVEA','SPEA2','SMSEMOA'};
problems   = {'DTLZ1','DTLZ2','DTLZ3','DTLZ4','DTLZ7','WFG4'};
problemD   = [9, 14, 14, 14, 24, 14];

M          = 5;
numRuns    = 30;
plotRun    = 5;     % use the 5th run for convergence curves

platemoRoot = fileparts(which('platemo'));
if isempty(platemoRoot)
    error('MATLAB cannot find platemo.m. Add PlatEMO/PlatEMO to the path first.');
end
cd(platemoRoot);

outDir = 'F:\OldE\University\EvolutionaryComputing\Evolutionary_Computing_2026_Spring\assignment2\results_m5';
if ~exist(outDir,'dir'); mkdir(outDir); end

summaryRows = {};
rawRows = {};

for p = 1:numel(problems)
    problemObj = feval(problems{p}, 'M', M, 'D', problemD(p));

    % For M > 3, use sampled true Pareto-optimal points and visualize them
    % with a parallel-coordinate plot.
    truePF = problemObj.optimum;

    maxTruePFPlotPoints = 500;
    if size(truePF,1) > maxTruePFPlotPoints
        sampleIndex = round(linspace(1, size(truePF,1), maxTruePFPlotPoints));
        truePFPlot = truePF(sampleIndex,:);
    else
        truePFPlot = truePF;
    end

    for a = 1:numel(algorithms)
        finalIGD = nan(numRuns,1);
        finalHV  = nan(numRuns,1);
        runtime  = nan(numRuns,1);

        for r = 1:numRuns
            matFile = fullfile(platemoRoot,'Data',algorithms{a}, ...
                sprintf('%s_%s_M%d_D%d_%d.mat', ...
                algorithms{a}, problems{p}, M, problemD(p), r));

            if ~exist(matFile,'file')
                warning('Missing file: %s', matFile);
                continue;
            end

            S = load(matFile,'result','metric');
            finalIGD(r) = S.metric.IGD(end);
            finalHV(r)  = S.metric.HV(end);
            runtime(r)  = S.metric.runtime;

            rawRows(end+1,:) = {algorithms{a}, problems{p}, M, problemD(p), r, ...
                finalIGD(r), finalHV(r), runtime(r)}; %#ok<SAGROW>
        end

        summaryRows(end+1,:) = {algorithms{a}, problems{p}, M, problemD(p), ...
            mean(finalIGD,'omitnan'), std(finalIGD,'omitnan'), ...
            mean(finalHV,'omitnan'),  std(finalHV,'omitnan'), ...
            mean(runtime,'omitnan'),  std(runtime,'omitnan')}; %#ok<SAGROW>

        validRuns = find(~isnan(finalIGD));
        if isempty(validRuns)
            warning('No valid runs found for %s on %s.', algorithms{a}, problems{p});
            continue;
        end

        [~,order] = sort(finalIGD(validRuns));
        medianRun = validRuns(order(ceil(numel(order)/2)));

        [~,bestLocal] = min(finalIGD(validRuns));
        bestRun = validRuns(bestLocal);

        selectedRuns  = [medianRun, bestRun];
        selectedNames = {'MedianIGD','BestIGD'};

        for q = 1:2
            chosenRun = selectedRuns(q);

            matFile = fullfile(platemoRoot,'Data',algorithms{a}, ...
                sprintf('%s_%s_M%d_D%d_%d.mat', ...
                algorithms{a}, problems{p}, M, problemD(p), chosenRun));

            S = load(matFile,'result');
            popObj = S.result{end,2}.best.objs;

            combinedObj = [truePFPlot; popObj];
            objMin = min(combinedObj, [], 1);
            objMax = max(combinedObj, [], 1);
            objRange = objMax - objMin;
            objRange(objRange == 0) = 1;

            truePFNorm = (truePFPlot - objMin) ./ objRange;
            popObjNorm = (popObj     - objMin) ./ objRange;

            fig = figure('Visible','off');
            hold on;

            labels = {'f_1','f_2','f_3','f_4','f_5'};

            hTrue = parallelcoords(truePFNorm, ...
                'Labels', labels, ...
                'Color', [0.78, 0.78, 0.78], ...
                'LineWidth', 0.35);

            hObtained = parallelcoords(popObjNorm, ...
                'Labels', labels, ...
                'Color', [0.15, 0.15, 0.15], ...
                'LineWidth', 0.90);

            grid on;
            ylim([0,1]);
            xlabel('Objective');
            ylabel('Normalized objective value');

            title(sprintf('%s on %s: %s run %d', ...
                algorithms{a}, problems{p}, selectedNames{q}, chosenRun), ...
                'Interpreter','none');

            legend([hTrue(1), hObtained(1)], ...
                {'True Pareto front samples','Obtained solutions'}, ...
                'Location','best');

            exportgraphics(fig, ...
                fullfile(outDir, sprintf('Parallel_%s_%s_%s_M5.png', ...
                selectedNames{q}, algorithms{a}, problems{p})), ...
                'Resolution',300);

            close(fig);
        end
    end

    % Compare convergence trajectories using plotRun.
    figIGD = figure('Visible','off'); hold on; grid on;
    figHV  = figure('Visible','off'); hold on; grid on;
    runtimeMean = nan(numel(algorithms),1);

    for a = 1:numel(algorithms)
        matFile = fullfile(platemoRoot,'Data',algorithms{a}, ...
            sprintf('%s_%s_M%d_D%d_%d.mat', ...
            algorithms{a}, problems{p}, M, problemD(p), plotRun));

        if ~exist(matFile,'file')
            warning('Missing convergence file: %s', matFile);
            continue;
        end

        S = load(matFile,'result','metric');
        fe = cell2mat(S.result(:,1));

        figure(figIGD);
        plot(fe,S.metric.IGD,'LineWidth',1.4,'DisplayName',algorithms{a});

        figure(figHV);
        plot(fe,S.metric.HV,'LineWidth',1.4,'DisplayName',algorithms{a});

        algRows = strcmp(summaryRows(:,1),algorithms{a}) & ...
                  strcmp(summaryRows(:,2),problems{p});
        rowIndex = find(algRows,1);
        if ~isempty(rowIndex)
            runtimeMean(a) = summaryRows{rowIndex,9};
        end
    end

    figure(figIGD);
    xlabel('Function evaluations (FE)');
    ylabel('IGD');
    title(sprintf('IGD convergence on %s: run %d, M=5', problems{p}, plotRun), ...
        'Interpreter','none');
    legend('Location','best');
    exportgraphics(figIGD, ...
        fullfile(outDir,sprintf('Convergence_IGD_%s_M5.png',problems{p})), ...
        'Resolution',300);
    close(figIGD);

    figure(figHV);
    xlabel('Function evaluations (FE)');
    ylabel('HV');
    title(sprintf('HV convergence on %s: run %d, M=5', problems{p}, plotRun), ...
        'Interpreter','none');
    legend('Location','best');
    exportgraphics(figHV, ...
        fullfile(outDir,sprintf('Convergence_HV_%s_M5.png',problems{p})), ...
        'Resolution',300);
    close(figHV);

    figRT = figure('Visible','off');
    bar(runtimeMean); grid on;
    set(gca,'XTick',1:numel(algorithms),'XTickLabel',algorithms);
    ylabel('Mean runtime (s)');
    title(sprintf('Runtime comparison on %s, M=5',problems{p}),'Interpreter','none');
    exportgraphics(figRT, ...
        fullfile(outDir,sprintf('Runtime_%s_M5.png',problems{p})), ...
        'Resolution',300);
    close(figRT);
end

summaryTable = cell2table(summaryRows,'VariableNames', ...
    {'Algorithm','Problem','M','D','IGD_mean','IGD_std','HV_mean','HV_std', ...
     'Runtime_mean_s','Runtime_std_s'});

rawTable = cell2table(rawRows,'VariableNames', ...
    {'Algorithm','Problem','M','D','Run','IGD','HV','Runtime_s'});

writetable(summaryTable,fullfile(outDir,'summary_metrics_M5.csv'));
writetable(rawTable,fullfile(outDir,'raw_metrics_M5.csv'));

disp(summaryTable);
fprintf('\nM=5 export finished: %s\n',outDir);
