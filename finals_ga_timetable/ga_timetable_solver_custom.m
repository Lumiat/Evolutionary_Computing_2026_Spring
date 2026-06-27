function ga_timetable_solver_custom()
%GA_TIMETABLE_SOLVER_CUSTOM
% Genetic Algorithm solver for the customized university timetable task.
%
% This version runs the GA independently for 30 times to evaluate robustness.
%
% Main output files in current folder:
%   best_schedule.csv          schedule selected from the best run, for visualization
%   ga_history.csv             convergence history of the selected best run
%   best_penalty_report.txt    penalty report of the selected best run
%   ga_30run_summary.csv       final result summary of all 30 runs
%   ga_30run_history.csv       convergence history of all 30 runs
%
% Detailed output folder:
%   ga_30run_results/
%       summary.csv
%       all_runs_history.csv
%       selected_schedule.csv
%       selected_history.csv
%       selected_penalty_report.txt
%       runs/run_01/...
%       runs/run_02/...
%       ...
%
% Run in MATLAB:
%   >> ga_timetable_solver_custom

    data = buildData();

    params.numRuns = 30;
    params.baseSeed = 2026;
    params.outputRoot = 'ga_30run_results';

    % Fast hybrid-GA parameters.
    % The history file shows that hard constraints are usually satisfied in the first few
    % generations, while later generations mostly stagnate on soft-constraint local optima.
    % Therefore, this version uses a smaller population, earlier stopping, and targeted
    % local improvement on elite feasible individuals.
    params.popSize = 160;
    params.maxGen = 600;
    params.eliteCount = 10;
    params.tournamentSize = 3;
    params.crossoverRate = 0.88;
    params.mutationRate = 0.50;
    params.geneMutationRate = 0.18;
    params.stallLimit = 150;
    params.repairAttempts = 80;
    params.printEvery = 50;

    % Stop as soon as a high-quality feasible solution is found.
    % In the current penalty design, 282/284 is the observed good basin.
    params.targetPenalty = 284;

    % Targeted local improvement. This is much cheaper than running many extra GA
    % generations and directly attacks the observed local optima around 520/530.
    params.localImproveInterval = 15;
    params.localImproveStallTrigger = 25;
    params.localImproveEliteCount = 4;
    params.localImproveMaxPass = 3;

    if exist(params.outputRoot, 'dir')
        rmdir(params.outputRoot, 's');
    end
    mkdir(params.outputRoot);
    mkdir(fullfile(params.outputRoot, 'runs'));

    summaryRun = zeros(params.numRuns, 1);
    summarySeed = zeros(params.numRuns, 1);
    summaryBest = zeros(params.numRuns, 1);
    summaryHard = zeros(params.numRuns, 1);
    summarySoft = zeros(params.numRuns, 1);
    summaryGenerationCount = zeros(params.numRuns, 1);
    summaryFeasible = false(params.numRuns, 1);
    summarySoftTheoryMorning = zeros(params.numRuns, 1);
    summarySoftLabAfternoon = zeros(params.numRuns, 1);
    summarySoftNoEvening = zeros(params.numRuns, 1);
    summarySoftDailyCampusSwitch = zeros(params.numRuns, 1);
    summarySoftTheoryLabSameProfessor = zeros(params.numRuns, 1);

    allHistoryCells = cell(params.numRuns, 1);

    globalBestPenalty = inf;
    selectedRun = 1;

    fprintf('Start 30-run customized GA timetable experiment.\n');
    fprintf('Events: %d | Rooms: %d | Professors: %d | Runs: %d\n', ...
        numel(data.events), numel(data.rooms), numel(data.professors), params.numRuns);

    for runID = 1:params.numRuns
        seed = params.baseSeed + runID - 1;
        rng(seed);

        fprintf('\n================ Run %02d/%02d | seed = %d ================\n', ...
            runID, params.numRuns, seed);

        [bestIndividual, bestPenalty, bestDetail, history] = runSingleGA(data, params, runID);
        scheduleTable = individualToTable(bestIndividual, data);
        historyTable = table( ...
            repmat(runID, size(history, 1), 1), ...
            repmat(seed, size(history, 1), 1), ...
            history(:, 1), history(:, 2), history(:, 3), history(:, 4), ...
            'VariableNames', {'Run','Seed','Generation','BestPenalty','MeanPenalty','BestHardPenalty'});

        runDir = fullfile(params.outputRoot, 'runs', sprintf('run_%02d', runID));
        mkdir(runDir);
        writetable(scheduleTable, fullfile(runDir, 'best_schedule.csv'), 'Encoding', 'UTF-8');
        writetable(historyTable, fullfile(runDir, 'ga_history.csv'), 'Encoding', 'UTF-8');
        writePenaltyReport(bestPenalty, bestDetail, fullfile(runDir, 'best_penalty_report.txt'));

        allHistoryCells{runID} = historyTable;

        summaryRun(runID) = runID;
        summarySeed(runID) = seed;
        summaryBest(runID) = bestPenalty;
        summaryHard(runID) = bestDetail.hardPenalty;
        summarySoft(runID) = bestDetail.softPenalty;
        summaryGenerationCount(runID) = size(history, 1);
        summaryFeasible(runID) = (bestDetail.hardPenalty == 0);
        summarySoftTheoryMorning(runID) = bestDetail.softTheoryMorning;
        summarySoftLabAfternoon(runID) = bestDetail.softLabAfternoon;
        summarySoftNoEvening(runID) = bestDetail.softNoEvening;
        summarySoftDailyCampusSwitch(runID) = bestDetail.softDailyCampusSwitch;
        summarySoftTheoryLabSameProfessor(runID) = bestDetail.softTheoryLabSameProfessor;

        fprintf('Run %02d finished | best = %.2f | hard = %.2f | soft = %.2f | generations = %d\n', ...
            runID, bestPenalty, bestDetail.hardPenalty, bestDetail.softPenalty, size(history, 1));

        if bestPenalty < globalBestPenalty
            globalBestPenalty = bestPenalty;
            selectedRun = runID;
        end
    end

    IsSelectedForVisualization = (summaryRun == selectedRun);
    summaryTable = table(summaryRun, summarySeed, summaryBest, summaryHard, summarySoft, ...
        summarySoftTheoryMorning, summarySoftLabAfternoon, summarySoftNoEvening, ...
        summarySoftDailyCampusSwitch, summarySoftTheoryLabSameProfessor, ...
        summaryGenerationCount, summaryFeasible, IsSelectedForVisualization, ...
        'VariableNames', {'Run','Seed','BestPenalty','HardPenalty','SoftPenalty', ...
        'SoftTheoryMorning','SoftLabAfternoon','SoftNoEvening', ...
        'SoftDailyCampusSwitch','SoftTheoryLabSameProfessor', ...
        'GenerationCount','Feasible','SelectedForVisualization'});

    allHistoryTable = vertcat(allHistoryCells{:});

    writetable(summaryTable, fullfile(params.outputRoot, 'summary.csv'), 'Encoding', 'UTF-8');
    writetable(allHistoryTable, fullfile(params.outputRoot, 'all_runs_history.csv'), 'Encoding', 'UTF-8');

    selectedDir = fullfile(params.outputRoot, 'runs', sprintf('run_%02d', selectedRun));
    copyfile(fullfile(selectedDir, 'best_schedule.csv'), fullfile(params.outputRoot, 'selected_schedule.csv'));
    copyfile(fullfile(selectedDir, 'ga_history.csv'), fullfile(params.outputRoot, 'selected_history.csv'));
    copyfile(fullfile(selectedDir, 'best_penalty_report.txt'), fullfile(params.outputRoot, 'selected_penalty_report.txt'));

    % Backward-compatible files for the existing visualization workflow.
    copyfile(fullfile(selectedDir, 'best_schedule.csv'), 'best_schedule.csv');
    copyfile(fullfile(selectedDir, 'ga_history.csv'), 'ga_history.csv');
    copyfile(fullfile(selectedDir, 'best_penalty_report.txt'), 'best_penalty_report.txt');
    copyfile(fullfile(params.outputRoot, 'summary.csv'), 'ga_30run_summary.csv');
    copyfile(fullfile(params.outputRoot, 'all_runs_history.csv'), 'ga_30run_history.csv');

    fprintf('\n============================================================\n');
    fprintf('30-run experiment finished.\n');
    fprintf('Selected run for timetable visualization: run_%02d\n', selectedRun);
    fprintf('Selected best penalty = %.2f\n', globalBestPenalty);
    fprintf('Feasible runs with hard penalty = 0: %d/%d\n', sum(summaryFeasible), params.numRuns);
    fprintf('Mean final best penalty = %.2f | Std = %.2f\n', mean(summaryBest), std(summaryBest));
    fprintf('Files written: best_schedule.csv, ga_history.csv, ga_30run_summary.csv, ga_30run_history.csv\n');
    fprintf('Detailed results folder: %s\n', params.outputRoot);
