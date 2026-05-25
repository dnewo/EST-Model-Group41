function Supply = loadSupplyData(supplyFile, timeUnit, supplyUnit)
% LOADSUPPLYDATA Load the supply data from the specified file.
% Supply = LOADSUPPLYDATA(supplyFile, timeUnit, supplyUnit) loads the data in supplyFile with the time in timeUnit and the power in supplyUnit, returning a time series
% By default, this function uses the original/raw supply data
% To use weekly averaged supply data instead, activate the weekly section below and comment out the raw supply line at the bottom

    global unit;
    supply = importdata(supplyFile, ',');

    %% WEEKLY AVERAGED SUPPLY DATA - (assistance from ChatGPT)
    %% Groups average weekly power input, can represent smoothing of battery/weekly injection
    %% To activate this section:
    %% 1. Remove the %{ and %} around the section.
    %% 2. Comment out the raw Supply line at the bottom of the function.

    %{
    rowsPerWeek = 672; % One week for 15 min data: 7 days * 24 hours * 4 samples/hour.

    % Extract time and power columns.
    timeColumn = supply.data(:,1);
    powerColumn = supply.data(:,2);

    % Crop data so the number of rows is a whole number of weeks.
    numRows = floor(length(powerColumn)/rowsPerWeek) * rowsPerWeek;
    timeColumn = timeColumn(1:numRows);
    powerColumn = powerColumn(1:numRows);

    % Reshape data into weekly groups.
    powerWeeklyMatrix = reshape(powerColumn, rowsPerWeek, []);
    timeWeeklyMatrix = reshape(timeColumn, rowsPerWeek, []);

    % Use average power during each week, not the sum of power values.
    weeklyPower = mean(powerWeeklyMatrix, 1);

    % Use the final time of each week as the time point.
    weeklyTime = timeWeeklyMatrix(end, :);

    % Convert weekly values to column vectors.
    weeklyPower = weeklyPower(:);
    weeklyTime = weeklyTime(:);

    % Create weekly averaged time series.
    Supply = timeseries(unit(supplyUnit)*weeklyPower, ...
                        unit(timeUnit)*weeklyTime);

    % Keep the weekly supply value constant between weekly data points.
    Supply = setinterpmethod(Supply, 'zoh');

    return
    %}

    %% ORIGINAL/RAW SUPPLY DATA
    % This uses every data point from the original supply file.
    Supply = timeseries(unit(supplyUnit)*supply.data(:,2), ...
                        unit(timeUnit)*supply.data(:,1));
end