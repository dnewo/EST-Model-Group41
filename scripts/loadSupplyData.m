function Supply = loadSupplyData(supplyFile, timeUnit, supplyUnit)
%   LOADSUPPLYDATA  Load the supply data from the specified file.
%   Supply = LOADSUPPLYDATA(supplyFile, supplyUnit) loads the
%   data in supplyFile with the time in timeUnit and the power in
%   supplyUnit, returning a time series.

    global unit;
    supply = importdata(supplyFile, ',');
    
    %%Program for finding the sums across a number of rows written with
    %%assistance from GOOGLE GEMINI. Work in progress.

    %{
    rowsToSum = 672; % Sum across one week, which is equivalent to 672 rows in the file. 
    
    % Extracting the time and power data from the supply file. 
    timeColumn = supply.data(:,1);
    powerColumn = supply.data(:,2);
    
    % Cropping the data to ensure we have a multiple of rowsToSum rows. 
    numRows = floor(length(powerColumn)/rowsToSum) * rowsToSum;
    timeColumn = timeColumn(1:numRows);
    powerColumn = powerColumn(1:numRows);
    
    % 
    groupedPower = sum(reshape(powerColumn,rowsToSum,[]));
    
    tempTime = reshape(timeColumn,rowsToSum,[]);
    groupedTime = tempTime(rowsToSum,:);
    
    groupedTime = groupedTime(:);
    groupedPower = groupedPower(:);
    
    size(groupedPower)
    size(groupedTime)
    Supply = timeseries(unit(supplyUnit)*groupedPower, unit(timeUnit)*groupedTime);
   
    size(supply.data(:,2))
    size(supply.data(:,1))
    %}
   
    Supply = timeseries(unit(supplyUnit)*supply.data(:,2),unit(timeUnit)*supply.data(:,1));
end