end

function [bestIndividual, bestPenalty, bestDetail, history] = runSingleGA(data, params, runID)
    population = cell(params.popSize, 1);
    for i = 1:params.popSize
        population{i} = createRandomIndividual(data, params);
    end

    bestIndividual = [];
    bestPenalty = inf;
    bestDetail = [];
    stallCounter = 0;
    history = zeros(params.maxGen, 4);  % generation, best, mean, best hard penalty

    for gen = 1:params.maxGen
        penalties = zeros(params.popSize, 1);
        hardParts = zeros(params.popSize, 1);
        softParts = zeros(params.popSize, 1);
        details = cell(params.popSize, 1);

        for i = 1:params.popSize
            [penalties(i), details{i}] = evaluateIndividual(population{i}, data);
            hardParts(i) = details{i}.hardPenalty;
            softParts(i) = details{i}.softPenalty;
        end

        % Local improvement is applied only to a few elite feasible individuals.
        % This directly fixes the observed issue: the GA finds feasibility very quickly
        % but then remains trapped around soft penalties such as 520/530.
        [generationBestPenalty, bestIdx] = min(penalties);
        generationBestHard = hardParts(bestIdx);

        doLocalImprove = (generationBestHard == 0) && ...
            (gen <= 5 || mod(gen, params.localImproveInterval) == 0 || stallCounter >= params.localImproveStallTrigger);

        if doLocalImprove
            [~, eliteOrder] = sort(penalties, 'ascend');
            eliteCount = min(params.localImproveEliteCount, numel(eliteOrder));

            for kk = 1:eliteCount
                idx = eliteOrder(kk);
                if hardParts(idx) ~= 0
                    continue;
                end

                [cand, candPenalty, candDetail] = localImproveFocused(population{idx}, data, params);
                if candDetail.hardPenalty == 0 && candPenalty < penalties(idx)
                    population{idx} = cand;
                    penalties(idx) = candPenalty;
                    hardParts(idx) = candDetail.hardPenalty;
                    softParts(idx) = candDetail.softPenalty;
                    details{idx} = candDetail;
                end
            end

            [generationBestPenalty, bestIdx] = min(penalties);
            generationBestHard = hardParts(bestIdx);
        end

        generationMeanPenalty = mean(penalties);
        history(gen, :) = [gen, generationBestPenalty, generationMeanPenalty, generationBestHard];

        if generationBestPenalty < bestPenalty
            bestPenalty = generationBestPenalty;
            bestIndividual = population{bestIdx};
            bestDetail = details{bestIdx};
            stallCounter = 0;
        else
            stallCounter = stallCounter + 1;
        end

        if mod(gen, params.printEvery) == 0 || gen == 1
            fprintf('Run %02d | Gen %4d | best = %.2f | mean = %.2f | hard(best) = %.2f | soft(best) = %.2f\n', ...
                runID, gen, generationBestPenalty, generationMeanPenalty, hardParts(bestIdx), softParts(bestIdx));
        end

        if bestDetail.hardPenalty == 0 && bestPenalty <= params.targetPenalty
            fprintf('Run %02d target reached: best penalty <= %.2f.\n', runID, params.targetPenalty);
            history = history(1:gen, :);
            break;
        end

        if bestDetail.hardPenalty == 0 && stallCounter >= params.stallLimit
            fprintf('Run %02d early stop: hard penalty = 0 and no improvement for %d generations.\n', ...
                runID, params.stallLimit);
            history = history(1:gen, :);
            break;
        end

        population = createNextGeneration(population, penalties, params, data);
    end

    % Final focused local improvement on the best feasible solution.
    [bestPenalty, bestDetail] = evaluateIndividual(bestIndividual, data);
    if bestDetail.hardPenalty == 0
        [bestIndividual, bestPenalty, bestDetail] = localImproveFocused(bestIndividual, data, params);
    end
end

function data = buildData()
    data.days = {'Mon','Tue','Wed','Thu','Fri'};
    data.daysCN = {'星期一','星期二','星期三','星期四','星期五'};
    data.sectionStart = [8*60+15, 9*60+10, 10*60+15, 11*60+10, ...
                         13*60+50, 14*60+45, 15*60+40, 16*60+45, ...
                         17*60+40, 19*60+20, 20*60+15, 21*60+10];
    data.sectionEnd   = [9*60, 9*60+55, 11*60, 11*60+55, ...
                         14*60+35, 15*60+30, 16*60+25, 17*60+30, ...
                         18*60+25, 20*60+5, 21*60, 21*60+55];
    data.sectionLabel = {'第一节','第二节','第三节','第四节','第五节','第六节', ...
                         '第七节','第八节','第九节','第十节','第十一节','第十二节'};
    data.bigSectionLabel = {'第一大节','第一大节','第二大节','第二大节', ...
                            '第三大节','第三大节','第三大节','第四大节', ...
                            '第四大节','第五大节','第五大节','第五大节'};

    data.rooms = makeRooms();
    data.professors = makeProfessors();
    data.events = makeEvents();

    % Penalty weights. Hard weights are intentionally much larger than soft weights.
    data.W.invalidTime = 3000;
    data.W.roomCapacity = 2600;
    data.W.fixedCampus = 2800;
    data.W.profQualification = 2800;
    data.W.profAvailability = 2300;
    data.W.roomOverlap = 3600;
    data.W.profOverlap = 3600;
    data.W.studentOverlap = 3400;
    data.W.studentShortGap = 900;
    data.W.profWeeklyLoad = 1100;
    data.W.profShortGap = 800;
    data.W.profCommute = 2200;
    data.W.labBeforeTheory = 2400;
    data.W.courseCampusMismatch = 2200;
    data.W.softTheoryMorning = 40;
    data.W.softLabAfternoon = 32;
    data.W.softNoEvening = 6;
    data.W.softDailyCampusSwitch = 55;        % Soft: avoid a professor commuting between campuses in one day.
    data.W.softTheoryLabSameProfessor = 80;  % Soft: prefer matching theory/lab occurrence taught by the same professor.
end

function rooms = makeRooms()
    rooms = struct('name', {}, 'campusID', {}, 'campusName', {}, ...
                   'building', {}, 'capacity', {}, 'sizeType', {}, 'fullName', {});

    rooms = addRoom(rooms, 'C301', 1, '望江校区', '基础教学楼C座', 50, '小教室');
    rooms = addRoom(rooms, 'C305', 1, '望江校区', '基础教学楼C座', 50, '小教室');
    rooms = addRoom(rooms, 'C306', 1, '望江校区', '基础教学楼C座', 50, '小教室');

    rooms = addRoom(rooms, 'A107', 2, '江安校区', '教学楼A座', 50, '小教室');
    rooms = addRoom(rooms, 'A305', 2, '江安校区', '教学楼A座', 50, '小教室');
    rooms = addRoom(rooms, 'A507', 2, '江安校区', '教学楼A座', 50, '小教室');
    rooms = addRoom(rooms, 'B109', 2, '江安校区', '综合楼', 50, '小教室');
    rooms = addRoom(rooms, 'C203', 2, '江安校区', '综合楼', 120, '大教室');
    rooms = addRoom(rooms, 'C106', 2, '江安校区', '综合楼', 120, '大教室');
