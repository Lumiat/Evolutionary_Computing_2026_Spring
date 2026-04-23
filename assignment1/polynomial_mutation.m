function x_mutated = polynomial_mutation(x, pm, eta_m, lb, ub)
    % Polynomial Mutation (NSGA-II)
    % x: to be mutated
    % pm: mutation percentage
    % eta_m: distribution index
    % lb, ub: upper bound, lower bound
    
    dim = length(x);
    x_mutated = x;
    
    for j = 1:dim
        if rand < pm
            u = rand;
            if u < 0.5
                delta = (2 * u)^(1 / (eta_m + 1)) - 1;
            else
                delta = 1 - (2 * (1 - u))^(1 / (eta_m + 1));
            end
            
            % mutate according to upper bound and lower bound
            v = x_mutated(j) + delta * (ub - lb);
            
            % boundary check
            x_mutated(j) = max(min(v, ub), lb);
        end
    end
end