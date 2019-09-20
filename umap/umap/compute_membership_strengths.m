function [rows, cols, vals] = compute_membership_strengths(knn_indices, knn_dists, sigmas, rhos)
%COMPUTE_MEMBERSHIP_STRENGTHS Construct the membership strength data for
% the 1-skeleton of each local fuzzy simplicial set -- this is formed as a
% sparse matrix where each row is a local fuzzy simplicial set, with a
% membership strength for the 1-simplex to each other data point.
%
% [rows, cols, vals] = COMPUTE_MEMBERSHIP_STRENGTHS(knn_indices, knn_dists, sigmas, rhos)
%
% Parameters
% ----------
% knn_indices: array of size (n_samples, n_neighbors)
%     The indices on the "n_neighbors" closest points in the dataset.
% 
% knn_dists: array of size (n_samples, n_neighbors)
%     The distances to the "n_neighbors" closest points in the dataset.
% 
% sigmas: array of size (n_samples, 1)
%     The normalization factor derived from the metric tensor approximation.
% 
% rhos: array of size (n_samples, 1)
%     The local connectivity adjustment.
% 
% Returns
% -------
% rows: array of size (n_samples*n_neighbors, 1)
%     Row data for the resulting sparse matrix.
% 
% cols: array of size (n_samples*n_neighbors, 1)
%     Column data for the resulting sparse matrix.
% 
% vals: array of size (n_samples*n_neighbors, 1)
%     Entries for the resulting sparse matrix.

    [n_samples, n_neighbors] = size(knn_indices);
    
    knn_fail = knn_indices == -1;
    itself = knn_indices == repmat((1:n_samples)', 1, n_neighbors);

    rows = repmat((1:n_samples)', 1, n_neighbors);
    rows(knn_fail) = NaN;
    rows = rows';
    rows = rows(:);
    
    cols = knn_indices;
    cols(knn_fail) = NaN;
    cols = cols';
    cols = cols(:);
    
    d = knn_dists - rhos;
        
    vals = exp(-max(0, d./repmat(sigmas, [1 n_neighbors])));
    vals(itself) = 0;
    vals(knn_fail) = NaN;
    vals = vals';
    vals = vals(:);