end

function rooms = addRoom(rooms, name, campusID, campusName, building, capacity, sizeType)
    idx = numel(rooms) + 1;
    rooms(idx).name = name;
    rooms(idx).campusID = campusID;
    rooms(idx).campusName = campusName;
    rooms(idx).building = building;
    rooms(idx).capacity = capacity;
    rooms(idx).sizeType = sizeType;
    rooms(idx).fullName = [campusName '-' building '-' name];
end

function professors = makeProfessors()
    professors = struct('code', {}, 'name', {}, 'allowedBases', {});
    professors(1).code = 'A'; professors(1).name = 'Prof. Zhao';  professors(1).allowedBases = {'Elective_A'};
    professors(2).code = 'B'; professors(2).name = 'Prof. Sun';   professors(2).allowedBases = {'Elective_B'};
    professors(3).code = 'C'; professors(3).name = 'Prof. Liu';   professors(3).allowedBases = {'Required_A','Required_C'};
    professors(4).code = 'D'; professors(4).name = 'Prof. Zhou';  professors(4).allowedBases = {'Required_B'};
    professors(5).code = 'E'; professors(5).name = 'Prof. Zhang'; professors(5).allowedBases = {'Required_B','Required_C'};
    professors(6).code = 'F'; professors(6).name = 'Prof. Luo';   professors(6).allowedBases = {'Required_A','Required_C'};
end

function events = makeEvents()
    events = struct('name', {}, 'displayName', {}, 'base', {}, 'baseName', {}, ...
                    'kind', {}, 'kindName', {}, 'occurrence', {}, 'duration', {}, ...
                    'enrollment', {}, 'fixedCampus', {}, 'preference', {});

    % Required theory courses: 3 meetings/week, 3 sections/meeting.
    events = addRepeated(events, '系统结构', 'Required_A', 'Theory', '理论课', 3, 3, 49, 1, 'morning');
    events = addRepeated(events, '微积分',   'Required_B', 'Theory', '理论课', 3, 3, 90, 0, 'morning');
    events = addRepeated(events, '编译原理', 'Required_C', 'Theory', '理论课', 3, 3, 49, 0, 'morning');

    % Required labs: 3 meetings/week, 2 sections/meeting.
    events = addRepeated(events, '系统结构课程设计', 'Required_A', 'Lab', '实验课', 3, 2, 49, 1, 'afternoon');
    events = addRepeated(events, '编译原理课程设计', 'Required_C', 'Lab', '实验课', 3, 2, 49, 0, 'afternoon');

    % Elective courses: 1 meeting/week, 2 sections/meeting.
    events = addOne(events, '模式识别', 'Elective_A', 'Elective', '选修课', 1, 2, 37, 0, 'any');
    events = addOne(events, '进化计算', 'Elective_B', 'Elective', '选修课', 1, 2, 37, 0, 'any');
end

function events = addRepeated(events, baseName, base, kind, kindName, count, duration, enrollment, fixedCampus, preference)
    for k = 1:count
        events = addOne(events, baseName, base, kind, kindName, k, duration, enrollment, fixedCampus, preference);
    end
end

function events = addOne(events, baseName, base, kind, kindName, occurrence, duration, enrollment, fixedCampus, preference)
    idx = numel(events) + 1;
    if strcmp(kind, 'Elective')
        displayName = sprintf('%s_01', baseName);
    elseif strcmp(kind, 'Theory')
        displayName = sprintf('%s_理论_%02d', baseName, occurrence);
    else
        displayName = sprintf('%s_实验_%02d', baseName, occurrence);
    end
    events(idx).name = displayName;
    events(idx).displayName = displayName;
    events(idx).base = base;
    events(idx).baseName = baseName;
    events(idx).kind = kind;
    events(idx).kindName = kindName;
    events(idx).occurrence = occurrence;
    events(idx).duration = duration;
    events(idx).enrollment = enrollment;
    events(idx).fixedCampus = fixedCampus; % 0 means both campuses are allowed.
    events(idx).preference = preference;
end

function individual = createRandomIndividual(data, params)
    nEvents = numel(data.events);
    individual = zeros(nEvents, 4); % columns: day, startSection, roomIndex, professorIndex

    % Give each base course an initial campus to reduce theory-lab campus mismatch.
    baseCampus.Required_A = 1;
    baseCampus.Required_B = chooseFeasibleCampusForBase('Required_B', data);
    baseCampus.Required_C = chooseFeasibleCampusForBase('Required_C', data);

    order = initialSchedulingOrder(data);
    placed = [];

    for ii = 1:numel(order)
        e = order(ii);
        evt = data.events(e);
        preferredCampus = campusForEventBase(evt, baseCampus);
        [bestGene, found] = sampleGoodGene(e, individual, placed, data, preferredCampus, params.repairAttempts);
        if found
            individual(e, :) = bestGene;
        else
            individual(e, 1) = randi(5);
            starts = preferredStartSections(evt);
            individual(e, 2) = starts(randi(numel(starts)));
            roomIds = allowedRoomsForEvent(evt, data, preferredCampus);
            individual(e, 3) = roomIds(randi(numel(roomIds)));
            profIds = eligibleProfessors(evt, data);
            individual(e, 4) = profIds(randi(numel(profIds)));
        end
        placed(end+1) = e; %#ok<AGROW>
    end

    individual = repairIndividual(individual, data, params);
end

function order = initialSchedulingOrder(data)
    % Theory events first, then labs, then electives. Randomization preserves diversity.
    theory = [];
    lab = [];
    elective = [];
    for e = 1:numel(data.events)
        if strcmp(data.events(e).kind, 'Theory')
            theory(end+1) = e; %#ok<AGROW>
        elseif strcmp(data.events(e).kind, 'Lab')
            lab(end+1) = e; %#ok<AGROW>
        else
            elective(end+1) = e; %#ok<AGROW>
        end
    end
    theory = theory(randperm(numel(theory)));
    lab = lab(randperm(numel(lab)));
    elective = elective(randperm(numel(elective)));
    order = [theory, lab, elective];
end

function [gene, found] = sampleGoodGene(e, individual, placed, data, preferredCampus, attempts)
    evt = data.events(e);
    roomIds = allowedRoomsForEvent(evt, data, preferredCampus);
    profIds = eligibleProfessors(evt, data);
    startPool = preferredStartSections(evt);

    bestScore = inf;
    gene = zeros(1, 4);
    found = false;

    for t = 1:attempts
        candidate = zeros(1, 4);
        candidate(1) = randi(5);
        candidate(2) = startPool(randi(numel(startPool)));
        candidate(3) = roomIds(randi(numel(roomIds)));
        candidate(4) = profIds(randi(numel(profIds)));

        tmp = individual;
        tmp(e, :) = candidate;
        score = 0;

        if ~isProfessorAvailable(data.professors(candidate(4)).code, ...
                data.sectionStart(candidate(2)), ...
                data.sectionEnd(candidate(2) + evt.duration - 1), ...
                data.rooms(candidate(3)).campusID)
            score = score + 100;
        end
        for p = placed
            if tmp(p, 1) == candidate(1)
                if eventsOverlap(tmp, e, p, data)
                    score = score + 1000;
                else
                    [s1, e1] = eventStartEndMinutes(tmp, e, data);
                    [s2, e2] = eventStartEndMinutes(tmp, p, data);
                    if timeGapMinutes(s1, e1, s2, e2) < 20
                        score = score + 100;
                    end
                end
                if tmp(p, 3) == candidate(3) && eventsOverlap(tmp, e, p, data)
                    score = score + 1000;
                end
                if tmp(p, 4) == candidate(4) && eventsOverlap(tmp, e, p, data)
                    score = score + 1000;
                end
            end
        end
        if score < bestScore
            bestScore = score;
            gene = candidate;
            found = true;
        end
        if score == 0
            return;
        end
    end
