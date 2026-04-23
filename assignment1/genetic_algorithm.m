function [bestFitnessHistory, finalBest] = genetic_algorithm(objFunc, bounds, popSize, maxGen, pc, pm, eliteRate, crossOp, mutOp)
    % Parameters:
    % objFunc: object function handler,
    % bounds: [min, max] of solution
    % popSize: popularity size
    % maxGen: max number of generation
    % pc: crossover percentage
    % pm: mutation percentage
    % eliteRate: elite kept rate
    % crossOp: crossover function handler 
    % mutOp: mutation function handler

    dim = 2; % variation dimension (x1, x2)
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

            % crossover
            [off1, off2] = crossOp(p1, p2, pc, lb, ub);
            
            % mutation
            off1 = mutOp(off1, pm, lb, ub);
            off2 = mutOp(off2, pm, lb, ub);

            newPop(i, :) = off1;
            if i + 1 <= popSize
                newPop(i+1, :) = off2;
            end
        end
        pop = newPop;
    end
    finalBest = bestFitnessHistory(end);
end


