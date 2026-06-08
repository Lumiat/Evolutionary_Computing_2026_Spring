%% summarize_platemo_results.m
% Summarize PlatEMO MAT files and export CSV + PNG figures.
% Run after run_platemo_experiments.m.

clear; clc;

algorithms = {'NSGAIII','MOEAD','RVEA','SPEA2','NSGAII'};
problems   = {'DTLZ7','WFG4'};
problemD   = [22, 12];
M          = 3;
numRuns    = 30;
plotRun    = 5;     % classroom plan: use the 5th run for convergence curves

platemoRoot = fileparts(which('platemo'));
if isempty(platemoRoot)
    error('MATLAB cannot find platemo.m. Add PlatEMO/PlatEMO to the path first.');
end
cd(platemoRoot);
outDir = 'F:\OldE\University\EvolutionaryComputing\Evolutionary_Computing_2026_Spring\assignment2\results';
if ~exist(outDir,'dir'); mkdir(outDir); end

summaryRows = {};
rawRows = {};

for p = 1:numel(problems)
    for a = 1:numel(algorithms)
        finalIGD = nan(numRuns,1);
        finalHV  = nan(numRuns,1);
        runtime  = nan(numRuns,1);

        for r = 1:numRuns
            matFile = fullfile(platemoRoot,'Data',algorithms{a}, ...
                sprintf('%s_%s_M%d_D%d_%d.mat', algorithms{a}, problems{p}, M, problemD(p), r));
            if ~exist(matFile,'file')
                warning('Missing file: %s', matFile);
                continue;
            end
            S = load(matFile,'result','metric');
            finalIGD(r) = S.metric.IGD(end);
            finalHV(r)  = S.metric.HV(end);
            runtime(r)  = S.metric.runtime;
            rawRows(end+1,:) = {algorithms{a},problems{p},r,finalIGD(r),finalHV(r),runtime(r)}; %#ok<SAGROW>
        end

        summaryRows(end+1,:) = {algorithms{a},problems{p},M,problemD(p), ...
            mean(finalIGD,'omitnan'),std(finalIGD,'omitnan'), ...
            mean(finalHV,'omitnan'), std(finalHV,'omitnan'), ...
            mean(runtime,'omitnan'), std(runtime,'omitnan')}; %#ok<SAGROW>

        % Save representative (median-IGD) and best-IGD final solution distributions.
        validRuns = find(~isnan(finalIGD));
        [~,order] = sort(finalIGD(validRuns));
        medianRun = validRuns(order(ceil(numel(order)/2)));
        [~,bestLocal] = min(finalIGD(validRuns));
        bestRun = validRuns(bestLocal);
        selectedRuns = [medianRun,bestRun];
        selectedNames = {'MedianIGD','BestIGD'};
        for q = 1:2
            chosenRun = selectedRuns(q);
            matFile = fullfile(platemoRoot,'Data',algorithms{a}, ...
                sprintf('%s_%s_M%d_D%d_%d.mat', algorithms{a}, problems{p}, M, problemD(p), chosenRun));
            S = load(matFile,'result');
            popObj = S.result{end,2}.best.objs;
            fig = figure('Visible','off');
            scatter3(popObj(:,1),popObj(:,2),popObj(:,3),24,'filled');
            grid on; xlabel('f_1'); ylabel('f_2'); zlabel('f_3');
            title(sprintf('%s on %s: %s run %d',algorithms{a},problems{p},selectedNames{q},chosenRun), ...
                'Interpreter','none');
            view(45,25);
            exportgraphics(fig,fullfile(outDir,sprintf('Front_%s_%s_%s.png',selectedNames{q},algorithms{a},problems{p})),'Resolution',300);
            close(fig);
        end
    end

    % Compare convergence trajectories using the selected run.
    figIGD = figure('Visible','off'); hold on; grid on;
    figHV  = figure('Visible','off'); hold on; grid on;
    runtimeMean = nan(numel(algorithms),1);
    for a = 1:numel(algorithms)
        matFile = fullfile(platemoRoot,'Data',algorithms{a}, ...
            sprintf('%s_%s_M%d_D%d_%d.mat', algorithms{a}, problems{p}, M, problemD(p), plotRun));
        S = load(matFile,'result','metric');
        fe = cell2mat(S.result(:,1));
        figure(figIGD); plot(fe,S.metric.IGD,'LineWidth',1.4,'DisplayName',algorithms{a});
        figure(figHV);  plot(fe,S.metric.HV, 'LineWidth',1.4,'DisplayName',algorithms{a});

        algRows = strcmp(summaryRows(:,1),algorithms{a}) & strcmp(summaryRows(:,2),problems{p});
        runtimeMean(a) = summaryRows{find(algRows,1),9};
    end
    figure(figIGD); xlabel('Function evaluations (FE)'); ylabel('IGD');
    title(sprintf('IGD convergence on %s: run %d',problems{p},plotRun),'Interpreter','none'); legend('Location','best');
    exportgraphics(figIGD,fullfile(outDir,sprintf('Convergence_IGD_%s.png',problems{p})),'Resolution',300); close(figIGD);

    figure(figHV); xlabel('Function evaluations (FE)'); ylabel('HV');
    title(sprintf('HV convergence on %s: run %d',problems{p},plotRun),'Interpreter','none'); legend('Location','best');
    exportgraphics(figHV,fullfile(outDir,sprintf('Convergence_HV_%s.png',problems{p})),'Resolution',300); close(figHV);

    figRT = figure('Visible','off');
    bar(runtimeMean); grid on;
    set(gca,'XTick',1:numel(algorithms),'XTickLabel',algorithms);
    ylabel('Mean runtime (s)'); title(sprintf('Runtime comparison on %s',problems{p}),'Interpreter','none');
    exportgraphics(figRT,fullfile(outDir,sprintf('Runtime_%s.png',problems{p})),'Resolution',300); close(figRT);
end

summaryTable = cell2table(summaryRows,'VariableNames', ...
    {'Algorithm','Problem','M','D','IGD_mean','IGD_std','HV_mean','HV_std','Runtime_mean_s','Runtime_std_s'});
rawTable = cell2table(rawRows,'VariableNames', ...
    {'Algorithm','Problem','Run','IGD','HV','Runtime_s'});

writetable(summaryTable,fullfile(outDir,'summary_metrics.csv'));
writetable(rawTable,fullfile(outDir,'raw_metrics.csv'));

disp(summaryTable);
fprintf('\nExport finished: %s\n',outDir);