end

function campus = chooseFeasibleCampusForBase(base, data)
    campuses = feasibleCampusesForBase(base, data);
    campus = campuses(randi(numel(campuses)));
end

function campus = campusForEventBase(evt, baseCampus)
    campus = 0;
    if strcmp(evt.base, 'Required_A')
        campus = baseCampus.Required_A;
    elseif strcmp(evt.base, 'Required_B')
        campus = baseCampus.Required_B;
    elseif strcmp(evt.base, 'Required_C')
        campus = baseCampus.Required_C;
    end
end

function starts = preferredStartSections(evt)
    allStarts = validStartSections(evt.duration);
    if strcmp(evt.preference, 'morning')
        preferred = allStarts(allStarts <= 2); % 3-section classes: 1-3 or 2-4
        if rand < 0.90 && ~isempty(preferred)
            starts = preferred;
            return;
        end
    elseif strcmp(evt.preference, 'afternoon')
        preferred = allStarts(allStarts >= 5 & allStarts <= 8);
        if rand < 0.90 && ~isempty(preferred)
            starts = preferred;
            return;
        end
    end
    starts = allStarts;
end

function starts = validStartSections(duration)
    starts = [];
    for s = 1:(12 - duration + 1)
        last = s + duration - 1;
        crossesLunch = (s <= 4 && last >= 5);
        crossesDinner = (s <= 9 && last >= 10);
        if ~crossesLunch && ~crossesDinner
            starts(end+1) = s; %#ok<AGROW>
        end
    end
end

function ids = allowedRoomsForEvent(evt, data, preferredCampus)
    ids = [];
    for r = 1:numel(data.rooms)
        room = data.rooms(r);
        if room.capacity < evt.enrollment
            continue;
        end
        if evt.fixedCampus ~= 0 && room.campusID ~= evt.fixedCampus
            continue;
        end
        if preferredCampus ~= 0 && room.campusID ~= preferredCampus
            continue;
        end
        ids(end+1) = r; %#ok<AGROW>
    end

    if isempty(ids) && preferredCampus ~= 0
        % If the preferred campus has no feasible room, fall back to all feasible rooms.
        ids = allowedRoomsForEvent(evt, data, 0);
    end
end


function ids = strictAllowedRoomsForEvent(evt, data, campusID)
    ids = [];
    for r = 1:numel(data.rooms)
        room = data.rooms(r);
        if room.capacity < evt.enrollment
            continue;
        end
        if evt.fixedCampus ~= 0 && room.campusID ~= evt.fixedCampus
            continue;
        end
        if campusID ~= 0 && room.campusID ~= campusID
            continue;
        end
        ids(end+1) = r; %#ok<AGROW>
    end
end

function campuses = feasibleCampusesForBase(base, data)
    eventIdx = findBaseIndices(data, base);
    campuses = [];
    for c = 1:2
        ok = true;
        for idx = eventIdx
            evt = data.events(idx);
            if evt.fixedCampus ~= 0 && evt.fixedCampus ~= c
                ok = false;
                break;
            end
            roomIds = strictAllowedRoomsForEvent(evt, data, c);
            if isempty(roomIds)
                ok = false;
                break;
            end
        end
        if ok
            campuses(end+1) = c; %#ok<AGROW>
        end
    end
    if isempty(campuses)
        campuses = 1:2;
    end
end

function ids = eligibleProfessors(evt, data)
    ids = [];
    for p = 1:numel(data.professors)
        if any(strcmp(data.professors(p).allowedBases, evt.base))
            ids(end+1) = p; %#ok<AGROW>
        end
    end
end

function nextPopulation = createNextGeneration(population, penalties, params, data)
    [~, order] = sort(penalties, 'ascend');
    nextPopulation = cell(params.popSize, 1);
    for i = 1:params.eliteCount
        nextPopulation{i} = population{order(i)};
    end

    writePos = params.eliteCount + 1;
    while writePos <= params.popSize
        parent1 = population{tournamentSelect(penalties, params.tournamentSize)};
        parent2 = population{tournamentSelect(penalties, params.tournamentSize)};
        [child1, child2] = crossoverIndividuals(parent1, parent2, params.crossoverRate, data);
        child1 = mutateIndividual(child1, params, data);
        child2 = mutateIndividual(child2, params, data);
        child1 = repairIndividual(child1, data, params);
        child2 = repairIndividual(child2, data, params);

        nextPopulation{writePos} = child1;
        if writePos + 1 <= params.popSize
            nextPopulation{writePos + 1} = child2;
        end
        writePos = writePos + 2;
    end
end

function idx = tournamentSelect(penalties, tournamentSize)
    candidates = randi(numel(penalties), tournamentSize, 1);
    [~, bestLocal] = min(penalties(candidates));
    idx = candidates(bestLocal);
end

function [child1, child2] = crossoverIndividuals(parent1, parent2, crossoverRate, data)
    child1 = parent1;
    child2 = parent2;
    if rand > crossoverRate
        return;
    end

    % Block-aware crossover.
    % Instead of exchanging isolated event genes, exchange meaningful course blocks
    % or matched theory-lab pairs. This preserves useful building blocks and reduces
    % the chance that crossover destroys theory/lab professor and campus structure.
    groups = crossoverGroups(data);

    for g = 1:numel(groups)
        if rand < 0.50
            idxs = groups{g};
            child1(idxs, :) = parent2(idxs, :);
            child2(idxs, :) = parent1(idxs, :);
        end
    end

    % Small uniform mixing for remaining diversity.
    if rand < 0.20
        nEvents = size(parent1, 1);
        mask = rand(nEvents, 1) < 0.15;
        child1(mask, :) = parent2(mask, :);
        child2(mask, :) = parent1(mask, :);
    end
end

function groups = crossoverGroups(data)
    groups = {};

    % Whole-course blocks.
    bases = {'Required_A','Required_B','Required_C','Elective_A','Elective_B'};
    for b = 1:numel(bases)
        idxs = findBaseIndices(data, bases{b});
        if ~isempty(idxs)
            groups{end+1} = idxs; %#ok<AGROW>
        end
    end

    % Matched theory-lab occurrence blocks for courses that have labs.
    labBases = {'Required_A','Required_C'};
    for b = 1:numel(labBases)
        base = labBases{b};
        for occ = 1:3
            theoryIdx = findOneEventIndex(data, base, 'Theory', occ);
            labIdx = findOneEventIndex(data, base, 'Lab', occ);
            groups{end+1} = [theoryIdx, labIdx]; %#ok<AGROW>
        end
    end
end

function individual = mutateIndividual(individual, params, data)
    if rand > params.mutationRate
        return;
    end
    nEvents = size(individual, 1);
    for e = 1:nEvents
        if rand < params.geneMutationRate
            evt = data.events(e);
            mutationType = randi(6);
            switch mutationType
                case 1
                    individual(e, 1) = randi(5); % day
                case 2
                    starts = validStartSections(evt.duration);
                    individual(e, 2) = starts(randi(numel(starts))); % start section
                case 3
                    roomIds = allowedRoomsForEvent(evt, data, 0);
                    individual(e, 3) = roomIds(randi(numel(roomIds))); % room
                case 4
                    profIds = eligibleProfessors(evt, data);
                    individual(e, 4) = profIds(randi(numel(profIds))); % professor
                case 5
                    individual = mutateMatchedPairProfessor(individual, e, data);
                case 6
                    individual = mutatePreferenceStart(individual, e, data);
            end
        end
    end
