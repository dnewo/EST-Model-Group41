clear all; clc; close all;

% 1. Data
disp('Ladowanie oryginalnych danych (preprocessing)...');
preprocessing;

% 2. Setup 
model_name = 'EST';
energy_density = 220;
conversion_factor = 3.6e6;

volumes_m3 = 5:2.5:40;
num_tests = length(volumes_m3);
final_energies = zeros(num_tests, 1);

disp('Rozpoczynam optymalizacje...');
load_system(model_name);


set_param(model_name, 'StopFcn', '');
set_param(model_name, 'InitFcn', '');
set_param(model_name, 'PreLoadFcn', '');

% Loop
for k = 1:num_tests
    Max_Capacity_J = volumes_m3(k) * energy_density * conversion_factor;
    assignin('base', 'Max_Capacity_J', Max_Capacity_J);
    

    V_ads = Max_Capacity_J / (220 * 3.6e6);
    assignin('base', 'm_ads', 720 * V_ads);
    assignin('base', 'm_w_max', 0.35 * 720 * V_ads);
    
    fprintf('Running %.1f m3... ', volumes_m3(k));
    
    % Run model
    simOut = sim(model_name, 'SimulationMode', 'normal');
    
    % Extract data safely 
  
    try
        if ismember('Total_Bought', simOut.who)
            raw_data = simOut.get('Total_Bought');
        else
            raw_data = evalin('base', 'Total_Bought');
        end
        
        if isa(raw_data, 'timeseries')
            val = raw_data.Data(end);
        elseif isa(raw_data, 'Simulink.SimulationData.Dataset')
            val = raw_data{1}.Values.Data(end);
        elseif isnumeric(raw_data) && ~isempty(raw_data)
            val = raw_data(end);
        elseif isstruct(raw_data) && isfield(raw_data, 'signals')
            val = raw_data.signals.values(end);
        end
    catch
        fprintf('[Brak danych] ');
    end
    
    % Save to array
    final_energies(k) = val;
    
    fprintf('Done. (Kupiono: %.2f kWh)\n', val / conversion_factor);
end

% 3. Plot
figure('Color', 'w');
plot(volumes_m3, final_energies / conversion_factor, '-ob', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
grid on;

set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', 'GridAlpha', 0.3);

xlabel('Storage Volume [m^3]', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
ylabel('Bought Energy [kWh]', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
title('Optimization Results', 'FontSize', 14, 'Color', 'k');

hold on;

if all(final_energies == 0)
    optimum_y = 0;
else
    optimum_y = interp1(volumes_m3, final_energies / conversion_factor, 15.78, 'linear', 'extrap');
end
plot(15.78, optimum_y, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r');

lgd = legend('Bought Energy', 'Calculated Optimum (15.78 m^3)');
set(lgd, 'TextColor', 'k', 'Color', 'w');