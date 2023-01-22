%https://au.mathworks.com/matlabcentral/fileexchange/88872-incrementalpca

% Let A be a data matrix of size [d x n], that is, there are n examples of 
% d features. The principal components of A have already been calculated, 
% using the svd of the centered A matrix: [U,S,V] = svd(A - mean(A,2), 'econ')
%
% A new data matrix X of size [d x m] becomes available. This algorithm
% finds the decomposition of the concatenated matrix [A X], taking adavantage
% of the fact that A has already been decomposed. This is useful if A is
% large, or in online learning situations. 
%
% Algorithm adapted from: D. Ross, Incremental Learning for Robust Visual Tracking, 
% https://www.cs.toronto.edu/~dross/ivt/RossLimLinYang_ijcv.pdf
%
% Inputs: 
%   X - new data matrix size [d x m]
%   U - principal components (PC's) previously found from A
%   S - principal values previously found from A
%   mu - sample mean of A
%   n_samples_seen - total number of data samples used to obtain U and S. 
%   n_components (optional, default=keep all) - number of principal 
%       components to keep. Use [] for default. 
%   energy_thresh (optional, scalar 0 to 1) - if set, and n_components==[],
%       determine n_components by capturing this fraction of variance
%
% Outputs:
%   U_new - update principal components
%   S_new - updated singular values
%   mu_new - updated sample mean
%   n_samples_seen - the total number of samples that have now been used to 
%                     estimate U, S, mu
% 
%
% EXAMPLE 1 (copy and paste):
%
% d = 5;
% n_samples_seen = 20;
% A = rand(d, n_samples_seen);
% mu = mean(A,2);
% [U,S,~] = svd(A - mu, 'econ');
% n_components = [];
% 
% X = rand(d, 5);
% 
% % PCA the incremental way:
% [U_new, S_new, mu_new, n_samples_seen] = incrementalPCA...
%    (X, U, S, mu, n_samples_seen, n_components);
% 
% % % PCA the standard way:
% [U_comparison, ~, ~] = svd([A X] - mean([A X],2), 'econ');
% sgn = sign(diag(U_new)) .* sign(diag(U_comparison));
% U_comparison = U_comparison * diag(sgn);
% 
% U_new
% U_comparison
% max(abs(U_new(:) - U_comparison(:)))
%or use the mean absolute unsigned error

%%
% EXAMPLE 2: 
%
% This function is designed so that the outputs can be used directly in the 
% the next call, so it can be used repeatedly, for example:
%
% n = 10;
% A = rand(5,n);
% mu = mean(A,2);
% [U,S,~] = svd(A - mu, 'econ');
% 
% new_data_X = rand(5, 4);
% [U, S, mu, n] = incrementalPCA(new_data_X, U, S, mu, n, [])
%
% newer_data_X = rand(5,6);
% [U, S, mu, n] = incrementalPCA(newer_data_X, U, S, mu, n, [])
% 
% ... and so on ... 
%
function [U_new, S_new, mu_new, n_samples_seen] = incrementalPCA(X, U, S, mu, ...
  n_samples_seen, n_components, energy_thresh)


n = n_samples_seen;

m = size(X,2);

muX = mean(X, 2);  % column average of new data

mu_new = n/(n+m)*mu + m/(n+m)*muX;  % update average

Xhat = [X-muX, sqrt(n*m/(n+m))*(muX-mu)];  % augment with mean correction

[U_Btild, R] = qr([U*S Xhat], 0);      % orthogonalize the augmented matrix

[Utild, S_new, ~] = svd(R, 'econ');  

U_new = U_Btild * Utild;

% only save n_components
if isempty(n_components) && exist('energy_thresh', 'var') && energy_thresh < 1
  energies = cumsum(diag(S_new)) / sum(diag(S_new));
  n_components = find(energies >= energy_thresh, 1);
elseif isempty(n_components)
  n_components = size(S_new,1);
end

U_new = U_new(:,1:n_components);
S_new = S_new(1:n_components, 1:n_components);

n_samples_seen = m + n;

end













