end

function individual = mutateMatchedPairProfessor(individual, e, data)
    evt = data.events(e);

    if ~(strcmp(evt.kind, 'Theory') || strcmp(evt.kind, 'Lab'))
        return;
    end
    if ~(strcmp(evt.base, 'Required_A') || strcmp(evt.base, 'Required_C'))
        return;
    end

    theoryIdx = findOneEventIndex(data, evt.base, 'Theory', evt.occurrence);
    labIdx = findOneEventIndex(data, evt.base, 'Lab', evt.occurrence);

    commonProfIds = intersect(eligibleProfessors(data.events(theoryIdx), data), ...
                              eligibleProfessors(data.events(labIdx), data));
    if isempty(commonProfIds)
        return;
    end

    newProf = commonProfIds(randi(numel(commonProfIds)));
    individual(theoryIdx, 4) = newProf;
    individual(labIdx, 4) = newProf;
end

function individual = mutatePreferenceStart(individual, e, data)
    evt = data.events(e);
    starts = validStartSections(evt.duration);

    if strcmp(evt.preference, 'morning')
        preferred = starts(starts <= 2);
        if ~isempty(preferred)
            starts = preferred;
        end
    elseif strcmp(evt.preference, 'afternoon')
        preferred = starts(starts >= 5 & starts <= 8);
        if ~isempty(preferred)
            starts = preferred;
        end
    else
        nonEvening = starts(starts < 10);
        if ~isempty(nonEvening)
            starts = nonEvening;
        end
    end

    individual(e, 1) = randi(5);
    individual(e, 2) = starts(randi(numel(starts)));
end

function individual = repairIndividual(individual, data, params)
    nEvents = numel(data.events);

    % Valid day/start/professor/room range repair.
    for e = 1:nEvents
        evt = data.events(e);
        if individual(e,1) < 1 || individual(e,1) > 5
            individual(e,1) = randi(5);
        end
        if ~isValidStart(individual(e,2), evt.duration)
            starts = validStartSections(evt.duration);
            individual(e,2) = starts(randi(numel(starts)));
        end
        if individual(e,3) < 1 || individual(e,3) > numel(data.rooms)
            roomIds = allowedRoomsForEvent(evt, data, 0);
            individual(e,3) = roomIds(randi(numel(roomIds)));
        end
        if individual(e,4) < 1 || individual(e,4) > numel(data.professors) || ...
                ~any(strcmp(data.professors(individual(e,4)).allowedBases, evt.base))
            profIds = eligibleProfessors(evt, data);
            individual(e,4) = profIds(randi(numel(profIds)));
        end
    end

    % Enforce theory-lab campus consistency only for required courses that actually have labs.
    requiredBases = {'Required_A','Required_C'};
    for b = 1:numel(requiredBases)
        base = requiredBases{b};
        idxs = findBaseIndices(data, base);
        feasible = feasibleCampusesForBase(base, data);
        currentCampuses = zeros(numel(idxs), 1);
        for k = 1:numel(idxs)
            currentCampuses(k) = data.rooms(individual(idxs(k),3)).campusID;
        end
        targetCampus = mode(currentCampuses);
        if ~any(feasible == targetCampus)
            targetCampus = feasible(randi(numel(feasible)));
        end
        for k = 1:numel(idxs)
            e = idxs(k);
            evt = data.events(e);
            room = data.rooms(individual(e,3));
            if room.campusID ~= targetCampus || room.capacity < evt.enrollment || ...
                    (evt.fixedCampus ~= 0 && room.campusID ~= evt.fixedCampus)
                roomIds = allowedRoomsForEvent(evt, data, targetCampus);
                individual(e,3) = roomIds(randi(numel(roomIds)));
            end
        end
    end

    % Try to repair professor availability by switching to another qualified professor.
    for e = 1:nEvents
        evt = data.events(e);
        [startMin, endMin] = eventStartEndMinutes(individual, e, data);
        campus = data.rooms(individual(e,3)).campusID;
        profIdx = individual(e,4);
        if ~isProfessorAvailable(data.professors(profIdx).code, startMin, endMin, campus)
            profIds = eligibleProfessors(evt, data);
            profIds = profIds(randperm(numel(profIds)));
            for p = profIds
                if isProfessorAvailable(data.professors(p).code, startMin, endMin, campus)
                    individual(e,4) = p;
                    break;
                end
            end
        end
    end

    % Repair student-level time conflicts: no overlap and at least 20 minutes between two courses.
    order = randperm(nEvents);
    placed = [];
    for ii = 1:nEvents
        e = order(ii);
        if hasStudentConflictWithSet(individual, e, placed, data)
            evt = data.events(e);
            roomCampus = data.rooms(individual(e,3)).campusID;
            [gene, ok] = sampleGoodGene(e, individual, placed, data, roomCampus, params.repairAttempts);
            if ok
                individual(e,:) = gene;
            else
                starts = validStartSections(evt.duration);
                individual(e,1) = randi(5);
                individual(e,2) = starts(randi(numel(starts)));
            end
        end
        placed(end+1) = e; %#ok<AGROW>
    end

    % Repair overloaded professors when an alternative qualified and available professor exists.
    individual = repairProfessorWeeklyLoad(individual, data);
end

function [individual, bestPenalty, bestDetail] = localImproveFocused(individual, data, params)
    [bestPenalty, bestDetail] = evaluateIndividual(individual, data);

    if bestDetail.hardPenalty > 0
        return;
    end

    for pass = 1:params.localImproveMaxPass
        improved = false;

        % 1) Improve matched theory-lab professor assignments.
        [candidate, candidatePenalty, candidateDetail] = improveTheoryLabProfessorMatch(individual, data);
        if candidateDetail.hardPenalty == 0 && candidatePenalty < bestPenalty
            individual = candidate;
            bestPenalty = candidatePenalty;
            bestDetail = candidateDetail;
            improved = true;
        end

        % 2) Greedy relocation to preferred time periods.
        [candidate, candidatePenalty, candidateDetail] = improveSingleEventTimes(individual, data);
        if candidateDetail.hardPenalty == 0 && candidatePenalty < bestPenalty
            individual = candidate;
            bestPenalty = candidatePenalty;
            bestDetail = candidateDetail;
            improved = true;
        end

        % 3) Swap time slots between two events. This is crucial because many
        % timetable improvements are impossible by moving only one event.
        [candidate, candidatePenalty, candidateDetail] = improveByTimeSwap(individual, data);
        if candidateDetail.hardPenalty == 0 && candidatePenalty < bestPenalty
            individual = candidate;
            bestPenalty = candidatePenalty;
            bestDetail = candidateDetail;
            improved = true;
        end

        if ~improved
            break;
        end
    end
end

function [individual, bestPenalty, bestDetail] = improveSingleEventTimes(individual, data)
    [bestPenalty, bestDetail] = evaluateIndividual(individual, data);
    nEvents = numel(data.events);

    for e = 1:nEvents
        evt = data.events(e);
        starts = preferredCandidateStarts(evt);

        for d = 1:5
            for ss = 1:numel(starts)
                s = starts(ss);
                candidate = individual;
                candidate(e, 1) = d;
                candidate(e, 2) = s;

                [candidatePenalty, candidateDetail] = evaluateIndividual(candidate, data);
                if candidateDetail.hardPenalty == 0 && candidatePenalty < bestPenalty
                    individual = candidate;
                    bestPenalty = candidatePenalty;
                    bestDetail = candidateDetail;
                end
            end
        end
    end
end

