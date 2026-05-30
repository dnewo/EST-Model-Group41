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


%% Efficiencies and performance indicators

% Total energy produced/received from the solar supply data, main input energy before selling, buying, battery losses, etc.
ESolarSupply = trapz(tout, PSupply);

% Energy delivered to the house by the system itself, excluding externally bought energy (energy sent directly +
% recovered energy from storage)
EDeliveredBySystem = EDirect + EfromExtraction;


% MOST IMPORTANT: fraction of solar supply energy that actually reaches the house as useful heat, including all storage
% and transport losses
eta_solar_to_house = EDeliveredBySystem / ESolarSupply;

% Storage-only efficiency:
% Fraction of energy sent into injection that is later recovered during extraction, EXCLUDING battery/cable losses
eta_storage_only = EfromExtraction / EtoInjection;

% Demand coverage by own system:fraction of total house demand covered by direct solar + storage
demand_covered_by_system = EDeliveredBySystem / EtoDemandTransport;

% Bought energy fraction:
% Fraction of total house demand that still had to be bought externally
buy_fraction = EBuy / EtoDemandTransport;

% Storage contribution to demand: fraction of total house demand covered by storage extraction only
storage_contribution = EfromExtraction / EtoDemandTransport;

% Solar self-use fraction: fraction of solar supply that is used directly or sent to storage instead of sold
solar_self_use = 1 - ESell / ESolarSupply;

fprintf('\n--- System performance results ---\n');
fprintf('Solar-to-house efficiency = %.2f %%\n', eta_solar_to_house*100);
fprintf('Storage-only efficiency = %.2f %%\n', eta_storage_only*100);
fprintf('Demand covered by own system = %.2f %%\n', demand_covered_by_system*100);
fprintf('Bought energy fraction = %.2f %%\n', buy_fraction*100);
fprintf('Storage contribution to demand = %.2f %%\n', storage_contribution*100);
fprintf('Solar self-use fraction = %.2f %%\n', solar_self_use*100);

%% Supply transport loss check (checks newly implemented transport to storage losses)

% Energy dissipated in supply-side transport:
% includes cable heating, battery losses and heater losses
ESupplyTransportLoss = trapz(tout, DSupplyTransport);

% Fraction of total solar supply lost in supply-side transport
supply_transport_loss_fraction = ESupplyTransportLoss / ESolarSupply;

fprintf('Supply transport loss fraction = %.2f %%\n', ...
    supply_transport_loss_fraction*100);

%% Check for heat loss by tank (commented out for now but might be useful for report)
%{
% Net effect of the heat exchange by losses
ETankExchangeSigned = trapz(tout, DStorage)

%Heat lost from tank to ambient
ETankLossOut = trapz(tout, max(DStorage, 0));

%Heat gained from tank to ambient
ETankGainIn = -trapz(tout, min(DStorage, 0));

fprintf('Signed tank heat exchange = %.3e J\n', ETankExchangeSigned);
fprintf('Heat lost from tank to ambient = %.3e J\n', ETankLossOut);
fprintf('Heat gained from ambient to tank = %.3e J\n', ETankGainIn);
fprintf('Net tank loss / injection = %.2f %%\n', ETankExchangeSigned/EtoInjection*100);
fprintf('Gross heat lost / injection = %.2f %%\n', ETankLossOut/EtoInjection*100);
fprintf('Heat gained / injection = %.2f %%\n', ETankGainIn/EtoInjection*100); 
%}