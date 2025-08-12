%% Decision Tree Analysis
clear
clc
% Define the dataset
data = {
    'Up',    'Down',    'Low',  'Impartial', 'Buy';
    'Down',  'Stable',  'High', 'Negative',  'Sell';
    'Up',    'Stable',  'High', 'Positive',  'Buy';
    'Down',  'Stable',  'Low',  'Positive',  'Buy';
    'Stable', 'Stable', 'Low',  'Negative',  'Buy';
    'Down',  'Down',    'Low',  'Impartial', 'Sell';
    'Stable', 'Up',     'High', 'Negative',  'Sell';
    'Up',    'Up',      'Low',  'Negative',  'Buy';
    'Down',  'Down',    'High', 'Positive',  'Sell'
};

% Feature names
featureNames = {'StockPrice', 'Market', 'Volatility', 'News', 'Decision'};

% Make a table to handle data better
dataTable = cell2table(data, 'VariableNames', featureNames);

% Display dataset table
fprintf('\nDataset:\n');
fprintf('---------------------------------------------------------------\n');
fprintf('| %-10s | %-10s | %-10s | %-10s | %-10s |\n', featureNames{:});
fprintf('---------------------------------------------------------------\n');

% Using while loop to display table rows
i = 1;
while i <= height(dataTable)
    fprintf('| %-10s | %-10s | %-10s | %-10s | %-10s |\n', ...
        char(dataTable.StockPrice(i)), ...
        char(dataTable.Market(i)), ...
        char(dataTable.Volatility(i)), ...
        char(dataTable.News(i)), ...
        char(dataTable.Decision(i)));
    i = i + 1;
end

% Convert to categorical for MATLAB functions
dataTable.StockPrice = categorical(dataTable.StockPrice);
dataTable.Market = categorical(dataTable.Market);
dataTable.Volatility = categorical(dataTable.Volatility);
dataTable.News = categorical(dataTable.News);
dataTable.Decision = categorical(dataTable.Decision);

%% a.) Make decision tree by calculating entropy and information gain

% Find entropy of the entire dataset
decisions = data(:, 5);
totalSamples = size(data, 1);
numBuy = sum(strcmp(decisions, 'Buy'));
numSell = sum(strcmp(decisions, 'Sell'));

% Get probabilities
pBuy = numBuy / totalSamples;
pSell = numSell / totalSamples;

% Calculate entropy
entropyS = -pBuy * log2(pBuy) - pSell * log2(pSell);

fprintf('\nData Set Entropy\n');
fprintf('Total samples: %d', totalSamples);
fprintf('\nBuy: %d, Sell: %d', numBuy, numSell);
fprintf('\nP(Buy) = %.4f, P(Sell) = %.4f', pBuy, pSell);
fprintf('\nEntropy(S) = -(%.4f * log2(%.4f) + %.4f * log2(%.4f)) = %.4f\n', pBuy, pBuy, pSell, pSell, entropyS);

% Calculate Information Gain for each attribute
fprintf('\nInformation Gain Calculation\n');

% Attributes to evaluate
attributeIndices = 1:4;
attributeInfoGains = zeros(1, 4);

% Using while loop to iterate through attributes
i = 1;
while i <= length(attributeIndices)
    attribute = featureNames{i};
    fprintf('\nCalculating Information Gain for %s:\n', attribute);
    
    % Get unique values for this attribute
    attrData = data(:, i);
    uniqueVals = unique(attrData);
    
    % Calculate weighted entropy sum
    weightedEntropySum = 0;
    
    % Calculate entropy for each attribute value using while loop
    j = 1;
    while j <= length(uniqueVals)
        value = uniqueVals{j};
        % Get subset where attribute = value
        idx = strcmp(attrData, value);
        subset = decisions(idx);
        subsetSize = sum(idx);
        
        % Count values in subset
        subBuy = sum(strcmp(subset, 'Buy'));
        subSell = sum(strcmp(subset, 'Sell'));
        
        % Calculate subset entropy
        if subBuy == 0 || subSell == 0
            subEntropy = 0; % Pure subset
        else
            subPBuy = subBuy / subsetSize;
            subPSell = subSell / subsetSize;
            subEntropy = -subPBuy * log2(subPBuy) - subPSell * log2(subPSell);
        end
        
        fprintf('  %s = %s: Subset size = %d (Buy: %d, Sell: %d)\n', attribute, value, subsetSize, subBuy, subSell);
        if subBuy > 0 && subSell > 0
            fprintf('  Entropy(%s=%s) = -(%.4f * log2(%.4f) + %.4f * log2(%.4f)) = %.4f\n', ...
                attribute, value, subPBuy, subPBuy, subPSell, subPSell, subEntropy);
        else
            fprintf('  Entropy(%s=%s) = 0 (pure subset)\n', attribute, value);
        end
        
        % Add weighted entropy to sum
        weightedEntropySum = weightedEntropySum + (subsetSize / totalSamples) * subEntropy;
        
        j = j + 1;
    end
    
    % Calculate information gain
    infoGain = entropyS - weightedEntropySum;
    attributeInfoGains(i) = infoGain;
    
    fprintf('  Weighted Entropy Sum = %.4f\n', weightedEntropySum);
    fprintf('  Information Gain(%s) = %.4f - %.4f = %.4f\n', attribute, entropyS, weightedEntropySum, infoGain);
    
    i = i + 1;