function starts = preferredCandidateStarts(evt)
    allStarts = validStartSections(evt.duration);

    if strcmp(evt.preference, 'morning')
        preferred = allStarts(allStarts <= 2);
        backup = allStarts(allStarts <= 5);
        starts = unique([preferred, backup], 'stable');
    elseif strcmp(evt.preference, 'afternoon')
        preferred = allStarts(allStarts >= 5 & allStarts <= 8);
        starts = preferred;
    else
        starts = allStarts(allStarts < 10);
    end

    if isempty(starts)
        starts = allStarts;
    end
end

function [individual, bestPenalty, bestDetail] = improveByTimeSwap(individual, data)
    [bestPenalty, bestDetail] = evaluateIndividual(individual, data);
    nEvents = numel(data.events);

    for i = 1:nEvents-1
        for j = i+1:nEvents
            candidate = individual;

            % Swap day and start section, keep room/professor unchanged.
            tmpDay = candidate(i, 1);
            tmpStart = candidate(i, 2);
            candidate(i, 1) = candidate(j, 1);
            candidate(i, 2) = candidate(j, 2);
            candidate(j, 1) = tmpDay;
            candidate(j, 2) = tmpStart;

            if ~isValidStart(candidate(i, 2), data.events(i).duration) || ...
                    ~isValidStart(candidate(j, 2), data.events(j).duration)
                continue;
            end

            [candidatePenalty, candidateDetail] = evaluateIndividual(candidate, data);
            if candidateDetail.hardPenalty == 0 && candidatePenalty < bestPenalty
                individual = candidate;
                bestPenalty = candidatePenalty;
                bestDetail = candidateDetail;
            end
        end
    end
end

function [individual, bestPenalty, bestDetail] = improveTheoryLabProfessorMatch(individual, data)
    [bestPenalty, bestDetail] = evaluateIndividual(individual, data);

    requiredBases = {'Required_A','Required_C'};

    for b = 1:numel(requiredBases)
        base = requiredBases{b};

        for occ = 1:3
            theoryIdx = findOneEventIndex(data, base, 'Theory', occ);
            labIdx = findOneEventIndex(data, base, 'Lab', occ);

            if individual(theoryIdx, 4) == individual(labIdx, 4)
                continue;
            end

            % Try 1: let lab use the theory professor.
            candidate = individual;
            candidate(labIdx, 4) = individual(theoryIdx, 4);

            [candidatePenalty, candidateDetail] = evaluateIndividual(candidate, data);
            if candidateDetail.hardPenalty == 0 && candidatePenalty < bestPenalty
                individual = candidate;
                bestPenalty = candidatePenalty;
                bestDetail = candidateDetail;
                continue;
            end

            % Try 2: let theory use the lab professor.
            candidate = individual;
            candidate(theoryIdx, 4) = individual(labIdx, 4);

            [candidatePenalty, candidateDetail] = evaluateIndividual(candidate, data);
            if candidateDetail.hardPenalty == 0 && candidatePenalty < bestPenalty
                individual = candidate;
                bestPenalty = candidatePenalty;
                bestDetail = candidateDetail;
            end
        end
    end
end

function individual = repairProfessorWeeklyLoad(individual, data)
    for iter = 1:3
        changed = false;
        for p = 1:numel(data.professors)
            loadCount = sum(individual(:,4) == p);
            if loadCount <= 5
                continue;
            end
            idxs = find(individual(:,4) == p)';
            idxs = idxs(randperm(numel(idxs)));
            for e = idxs
                if sum(individual(:,4) == p) <= 5
                    break;
                end
                evt = data.events(e);
                profIds = eligibleProfessors(evt, data);
                profIds = profIds(profIds ~= p);
                if isempty(profIds)
                    continue;
                end
                profIds = profIds(randperm(numel(profIds)));
                [startMin, endMin] = eventStartEndMinutes(individual, e, data);
                campus = data.rooms(individual(e,3)).campusID;
                for p2 = profIds
                    if sum(individual(:,4) == p2) >= 5
                        continue;
                    end
                    if isProfessorAvailable(data.professors(p2).code, startMin, endMin, campus)
                        individual(e,4) = p2;
                        changed = true;
                        break;
                    end
                end
            end
        end
        if ~changed
            break;
        end
    end
end

function conflict = hasStudentConflictWithSet(individual, e, placed, data)
    conflict = false;
    for p = placed
        if individual(e,1) ~= individual(p,1)
            continue;
        end
        if eventsOverlap(individual, e, p, data)
            conflict = true;
            return;
        end
        [s1, e1] = eventStartEndMinutes(individual, e, data);
        [s2, e2] = eventStartEndMinutes(individual, p, data);
        if timeGapMinutes(s1, e1, s2, e2) < 20
            conflict = true;
            return;
        end
    end
end

