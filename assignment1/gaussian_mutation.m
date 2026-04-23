function x_mutated = gaussian_mutation(x, pm, lb, ub)
    % Gaussian Mutation
    x_mutated = x;
    if rand < pm
        dim = length(x);
        x_mutated = x_mutated + randn(1, dim) * 0.1;
    end
    % boundary check
    x_mutated = max(min(x_mutated, ub), lb);
end