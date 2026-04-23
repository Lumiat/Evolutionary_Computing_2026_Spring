function main(funcID, algoType)
    %% hyper params
    numRuns = 30;
    maxGen = 100;
    popSize = 50;
    pc = 0.8;
    pm = 0.1;
    eliteRate = 0.1;
    eta_c = 10;
    eta_m = 10;

    % funcID: if 1 use dejong1, if 2 use dejong2
    
    if nargin < 1
        funcID = 1;
    end
    if nargin < 2
        algoType = 2; 
    end 

    %% configure according to funcID
    if funcID == 1
        targetFunc = @dejong1;
        bounds = [-5.12, 5.12];
        funcName = 'De Jong 1';
    elseif funcID == 2
        targetFunc = @dejong2;
        bounds = [-2.048, 2.048];
        funcName = 'De Jong 2';
    else
        error('Error：funcID only allow 1 or 2.');
    end

    fprintf('Current object function: %s\n', funcName);

    if algoType == 1
        % use arithmetic crossover + gaussian mutation
        crossOp = @arithmetic_crossover;
        mutOp = @gaussian_mutation;
        algoName = 'Basic (Arithmetic + Gaussian)';
    else
        % use sbx+polinomial mutation
        crossOp = @(p1, p2, pc, lb, ub) sbx_crossover(p1, p2, pc, eta_c, lb, ub);
        mutOp = @(x, pm, lb, ub) polynomial_mutation(x, pm, eta_m, lb, ub);
        algoName = 'Advanced (SBX + Polynomial)';
    end

    fprintf('Current object function: %s\n', funcName);
    fprintf('Current Algorithm: %s\n', algoName);

    %% 30 runs
    allHistories = zeros(maxGen, numRuns);
    finalResults = zeros(numRuns, 1);
    
    fprintf("Running Algorithm...\n");
    for r = 1:numRuns
        [history, bestVal] = genetic_algorithm(targetFunc, bounds, popSize, maxGen, pc, pm, eliteRate, crossOp, mutOp);
        allHistories(:, r) = history;
        finalResults(r) = bestVal;
    end
    
    %% result statistics
    avgVal = mean(finalResults);
    stdVal = std(finalResults);
    fprintf("Mean Value of 30 runs: %.6f\n", avgVal);
    fprintf("Std Value of 30 runs: %.6f\n", stdVal);
    
    %% visualize training process of one run
    figure(1);
    plot(1:maxGen, allHistories(:, 5), 'LineWidth',1.5); % show the fifth run
    xlabel('Generation');
    ylabel('Fitness');
    if funcID == 1
        title('Single Run Evolution Process (De Jong 1, 5th run)');
    else
        title(['Single Run Evolution Process (De Jong 2, 5th run)']);
    end
    grid on;
    
    %% draw boxplot
    figure(2);
    % in allHistories, each row represents a generation, each column represents a run
    selectedGens = [1, 10, 50, 100];
    boxplot(allHistories(selectedGens, :)');
    set(gca, 'XTickLabel', {'Gen 1', 'Gen 10', 'Gen 50', 'Gen 100'});
    ylabel('Best Fitness');
    title('Distribution of Best Fitness over 30 Runs');
    grid on;