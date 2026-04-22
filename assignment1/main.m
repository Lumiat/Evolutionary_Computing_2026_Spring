function main(funcID)
    % funcID: if 1 use dejong1, if 2 use dejong2
    
    if nargin < 1
        funcID = 1;
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

    %% hyper params
    numRuns = 30;
    maxGen = 100;
    popSize = 50;
    pc = 0.8;
    pm = 0.1;
    eliteRate = 0.1;
    
    %% 30 runs
    allHistories = zeros(maxGen, numRuns);
    finalResults = zeros(numRuns, 1);
    
    fprintf("Running Algorithm...\n");
    for r = 1:numRuns
        [history, bestVal] = genetic_algorithm(targetFunc, bounds, popSize, maxGen, pc, pm, eliteRate);
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
    title('Single Run Evolution Process (De Jong 2, 5th run)');
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