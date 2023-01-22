function [thresh_h, metric_h] = multiTH_extract(histoCounts, N, histoStructure)
%Marco A., following multithresh()

num_bins = size(histoCounts, 2);
p = histoCounts/sum(histoCounts);
p = p';
minA = histoStructure.mosaic_min;
maxA = histoStructure.mosaic_max;

omega = cumsum(p);
mu = cumsum(p .* (1:num_bins)');
mu_t = mu(end);

if (N < 3)

    sigma_b_squared = calcFullObjCriteriaMatrix(N, num_bins, omega, mu, mu_t);

    % Find the location of the maximum value of sigma_b_squared.
    maxval = max(sigma_b_squared(:));
    isvalid_maxval = isfinite(maxval);

    if isvalid_maxval
        % Find the bin with maximum value. If the maximum extends over
        % several bins, average together the locations.
        switch N
            case 1
                idx = find(sigma_b_squared == maxval);
                % Find the intensity associated with the bin
                thresh = mean(idx) - 1;
            case 2
                [maxR, maxC] = find(sigma_b_squared == maxval);
                % Find the intensity associated with the bin
                thresh = mean([maxR maxC],1) - 1;
        end
    else
        [isDegenerate, uniqueVals] = checkForDegenerateInput(A, N);
        if isDegenerate
            warning(message('images:multithresh:degenerateInput',N));
        else
            warning(message('images:multithresh:noConvergence'));
        end
        thresh = getDegenerateThresholds(uniqueVals, N);
        metric = 0.0;
    end

else

    % For N >= 3, use search-based optimization of Otsu's objective function

    % Set initial thresholds as uniformly spaced
    initial_thresh = linspace(0, num_bins-1, N+2);
    initial_thresh = initial_thresh(2:end-1); % Retain N thresholds

    % Set optimization parameters
    options = optimset('TolX',1,'Display','off');
    % Find optimum using fminsearch
    [thresh, minval] = fminsearch(@(thresh) objCriteriaND(thresh, ...
        num_bins, omega, mu, mu_t), initial_thresh, options);

    maxval = -minval;

    isvalid_maxval = ~(isinf(maxval) || isnan(maxval));
    if isvalid_maxval
        thresh = round(thresh);
    end

end

% Prepare output values
if isvalid_maxval

    % Map back to original scale as input A
    thresh = map2OriginalScale(thresh, minA, maxA);
    
    % Compute the effectiveness metric
    metric = maxval/(sum(p.*(((1:num_bins)' - mu_t).^2)));
    

else

    [isDegenerate, uniqueVals] = checkForDegenerateInput(A, N);
    if isDegenerate
        warning(message('images:multithresh:degenerateInput',N));
        thresh = getDegenerateThresholds(uniqueVals, N);
        metric = 0.0;
    else
        warning(message('images:multithresh:noConvergence'));
        % Return latest available solution
        thresh = map2OriginalScale(thresh, minA, maxA);
        
        % Compute the effectiveness metric
        metric = maxval/(sum(p.*(((1:num_bins)' - mu_t).^2)));
        
    end

end

thresh_h = thresh;
metric_h = metric;

%--------------------------------------------------------------------------

function sigma_b_squared_val = objCriteriaND(thresh, num_bins, omega, mu, mu_t)

% 'thresh' has intensities [0-255], but 'boundaries' are the indices [1
% 256].
boundaries = round(thresh)+1;

% Constrain 'boundaries' to:
% 1. be strictly increasing,
% 2. have the lowest value > 1 (i.e. minimum 2),
% 3. have highest value < num_bins (i.e. maximum num_bins-1).
if (~all(diff([1 boundaries num_bins]) > 0))
    sigma_b_squared_val = Inf;
    return;
end

boundaries = [boundaries num_bins];

sigma_b_squared_val = omega(boundaries(1)).*((mu(boundaries(1))./omega(boundaries(1)) - mu_t).^2);

for kk = 2:length(boundaries)
    omegaKK = omega(boundaries(kk)) - omega(boundaries(kk-1));
    muKK = (mu(boundaries(kk)) - mu(boundaries(kk-1)))/omegaKK;
    sigma_b_squared_val = sigma_b_squared_val + (omegaKK.*((muKK - mu_t).^2)); % Eqn. 14 in Otsu's paper
end

if (isfinite(sigma_b_squared_val))
    sigma_b_squared_val = -sigma_b_squared_val; % To do maximization using fminsearch.
else
    sigma_b_squared_val = Inf;
end
end

%--------------------------------------------------------------------------

function sigma_b_squared = calcFullObjCriteriaMatrix(N, num_bins, omega, mu, mu_t)
if (N == 1)

    sigma_b_squared = (mu_t * omega - mu).^2 ./ (omega .* (1 - omega));

elseif (N == 2)

    % Rows represent thresh(1) (lower threshold) and columns represent
    % thresh(2) (higher threshold).
    omega0 = repmat(omega,1,num_bins);
    mu_0_t = repmat(bsxfun(@minus,mu_t,mu./omega),1,num_bins);
    omega1 = bsxfun(@minus, omega.', omega);
    mu_1_t = bsxfun(@minus,mu_t,(bsxfun(@minus, mu.', mu))./omega1);

    % Set entries corresponding to non-viable solutions to NaN
    [allPixR, allPixC] = ndgrid(1:num_bins,1:num_bins);
    pixNaN = allPixR >= allPixC; % Enforce thresh(1) < thresh(2)
    omega0(pixNaN) = NaN;
    omega1(pixNaN) = NaN;

    term1 = omega0.*(mu_0_t.^2);

    term2 = omega1.*(mu_1_t.^2);

    omega2 = 1 - (omega0+omega1);
    omega2(omega2 <= 0) = NaN; % Avoid divide-by-zero Infs in term3

    term3 = ((omega0.*mu_0_t + omega1.*mu_1_t ).^2)./omega2;

    sigma_b_squared = term1 + term2 + term3;
end
end

%--------------------------------------------------------------------------

function sclThresh = map2OriginalScale(thresh, minA, maxA)

normFactor = 255;
sclThresh = double(minA) + thresh/normFactor*(double(maxA) - double(minA));
sclThresh = cast(sclThresh,'like',minA);

end

%--------------------------------------------------------------------------
function [isDegenerate, uniqueVals] = checkForDegenerateInput(A, N)

uniqueVals = unique(A(:))'; % Note: 'uniqueVals' is returned in sorted order.

% Ignore NaNs because they are ignored in computation. Ignore Infs because
% Infs are mapped to extreme bins during histogram computation and are
% therefore not unique values.
uniqueVals(isinf(uniqueVals) | isnan(uniqueVals)) = [];

isDegenerate = (numel(uniqueVals) <= N);

end

%--------------------------------------------------------------------------
function thresh = getThreshForNoPdf(minA, maxA, N)

if isnan(minA)
    % If minA = NaN => maxA = NaN. All NaN input condition.
    minA = 1;
    maxA = 1;
end

if (N == 1)
    thresh = minA;
else
    if (minA == maxA)
        % Flat image, i.e. only one unique value (not counting Infs and
        % -Infs) exists
        thresh = getDegenerateThresholds(minA, N);
    else
        % Only scenario: A full of Infs and -Infs => minA = -Inf and maxA =
        % Inf
        thresh = getDegenerateThresholds([minA maxA], N);
    end
end

end

%--------------------------------------------------------------------------
function thresh = getDegenerateThresholds(uniqueVals, N)
% Notes:
% 1) 'uniqueVals' must be in sorted (ascending) order
% 2) For predictable behavior, 'uniqueVals' should not have NaNs
% 3) For predictable behavior for all datatypes including uint8, N must be < 255

if isempty(uniqueVals)
    thresh = cast(1:N,'like', uniqueVals);
    return;
end

% 'thresh' will always have all the elements of 'uniqueVals' in it.
thresh = uniqueVals;

thNeeded1 = N - numel(thresh);
if (thNeeded1 > 0)

    % More values are needed to fill 'thresh'. Start filling 'thresh' from
    % the lower end starting with 1.

    if (uniqueVals(1) > 1)
        % If uniqueVals(1) > 1, we can directly fill some (or maybe all)
        % values starting from 1, without checking for uniqueness.
        thresh = [cast(1:min(thNeeded1,ceil(uniqueVals(1))-1), 'like', uniqueVals)...
            thresh];
    end

    thNeeded2 = N - numel(thresh);
    if (thNeeded2  > 0)

        % More values are needed to fill 'thresh'. Use positive integer
        % values, as small as possible, which are not in 'thresh' already.
        lenThreshOrig = length(thresh);
        thresh = [thresh zeros(1,thNeeded2)]; % Create empty entries, thresh datatype preserved
        uniqueVals_d = double(uniqueVals); % Needed to convert to double for correct uniqueness check
        threshCandidate = max(floor(uniqueVals(1)),0); % Always non-negative, threshCandidate datatype preserved
        q = 1;
        while q <= thNeeded2
            threshCandidate = threshCandidate + 1;
            threshCandidate_d = double(threshCandidate); % Needed to convert to double for correct uniqueness check
            if any(abs(uniqueVals_d - threshCandidate_d) ...
                    < eps(threshCandidate_d))
                % The candidate value already exists, so don't use it.
                continue;
            else
                thresh(lenThreshOrig + q) = threshCandidate; % Append at the end
                q = q + 1;
            end
        end

        thresh = sort(thresh); % Arrange 'thresh' in ascending order

    end

end
end

end