end

% Get the attribute with the highest information gain
[maxIG, bestAttrIdx] = max(attributeInfoGains);
fprintf('\nHighest Information Gain is %s (%.4f)\n', featureNames{bestAttrIdx}, maxIG);

% Print the final decision tree structure based on calculations
fprintf('\n3. Decision Tree Structure\n');
fprintf('Root: %s (IG = %.4f)\n\n', featureNames{bestAttrIdx}, maxIG);
fprintf('  If %s = "Up" then Buy\n', featureNames{bestAttrIdx});
fprintf('  If %s = "Down":\n', featureNames{bestAttrIdx});
fprintf('  If Market = "Stable":\n');
fprintf('  If Volatility = "High" then Sell\n');
fprintf('  If Volatility = "Low" then Buy\n');
fprintf('  If Market = "Down" then Sell\n');
fprintf('  If %s = "Stable":\n', featureNames{bestAttrIdx});
fprintf('  If Market = "Stable" then Buy\n');
fprintf('  If Market = "Up" then Sell\n');

%% b.) Using fitctree command in MATLAB to generate Tree1
fprintf('\nMATLAB fitctree Decision Tree\n');

% Prepare data for MATLAB's tree functions
X = dataTable(:, 1:4);
Y = dataTable.Decision;

% Create decision tree model (Tree1)
tree1 = fitctree(X, Y, 'MinParentSize', 1, 'Prune', 'off');

% Calculate resubstitution error for tree1
resubErr1 = resubLoss(tree1);
fprintf('\nResubstitution error for tree1: %.4f\n', resubErr1);

%% c.) Finding optimal MinParentSize for Tree2
fprintf('\nMaximum MinParentSize Value\n');

% Initialize variables for binary search
minValue = 1;  % Minimum possible value
maxValue = height(dataTable);  % Maximum possible value
optimalMinParentSize = 1;  % Default minimum value

fprintf('Find maximum MinParentSize value that yields zero classification loss:\n\n');

% Binary search to find maximum MinParentSize with zero loss
while minValue <= maxValue
    midValue = floor((minValue + maxValue) / 2);
    
    % Create a tree with the current MinParentSize
    treeMid = fitctree(X, Y, 'MinParentSize', midValue);
    
    % Calculate classification loss
    predictions = predict(treeMid, X);
    loss = sum(predictions ~= Y) / height(Y);
    
    fprintf('Testing MinParentSize = %d: Classification Loss = %.4f\n', midValue, loss);
    
    if loss == 0
        % If zero loss, try a larger value
        optimalMinParentSize = midValue;
        minValue = midValue + 1;
    else
        % If non-zero loss, try a smaller value
        maxValue = midValue - 1;
    end
end

fprintf('\nMaximum MinParentSize with zero classification loss: %d\n', optimalMinParentSize);

% Create the optimal tree (tree2) with the found MinParentSize
tree2 = fitctree(X, Y, 'MinParentSize', optimalMinParentSize);

% Calculate resubstitution error for tree2
resubErr2 = resubLoss(tree2);
fprintf('\nResubstitution error for tree2: %.4f\n', resubErr2);

% Plot tree1
figure('Name', 'Tree1', 'NumberTitle', 'off');
view(tree1, 'Mode', 'graph');
title('Tree1');

% Plot tree2
figure('Name', 'Tree2', 'NumberTitle', 'off');
view(tree2, 'Mode', 'graph');
title('Tree2');

% Summary
fprintf('\nSummary\n');
fprintf('1. Manual Decision Tree Analysis\n');
fprintf('   * Dataset entropy: %.4f\n', entropyS);
fprintf('   * Best attribute: %s (Information Gain = %.4f)\n', featureNames{bestAttrIdx}, maxIG);
fprintf('\n2. Tree1: Basic Decision Tree\n');
fprintf('   * Resubstitution error: %.4f\n', resubErr1);
fprintf('\n3. Tree2: Optimal MinParentSize Tree\n');
fprintf('   * Maximum MinParentSize with zero classification loss: %d\n', optimalMinParentSize);
fprintf('   * Resubstitution error: %.4f\n', resubErr2);