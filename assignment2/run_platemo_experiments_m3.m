%% run_platemo_experiments_m3_modified.m
% Run five PlatEMO algorithms on six multi-objective benchmark problems.
% This script only runs the M = 3 experiments.
%
% For fair comparison across algorithms, each problem uses the same maxFE
% for all algorithms. The requested number of generations is converted by:
%     maxFE = populationSize * generations
%
% Place this script anywhere, add PlatEMO/PlatEMO to the MATLAB path,
% then run this file.

clear; clc;

% ---------- Reproducible experiment configuration ----------
% Teacher-specified algorithms:
% NSGA-III, MOEA/D, RVEA, SPEA2, SMS-EMOA
algorithms = {@NSGAIII, @MOEAD, @RVEA, @SPEA2, @NSGAII};

% M = 3 benchmark problems
problems    = {@DTLZ1, @DTLZ2, @DTLZ3, @DTLZ4, @DTLZ7, @WFG4};
problemD    = [     7,     12,     12,     12,     22,    12];
generations = [   400,    110,   1000,    110,    500,   750];

M           = 3;
N           = 91;
maxFEs      = N .* generations;

numRuns     = 30;
numSaved    = 50;              % saved checkpoints for convergence curves
metrics     = {'IGD','HV'};

% ---------- Locate PlatEMO ----------
platemoRoot = fileparts(which('platemo'));
if isempty(platemoRoot)
    error(['MATLAB cannot find platemo.m. Add the PlatEMO/PlatEMO folder ', ...
           'to the MATLAB path first, then rerun this script.']);
end
cd(platemoRoot);

% ---------- Basic availability checks ----------
for a = 1:numel(algorithms)
    algorithmName = func2str(algorithms{a});
    if isempty(which(algorithmName))
        error(['MATLAB cannot find algorithm class "%s". ', ...
               'Please confirm that your PlatEMO version contains this algorithm ', ...
               'and that the PlatEMO folder has been added to the MATLAB path.'], ...
               algorithmName);
    end
end

for p = 1:numel(problems)
    problemName = func2str(problems{p});
    if isempty(which(problemName))
        error(['MATLAB cannot find problem class "%s". ', ...
               'Please confirm that your PlatEMO folder has been added to the MATLAB path.'], ...
               problemName);
    end
end

% ---------- Print configuration ----------
fprintf('PlatEMO root: %s\n', platemoRoot);
fprintf('Global configuration: M=%d, N=%d, runs=%d, checkpoints=%d\n', ...
        M, N, numRuns, numSaved);

fprintf('\nProblem-specific settings:\n');
fprintf('%-8s %-4s %-4s %-8s %-8s\n', 'Problem', 'M', 'D', 'Gen', 'maxFE');
for p = 1:numel(problems)
    fprintf('%-8s %-4d %-4d %-8d %-8d\n', ...
            func2str(problems{p}), M, problemD(p), generations(p), maxFEs(p));
end

% ---------- Run all algorithm-problem combinations ----------
for p = 1:numel(problems)
    problemName = func2str(problems{p});

    for a = 1:numel(algorithms)
        algorithmName = func2str(algorithms{a});

        for r = 1:numRuns
            fprintf('\n[%s | %s | M=%d | D=%d | N=%d | Gen=%d | maxFE=%d | run %02d/%02d]\n', ...
                    algorithmName, problemName, M, problemD(p), N, ...
                    generations(p), maxFEs(p), r, numRuns);

            platemo('algorithm', algorithms{a}, ...
                    'problem',   problems{p}, ...
                    'M',         M, ...
                    'D',         problemD(p), ...
                    'N',         N, ...
                    'maxFE',     maxFEs(p), ...
                    'save',      numSaved, ...
                    'run',       r, ...
                    'metName',   metrics);
        end
    end
end

fprintf('\nAll M=3 runs finished. MAT files are under: %s\n', ...
        fullfile(platemoRoot, 'Data'));