function [totalPenalty, detail] = evaluateIndividual(individual, data)
    hardPenalty = 0;
    softPenalty = 0;

    detail.invalidTime = 0;
    detail.roomCapacity = 0;
    detail.fixedCampus = 0;
    detail.profQualification = 0;
    detail.profAvailability = 0;
    detail.roomOverlap = 0;
    detail.profOverlap = 0;
    detail.studentOverlap = 0;
    detail.studentShortGap = 0;
    detail.profWeeklyLoad = 0;
    detail.profShortGap = 0;
    detail.profCommute = 0;
    detail.labBeforeTheory = 0;
    detail.courseCampusMismatch = 0;
    detail.softTheoryMorning = 0;
    detail.softLabAfternoon = 0;
    detail.softNoEvening = 0;
    detail.softDailyCampusSwitch = 0;
    detail.softTheoryLabSameProfessor = 0;

    nEvents = numel(data.events);

    % 1) Single-event constraints.
    for e = 1:nEvents
        evt = data.events(e);
        day = individual(e, 1);
        startSec = individual(e, 2);
        roomIdx = individual(e, 3);
        profIdx = individual(e, 4);

        if day < 1 || day > 5 || startSec < 1 || startSec + evt.duration - 1 > 12 || ...
                roomIdx < 1 || roomIdx > numel(data.rooms) || profIdx < 1 || profIdx > numel(data.professors)
            hardPenalty = hardPenalty + data.W.invalidTime;
            detail.invalidTime = detail.invalidTime + 1;
            continue;
        end

        if ~isValidStart(startSec, evt.duration)
            hardPenalty = hardPenalty + data.W.invalidTime;
            detail.invalidTime = detail.invalidTime + 1;
        end

        room = data.rooms(roomIdx);
        if room.capacity < evt.enrollment
            hardPenalty = hardPenalty + data.W.roomCapacity;
            detail.roomCapacity = detail.roomCapacity + 1;
        end

        if evt.fixedCampus ~= 0 && room.campusID ~= evt.fixedCampus
            hardPenalty = hardPenalty + data.W.fixedCampus;
            detail.fixedCampus = detail.fixedCampus + 1;
        end

        if ~any(strcmp(data.professors(profIdx).allowedBases, evt.base))
            hardPenalty = hardPenalty + data.W.profQualification;
            detail.profQualification = detail.profQualification + 1;
        end

        [startMin, endMin] = eventStartEndMinutes(individual, e, data);
        if ~isProfessorAvailable(data.professors(profIdx).code, startMin, endMin, room.campusID)
            hardPenalty = hardPenalty + data.W.profAvailability;
            detail.profAvailability = detail.profAvailability + 1;
        end

        % Soft preferences: required theories in the morning, required labs in the afternoon.
        if strcmp(evt.preference, 'morning') && startSec > 4
            penalty = data.W.softTheoryMorning * (startSec - 4);
            softPenalty = softPenalty + penalty;
            detail.softTheoryMorning = detail.softTheoryMorning + penalty;
        elseif strcmp(evt.preference, 'afternoon') && (startSec < 5 || startSec > 9)
            if startSec < 5
                penalty = data.W.softLabAfternoon * (5 - startSec);
            else
                penalty = data.W.softLabAfternoon * (startSec - 9);
            end
            softPenalty = softPenalty + penalty;
            detail.softLabAfternoon = detail.softLabAfternoon + penalty;
        end
        if startSec >= 10
            penalty = data.W.softNoEvening;
            softPenalty = softPenalty + penalty;
            detail.softNoEvening = detail.softNoEvening + penalty;
        end
    end

    % 2) Pairwise constraints.
    for i = 1:nEvents-1
        for j = i+1:nEvents
            if individual(i, 1) ~= individual(j, 1)
                continue;
            end

            overlap = eventsOverlap(individual, i, j, data);
            sameRoom = individual(i, 3) == individual(j, 3);
            sameProfessor = individual(i, 4) == individual(j, 4);

            % Global student-level timetable constraint: no two classes at the same time.
            if overlap
                hardPenalty = hardPenalty + data.W.studentOverlap;
                detail.studentOverlap = detail.studentOverlap + 1;
            else
                [s1, e1] = eventStartEndMinutes(individual, i, data);
                [s2, e2] = eventStartEndMinutes(individual, j, data);
                gap = timeGapMinutes(s1, e1, s2, e2);
                if gap < 20
                    hardPenalty = hardPenalty + data.W.studentShortGap;
                    detail.studentShortGap = detail.studentShortGap + 1;
                end
            end

            if sameRoom && overlap
                hardPenalty = hardPenalty + data.W.roomOverlap;
                detail.roomOverlap = detail.roomOverlap + 1;
            end
            if sameProfessor && overlap
                hardPenalty = hardPenalty + data.W.profOverlap;
                detail.profOverlap = detail.profOverlap + 1;
            end

            if sameProfessor && ~overlap
                [s1, e1] = eventStartEndMinutes(individual, i, data);
                [s2, e2] = eventStartEndMinutes(individual, j, data);
                gap = timeGapMinutes(s1, e1, s2, e2);
                campus1 = data.rooms(individual(i, 3)).campusID;
                campus2 = data.rooms(individual(j, 3)).campusID;
                if gap < 20
                    hardPenalty = hardPenalty + data.W.profShortGap;
                    detail.profShortGap = detail.profShortGap + 1;
                end
                if campus1 ~= campus2 && gap < 50
                    hardPenalty = hardPenalty + data.W.profCommute;
                    detail.profCommute = detail.profCommute + 1;
                end
            end
        end
    end

    % 3) Professor weekly load: no more than 5 teaching meetings per week.
    for p = 1:numel(data.professors)
        loadCount = sum(individual(:, 4) == p);
        if loadCount > 5
            hardPenalty = hardPenalty + data.W.profWeeklyLoad * (loadCount - 5);
            detail.profWeeklyLoad = detail.profWeeklyLoad + (loadCount - 5);
        end
    end

    % 4) Labs must not be scheduled before their corresponding theory occurrence.
    % Required_B / 微积分 has no paired lab, so it must not be checked here.
    requiredBases = {'Required_A','Required_C'};
    for b = 1:numel(requiredBases)
        base = requiredBases{b};
        for occ = 1:3
            theoryIdx = findOneEventIndex(data, base, 'Theory', occ);
            labIdx = findOneEventIndex(data, base, 'Lab', occ);
            [~, theoryEnd] = eventStartEndMinutes(individual, theoryIdx, data);
            [labStart, ~] = eventStartEndMinutes(individual, labIdx, data);
            theoryEndAbs = (individual(theoryIdx, 1) - 1) * 24 * 60 + theoryEnd;
            labStartAbs = (individual(labIdx, 1) - 1) * 24 * 60 + labStart;
            if labStartAbs <= theoryEndAbs
                hardPenalty = hardPenalty + data.W.labBeforeTheory;
                detail.labBeforeTheory = detail.labBeforeTheory + 1;
            end
        end
    end

    % 5) Required theory and its corresponding lab should stay on the same campus.
    for b = 1:numel(requiredBases)
        base = requiredBases{b};
        idxs = findBaseIndices(data, base);
        campuses = zeros(numel(idxs), 1);
        for k = 1:numel(idxs)
            campuses(k) = data.rooms(individual(idxs(k), 3)).campusID;
        end
        if numel(unique(campuses)) > 1
            hardPenalty = hardPenalty + data.W.courseCampusMismatch * (numel(unique(campuses)) - 1);
            detail.courseCampusMismatch = detail.courseCampusMismatch + (numel(unique(campuses)) - 1);
        end
    end


    % 6) Soft constraint: avoid cross-campus commuting by the same professor within one day.
    % Hard commute feasibility is already checked above. This extra term makes the GA prefer
    % schedules where a professor stays on one campus during a day whenever possible.
    for p = 1:numel(data.professors)
        for d = 1:5
            idxs = find(individual(:, 4) == p & individual(:, 1) == d)';
            if numel(idxs) <= 1
                continue;
            end
            starts = zeros(numel(idxs), 1);
            campuses = zeros(numel(idxs), 1);
            for k = 1:numel(idxs)
                e = idxs(k);
                starts(k) = data.sectionStart(individual(e, 2));
                campuses(k) = data.rooms(individual(e, 3)).campusID;
            end
            [~, order] = sort(starts);
            campuses = campuses(order);
            switchCount = sum(campuses(1:end-1) ~= campuses(2:end));
            if switchCount > 0
                penalty = data.W.softDailyCampusSwitch * switchCount;
                softPenalty = softPenalty + penalty;
                detail.softDailyCampusSwitch = detail.softDailyCampusSwitch + penalty;
            end
        end
    end

    % 7) Soft constraint: prefer the same professor for matched theory/lab occurrences.
    % Example: 系统结构_理论_01 and 系统结构课程设计_实验_01 should preferably share a professor.
    for b = 1:numel(requiredBases)
        base = requiredBases{b};
        for occ = 1:3
            theoryIdx = findOneEventIndex(data, base, 'Theory', occ);
            labIdx = findOneEventIndex(data, base, 'Lab', occ);
            if individual(theoryIdx, 4) ~= individual(labIdx, 4)
                penalty = data.W.softTheoryLabSameProfessor;
                softPenalty = softPenalty + penalty;
                detail.softTheoryLabSameProfessor = detail.softTheoryLabSameProfessor + penalty;
            end
        end
    end

    totalPenalty = hardPenalty + softPenalty;
    detail.hardPenalty = hardPenalty;
    detail.softPenalty = softPenalty;
    detail.totalPenalty = totalPenalty;
end

function ok = isValidStart(startSec, duration)
    if startSec < 1 || startSec + duration - 1 > 12
        ok = false;
        return;
    end
    last = startSec + duration - 1;
    crossesLunch = (startSec <= 4 && last >= 5);
    crossesDinner = (startSec <= 9 && last >= 10);
    ok = ~(crossesLunch || crossesDinner);
end

function [startMin, endMin] = eventStartEndMinutes(individual, e, data)
    startSec = individual(e, 2);
    duration = data.events(e).duration;
    endSec = startSec + duration - 1;
    startMin = data.sectionStart(startSec);
    endMin = data.sectionEnd(endSec);
end

function overlap = eventsOverlap(individual, i, j, data)
    [s1, e1] = eventStartEndMinutes(individual, i, data);
    [s2, e2] = eventStartEndMinutes(individual, j, data);
    overlap = (s1 < e2) && (s2 < e1);
end

function gap = timeGapMinutes(s1, e1, s2, e2)
    if e1 <= s2
        gap = s2 - e1;
    elseif e2 <= s1
        gap = s1 - e2;
    else
        gap = -1; % overlap
    end
end

