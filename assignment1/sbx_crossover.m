function [off1, off2] = sbx_crossover(p1, p2, pc, eta_c, lb, ub)
    % Simulated Binary Crossover
    % p1, p2: parents
    % pc: crossover percentage
    % eta_c: distribution index
    % lb, ub: upper bound and lower bound
    
    dim = length(p1);
    off1 = p1;
    off2 = p2;
    
    if rand < pc
        for j = 1:dim
            if rand <= 0.5
                % calculate for every dim
                u = rand;
                if u <= 0.5
                    beta = (2 * u)^(1 / (eta_c + 1));
                else
                    beta = (1 / (2 * (1 - u)))^(1 / (eta_c + 1));
                end
                
                % generate offspring
                v1 = 0.5 * ((1 + beta) * p1(j) + (1 - beta) * p2(j));
                v2 = 0.5 * ((1 - beta) * p1(j) + (1 + beta) * p2(j));
                
                % boundary check
                off1(j) = max(min(v1, ub), lb);
                off2(j) = max(min(v2, ub), lb);
            end
        end
    end
end