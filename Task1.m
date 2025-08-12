%% M.A Trading Strategy for ABNB Stock
clear
clc

%% a.) Import data from the ABNB.csv file or ABNB.txt file
data = readtable('ABNB.csv', 'Delimiter', ',', 'DatetimeType', 'text');

% Convert date strings to datetime objects for proper sorting
data.Date = datetime(data.Date, 'InputFormat', 'dd/MM/yyyy');

% Make sure the data is sorted by date in ascending order
data = sortrows(data, 'Date');
dates = data.Date;

% Get closing prices
closingPrices = data.ClosePrice;

%% b. Implement the trading strategy

% Calculate the moving averages including the current day
ma9 = movmean(closingPrices, [8, 0]);
ma18 = movmean(closingPrices, [17, 0]);

% Variable Initialisation
initialBudget = 1500000;
budget = initialBudget;
portfolio = 0;            % Number of shares owned
sharesValue = 0;          % Value of shares in portfolio
buyDays = [];             % Number of days when buying happens
sellDays = [];            % Number of days when selling happens
profitLoss = zeros(size(closingPrices));  % Daily P/L
totalProfitLoss = 0;      % Sum profit/loss

% Previous day's crossover state between MA9 and MA18
initCrossoverState = NaN;

% Go through all days after the first 17 days
i = 19;
while i <= length(closingPrices)
    if ma9(i) > ma18(i)
        crossoverState = 1;  % Fast MA above Slow MA
    else
        crossoverState = -1; % Fast MA below Slow MA
    end
    
    % If this is the first day with valid MAs, set initCrossoverState
    if isnan(initCrossoverState)
        initCrossoverState = crossoverState;
    end
    
    % If 9MA crosses 18MA from below, Buy
    if crossoverState == 1 && initCrossoverState == -1
        if budget > 0
            % Calculate how many shares to buy (integer number only)
            sharesToBuy = floor(budget / closingPrices(i));
            
            % Update portfolio and budget
            portfolio = portfolio + sharesToBuy;
            cost = sharesToBuy * closingPrices(i);
            budget = budget - cost;
            
            % Record buy day
            buyDays = [buyDays; i];
            
            % Calculate daily profit/loss (buying has no immediate P&L)
            profitLoss(i) = 0;
        end
    % If 9MA crosses 18MA from above, Sell
    elseif crossoverState == -1 && initCrossoverState == 1
        if portfolio > 0
            % Sell all shares
            earned = portfolio * closingPrices(i);
            
            % Calculate profit/loss from this sale
            previousValue = portfolio * closingPrices(buyDays(end));
            profitLoss(i) = earned - previousValue;
            
            % Update portfolio and budget
            budget = budget + earned;
            portfolio = 0;
            
            % Record sell day
            sellDays = [sellDays; i];
        end
    end
    
    % Update previous crossover state for next iteration
    initCrossoverState = crossoverState;
    
    % Calculate the portfolio value for each day
    sharesValue = portfolio * closingPrices(i);
    
    % Update total P/L
    totalProfitLoss = totalProfitLoss + profitLoss(i);
    
    i = i + 1;
end

%% c. Output the results

% Calculate final portfolio value
finalValue = budget + (portfolio * closingPrices(end));
overallProfitLoss = finalValue - initialBudget;

% Create a trade log
transactionDays = [];
transactionDates = {};
transactionPrices = [];
transactionShares = [];
transactionAmounts = [];
transactionTypes = {};

% Process buy days
i = 1;
while i <= length(buyDays)
    day = buyDays(i);
    
    % Calculate shares bought and amount spent
    if i < length(buyDays)
        sharesBought = floor(budget / closingPrices(day));
        amountSpent = sharesBought * closingPrices(day);
    else
        % For the last buy, if we haven't sold yet
        if portfolio > 0
            sharesBought = portfolio;
            amountSpent = sharesBought * closingPrices(day);
        else
            sharesBought = floor(budget / closingPrices(day));
            amountSpent = sharesBought * closingPrices(day);
        end
    end
    
    % Add to transaction data
    transactionDays = [transactionDays; day];
    transactionDates{end+1} = datestr(dates(day), 'yyyy-mm-dd');
    transactionPrices = [transactionPrices; closingPrices(day)];
    transactionShares = [transactionShares; sharesBought];
    transactionAmounts = [transactionAmounts; amountSpent];
    transactionTypes{end+1} = 'Buy';
    
    i = i + 1;
end

% Process sell days
i = 1;
while i <= length(sellDays)
    day = sellDays(i);
    
    % Find the corresponding buy day
    buyDay = buyDays(find(buyDays < day, 1, 'last'));
    sharesSold = floor(budget / closingPrices(buyDay));
    profitLossAmount = profitLoss(day);
    
    % Add to transaction data
    transactionDays = [transactionDays; day];
    transactionDates{end+1} = datestr(dates(day), 'yyyy-mm-dd');
    transactionPrices = [transactionPrices; closingPrices(day)];
    transactionShares = [transactionShares; sharesSold];
    transactionAmounts = [transactionAmounts; profitLossAmount];
    transactionTypes{end+1} = 'Sell';
    
    i = i + 1;
end

% Sort transactions by day
[sortedDays, sortIdx] = sort(transactionDays);
sortedDates = transactionDates(sortIdx);
sortedPrices = transactionPrices(sortIdx);
sortedShares = transactionShares(sortIdx);
sortedAmounts = transactionAmounts(sortIdx);
sortedTypes = transactionTypes(sortIdx);

% Print overall results
fprintf('\nOverall Results:\n\n');
fprintf('Initial Budget: £%.2f\n', initialBudget);
fprintf('Final Budget: £%.2f\n', budget);
fprintf('Remaining Portfolio: %d shares at £%.2f = £%.2f\n', portfolio, closingPrices(end), portfolio * closingPrices(end));
fprintf('Total Profit/Loss: £%.2f (%.2f%%)\n', overallProfitLoss, (overallProfitLoss/initialBudget)*100);

% Display consolidated transaction table
fprintf('\nTrade Log:\n');
fprintf('---------------------------------------------------------------------------------\n');
fprintf('Day | Date       | Day Type | Price     | Shares    | (£)Amount        \n');
fprintf('---------------------------------------------------------------------------------\n');

for i = 1:length(sortedDays)
    day = sortedDays(i);
    date = sortedDates{i};
    dayType = sortedTypes{i};
    price = sortedPrices(i);
    shares = sortedShares(i);
    amount = sortedAmounts(i);
    
    % Format amount based on transaction type
    if strcmp(dayType, 'Buy')
        amountStr = sprintf('£%12.2f Spent', amount);
    else
        if amount >= 0
            amountStr = sprintf('£%12.2f Profit', amount);
        else
            amountStr = sprintf('£%12.2f Loss', -amount);
        end
    end
    
    fprintf('%3d | %s | %-8s | £%8.2f | %9d | %s\n', ...
        day, date, dayType, price, shares, amountStr);
end