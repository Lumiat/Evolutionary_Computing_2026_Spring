function [bestFitnessHistory, finalBest] = genetic_algorithm(objFunc, bounds, popSize, maxGen, pc, pm, eliteRate)
    % Parameters:
    % objFunc: object function handler,
    % bounds: [min, max] of solution
    % popSize: popularity size
    % maxGen: max number of generation
    % pc: crossover percentage
    % pm: mutation percentage
    % eliteRate: elite kept rate

    dim = 2 % variation dimension (x1, x2)
    lb = bounds(1);
    ub = bounds(2);

    % initialization
    pop = lb + (ub - lb) * rand(popSize, dim);
    bestFitnessHistory = zeros(maxGen, 1);

    numElite = round(popSize * eliteRate);

    for gen = 1:maxGen
        % evaluation
        fitness = zeros(popSize, 1);
        for i = 1:popSize
            fitness(i) = objFunc(pop(i, :));
        end

        % sort (ascend)
        [fitness, idx] = sort(fitness);
        pop = pop(idx, :);

        % record best fitness value
        bestFitnessHistory(gen) = fitness(1);

        % selection
        newPop = zeros(popSize, dim);
        newPop(1:numElite, :) = pop(1:numElite, :); % keep the best

        % crossover and mutation
        for i = (numElite + 1) : 2 : popSize
            % choose parent
            p1 = pop(randi(numElite + 10), :); 
            p2 = pop(randi(numElite + 10), :);

            % crossover: whole arithmetic crossover
            if rand < pc
                alpha = rand;
                offspring1 = alpha * p1 + (1 - alpha) * p2;
                offspring2 = alpha * p2 + (1 - alpha) * p1;
            else
                offspring1 = p1;
                offspring2 = p2;
            end
            
            % mutation: gaussian mutation
            if rand < pm
                offspring1 = offspring1 + randn(1, dim) * 0.1;
                offspring2 = offspring2 + randn(1, dim) * 0.1;
            end

            offspring1 = max(min(offspring1, ub), lb);
            offspring2 = max(min(offspring2, ub), lb);

            newPop(i, :) = offspring1;
            if i + 1 <= popSize
                newPop(i+1, :) = offspring2;
            end
        end
        pop = newPop;
    end
    finalBest = bestFitnessHistory(end);
end


