function [off1, off2] = arithmetic_crossover(p1, p2, pc, lb, ub)
    % Arithmetic Crossover
    if rand < pc
        alpha = rand;
        off1 = alpha * p1 + (1 - alpha) * p2;
        off2 = alpha * p2 + (1 - alpha) * p1;
    else
        off1 = p1;
        off2 = p2;
    end
    % boundary check
    off1 = max(min(off1, ub), lb);
    off2 = max(min(off2, ub), lb);
end