function ok = isProfessorAvailable(profCode, startMin, endMin, campusID)
    ok = true;
    switch profCode
        case 'A' % Prof. Zhao: before 10:00 campus 1; 10:00-15:00 unavailable; after 15:00 free.
            if intervalsOverlap(startMin, endMin, 10*60, 15*60)
                ok = false;
            end
            if startMin < 10*60 && campusID ~= 1
                ok = false;
            end
        case 'B' % Prof. Sun: before 12:00 campus 2; 12:00-17:00 free; after 17:00 unavailable.
            if endMin > 17*60
                ok = false;
            end
            if startMin < 12*60 && campusID ~= 2
                ok = false;
            end
        case 'C' % Prof. Liu: available all day and both campuses.
            ok = true;
        case 'D' % Prof. Zhou: free before 12:00 only.
            if endMin > 12*60
                ok = false;
            end
        case 'E' % Prof. Zhang: before 13:00 campus 1; after 18:00 campus 2.
            if startMin < 13*60 && campusID ~= 1
                ok = false;
            end
            if endMin > 18*60 && campusID ~= 2
                ok = false;
            end
        case 'F' % Prof. Luo: before 14:00 campus 2; after 14:00 no campus restriction.
            if startMin < 14*60 && campusID ~= 2
                ok = false;
            end
        otherwise
            ok = false;
    end
end

function tf = intervalsOverlap(s1, e1, s2, e2)
    tf = (s1 < e2) && (s2 < e1);
end

function idx = findOneEventIndex(data, base, kind, occurrence)
    idx = -1;
    for i = 1:numel(data.events)
        if strcmp(data.events(i).base, base) && strcmp(data.events(i).kind, kind) && data.events(i).occurrence == occurrence
            idx = i;
            return;
        end
    end
    error('Cannot find event: %s %s %d', base, kind, occurrence);
end

function idxs = findEventIndices(data, base, kind)
    idxs = [];
    for i = 1:numel(data.events)
        if strcmp(data.events(i).base, base) && strcmp(data.events(i).kind, kind)
            idxs(end+1) = i; %#ok<AGROW>
        end
    end
end

function idxs = findBaseIndices(data, base)
    idxs = [];
    for i = 1:numel(data.events)
        if strcmp(data.events(i).base, base)
            idxs(end+1) = i; %#ok<AGROW>
        end
    end
end

function T = individualToTable(individual, data)
    n = numel(data.events);
    EventID = (1:n)';
    CourseName = cell(n, 1);
    CourseBase = cell(n, 1);
    BaseCode = cell(n, 1);
    CourseType = cell(n, 1);
    Occurrence = zeros(n, 1);
    Day = cell(n, 1);
    DayCN = cell(n, 1);
    StartSection = zeros(n, 1);
    EndSection = zeros(n, 1);
    StartTime = cell(n, 1);
    EndTime = cell(n, 1);
    CampusID = zeros(n, 1);
    Campus = cell(n, 1);
    Building = cell(n, 1);
    Room = cell(n, 1);
    RoomFullName = cell(n, 1);
    RoomCapacity = zeros(n, 1);
    RoomSizeType = cell(n, 1);
    Professor = cell(n, 1);
    ProfessorCode = cell(n, 1);
    DurationSections = zeros(n, 1);
    Enrollment = zeros(n, 1);

    for e = 1:n
        evt = data.events(e);
        room = data.rooms(individual(e, 3));
        prof = data.professors(individual(e, 4));
        [startMin, endMin] = eventStartEndMinutes(individual, e, data);

        CourseName{e} = evt.displayName;
        CourseBase{e} = evt.baseName;
        BaseCode{e} = evt.base;
        CourseType{e} = evt.kindName;
        Occurrence(e) = evt.occurrence;
        Day{e} = data.days{individual(e, 1)};
        DayCN{e} = data.daysCN{individual(e, 1)};
        StartSection(e) = individual(e, 2);
        EndSection(e) = individual(e, 2) + evt.duration - 1;
        StartTime{e} = minutesToClock(startMin);
        EndTime{e} = minutesToClock(endMin);
        CampusID(e) = room.campusID;
        Campus{e} = room.campusName;
        Building{e} = room.building;
        Room{e} = room.name;
        RoomFullName{e} = room.fullName;
        RoomCapacity(e) = room.capacity;
        RoomSizeType{e} = room.sizeType;
        Professor{e} = prof.name;
        ProfessorCode{e} = prof.code;
        DurationSections(e) = evt.duration;
        Enrollment(e) = evt.enrollment;
    end

    T = table(EventID, CourseName, CourseBase, BaseCode, CourseType, Occurrence, Day, DayCN, ...
              StartSection, EndSection, StartTime, EndTime, CampusID, Campus, Building, Room, ...
              RoomFullName, RoomCapacity, RoomSizeType, Professor, ProfessorCode, ...
              DurationSections, Enrollment);
    T = sortrows(T, {'Day','StartSection','Room'});
end

function s = minutesToClock(mins)
    h = floor(mins / 60);
    m = mod(mins, 60);
    s = sprintf('%02d:%02d', h, m);
end

function writePenaltyReport(bestPenalty, detail, filename)
    fid = fopen(filename, 'w');
    if fid < 0
        warning('Cannot write penalty report.');
        return;
    end
    fprintf(fid, 'Best total penalty: %.2f\n', bestPenalty);
    fprintf(fid, 'Hard penalty: %.2f\n', detail.hardPenalty);
    fprintf(fid, 'Soft penalty: %.2f\n\n', detail.softPenalty);

    fprintf(fid, 'Hard-constraint violation counters:\n');
    fprintf(fid, 'invalidTime: %d\n', detail.invalidTime);
    fprintf(fid, 'roomCapacity: %d\n', detail.roomCapacity);
    fprintf(fid, 'fixedCampus: %d\n', detail.fixedCampus);
    fprintf(fid, 'profQualification: %d\n', detail.profQualification);
    fprintf(fid, 'profAvailability: %d\n', detail.profAvailability);
    fprintf(fid, 'roomOverlap: %d\n', detail.roomOverlap);
    fprintf(fid, 'profOverlap: %d\n', detail.profOverlap);
    fprintf(fid, 'studentOverlap: %d\n', detail.studentOverlap);
    fprintf(fid, 'studentShortGap: %d\n', detail.studentShortGap);
    fprintf(fid, 'profWeeklyLoadOver: %d\n', detail.profWeeklyLoad);
    fprintf(fid, 'profShortGap: %d\n', detail.profShortGap);
    fprintf(fid, 'profCommute: %d\n', detail.profCommute);
    fprintf(fid, 'labBeforeTheory: %d\n', detail.labBeforeTheory);
    fprintf(fid, 'courseCampusMismatch: %d\n\n', detail.courseCampusMismatch);

    fprintf(fid, 'Soft-constraint penalties:\n');
    fprintf(fid, 'softTheoryMorning: %.2f\n', detail.softTheoryMorning);
    fprintf(fid, 'softLabAfternoon: %.2f\n', detail.softLabAfternoon);
    fprintf(fid, 'softNoEvening: %.2f\n', detail.softNoEvening);
    fprintf(fid, 'softDailyCampusSwitch: %.2f\n', detail.softDailyCampusSwitch);
    fprintf(fid, 'softTheoryLabSameProfessor: %.2f\n\n', detail.softTheoryLabSameProfessor);

    fprintf(fid, 'Interpretation:\n');
    fprintf(fid, '- Hard penalty = 0 means no violation of the hard constraints encoded in the solver.\n');
    fprintf(fid, '- Soft penalty reflects unmet preferences, including morning theory, afternoon lab, avoiding same-day cross-campus commuting, and matching theory/lab professors.\n');
    fprintf(fid, '- If hard penalty remains nonzero, increase popSize/maxGen or inspect conflicting constraints.\n');
    fclose(fid);
end
