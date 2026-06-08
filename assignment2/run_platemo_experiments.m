%% run_platemo_experiments.m
% Run five PlatEMO algorithms on DTLZ7 and WFG4.
% Place this script anywhere, add PlatEMO/PlatEMO to MATLAB path, then run it.

clear; clc;

% ---------- Reproducible experiment configuration ----------
algorithms = {@NSGAIII, @MOEAD, @RVEA, @SPEA2, @NSGAII};
problems   = {@DTLZ7, @WFG4};
problemD   = [22, 12];          % DTLZ7: M+19 = 22; WFG4 default: (M-1)+10 = 12
M          = 3;
N          = 91;                % exact NBI reference-point count for M=3
maxFE      = 10010;             % 91 * 110, avoids unequal final generation budgets
numRuns    = 30;
numSaved   = 50;                % saved checkpoints for convergence curves
metrics    = {'IGD','HV'};

platemoRoot = fileparts(which('platemo'));
if isempty(platemoRoot)
    error(['MATLAB cannot find platemo.m. Add the PlatEMO/PlatEMO folder ', ...
           'to the MATLAB path first, then rerun this script.']);
end
cd(platemoRoot);

fprintf('PlatEMO root: %s\n', platemoRoot);
fprintf('Configuration: M=%d, N=%d, maxFE=%d, runs=%d, checkpoints=%d\n', ...
    M, N, maxFE, numRuns, numSaved);

for p = 1:numel(problems)
    for a = 1:numel(algorithms)
        for r = 1:numRuns
            fprintf('\n[%s | %s | run %02d/%02d]\n', ...
                func2str(algorithms{a}), func2str(problems{p}), r, numRuns);
            platemo('algorithm', algorithms{a}, ...
                    'problem',   problems{p}, ...
                    'M',         M, ...
                    'D',         problemD(p), ...
                    'N',         N, ...
                    'maxFE',     maxFE, ...
                    'save',      numSaved, ...
                    'run',       r, ...
                    'metName',   metrics);
        end
    end
end

fprintf('\nAll runs finished. MAT files are under: %s\n', fullfile(platemoRoot,'Data'));
