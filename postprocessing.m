% Post-processing script for the EST Simulink model. This script is invoked
% after the Simulink model is finished running (stopFcn callback function).C

close all;
figure;

%% Supply and demand
subplot(2,2,1);
plot(tout/unit("day"), PSupply/unit("W"));
hold on;
plot(tout/unit("day"), PDemand/unit("W"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Supply and demand');
xlabel('Time [day]');
ylabel('Power [W]');
legend("Supply","Demand");

%% Stored energy
subplot(2,2,2);
plot(tout/unit("day"), EStorage/unit("J"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Storage');
xlabel('Time [day]');
ylabel('Energy [J]');

%% Energy losses
subplot(2,2,3);
plot(tout/unit("day"), D/unit("W"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Losses');
xlabel('Time [day]');
ylabel('Dissipation rate [W]');

%% Load balancing
subplot(2,2,4);
plot(tout/unit("day"), PSell/unit("W"));
hold on;
plot(tout/unit("day"), PBuy/unit("W"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Load balancing');
xlabel('Time [day]');
ylabel('Power [W]');
legend("Sell","Buy");

%% Pie charts

% integrate the power signals in time
EfromSupplyTransport = trapz(tout, PfromSupplyTransport);
EtoDemandTransport   = trapz(tout, PtoDemandTransport);
ESell                = trapz(tout, PSell);
EBuy                 = trapz(tout, PBuy);
EtoInjection         = trapz(tout, PtoInjection);
EfromExtraction      = trapz(tout, PfromExtraction);
EStorageDissipation  = trapz(tout, DStorage);
EDirect              = EfromSupplyTransport - ESell - EtoInjection;
ESurplus             = EtoInjection-EfromExtraction-EStorageDissipation;

figure;
tiles = tiledlayout(1,2);

ax = nexttile;
pie(ax, [EDirect, EtoInjection, ESell]/EfromSupplyTransport);
lgd = legend({"Direct to demand", "To storage", "Sold"});
lgd.Layout.Tile = "south";
title(sprintf("Received energy %3.2e [J]", EfromSupplyTransport/unit('J')));

ax = nexttile;
pie(ax, [EDirect, EfromExtraction, EBuy]/EtoDemandTransport);
lgd = legend({"Direct from supply", "From storage", "Bought"});
lgd.Layout.Tile = "south";
title(sprintf("Delivered energy %3.2e [J]", EtoDemandTransport/unit('J')));


%% EFFICIENCIES

% Efficiency of the storage - energy sent into injection that is recovered during extraction (losses by storage)
eta_storage = EfromExtraction / EtoInjection;

% Fraction of injected storage energy that is lost inside the storage (double checks previous equation but by losses)
storage_loss_fraction = EStorageDissipation / EtoInjection;

% Energy delivered by the system excluding bought energy
Edelivered_system = EDirect + EfromExtraction;

% Overall system efficiency excluding bought energy
eta_system_no_buy = Edelivered_system / EfromSupplyTransport;

% Fraction of total demand-side energy covered by the system itself (E delivered by storage / E demand)
demand_covered_by_system = Edelivered_system / EtoDemandTransport;

% Fraction of total demand-side energy supplied by storage extraction
storage_contribution = EfromExtraction / EtoDemandTransport;

% Fraction of total demand-side energy that had to be bought externally
buy_fraction = EBuy / EtoDemandTransport;

% Fraction of supply energy that was used directly or sent to storage instead of sold
solar_self_use = (EDirect + EtoInjection) / EfromSupplyTransport;

fprintf('\n--- System performance results ---\n');
fprintf('Storage efficiency = %.2f %%\n', eta_storage*100);
fprintf('Storage loss fraction = %.2f %%\n', storage_loss_fraction*100);
fprintf('System efficiency excluding bought energy = %.2f %%\n', eta_system_no_buy*100);
fprintf('Demand covered by own system = %.2f %%\n', demand_covered_by_system*100);
fprintf('Storage contribution to demand = %.2f %%\n', storage_contribution*100);
fprintf('Bought energy fraction = %.2f %%\n', buy_fraction*100);
fprintf('Solar self-use fraction = %.2f %%\n', solar_self_use*100);