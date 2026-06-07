clear all; clc; close all;

% SETUP

disp('INITIALIZING DATA ');
addpath(genpath(pwd));
preprocessing; 

model_name = 'EST'; 
load_system(model_name);

set_param(model_name, 'InitFcn', '');
set_param(model_name, 'StopFcn', '');
set_param(model_name, 'PreLoadFcn', '');


try
    sim_time = evalin('base', 'stopt');
    set_param(model_name, 'StopTime', num2str(sim_time));
catch
    set_param(model_name, 'StopTime', '31536000');
end

% OPTIMIZATION PARAMETERS
volumes_m3 = 0.5:0.5:20;
num_tests = length(volumes_m3);
final_energies = zeros(num_tests, 1);

disp('STARTING OPTIMIZATION');
for k = 1:num_tests
    

    V_ads = volumes_m3(k);
    
    Max_Capacity_J = V_ads * 220 * 3.6e6; 
    m_ads_val = 720 * V_ads;
    m_w_max_val = 0.35 * m_ads_val;
    

    assignin('base', 'Max_Capacity_J', Max_Capacity_J);
    assignin('base', 'EStorageMax', Max_Capacity_J);
    assignin('base', 'm_ads', m_ads_val);
    assignin('base', 'm_w_max', m_w_max_val);
    
 
    assignin('base', 'm_w_0', m_w_max_val);
    assignin('base', 'EStorageInitial', 0);
    
    fprintf('Testing volume: %4.1f m3 ... ', V_ads);
    
 
    simOut = sim(model_name, 'SimulationMode', 'normal');

    try
        pb_obj = simOut.get('PBuy');
    catch
        pb_obj = evalin('base', 'PBuy');
    end
    
    if isa(pb_obj, 'timeseries')
        t_arr = pb_obj.Time;
        pb_arr = pb_obj.Data;
    else
        pb_arr = pb_obj;
        try t_arr = simOut.tout; catch, t_arr = evalin('base', 'tout'); end
    end
    

    val_J = trapz(t_arr, pb_arr);
    

    final_energies(k) = val_J / 3.6e6;
    fprintf('Bought: %6.3f kWh\n', final_energies(k));
end

% PLOT

disp('Generating plot...');
figure('Color', 'w');
plot(volumes_m3, final_energies, '-ob', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
grid on;

ax = gca;
ax.YAxis.Exponent = 0; 
set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', 'GridAlpha', 0.3);

xlabel('Storage Volume [m^3]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Bought Energy [kWh]', 'FontSize', 12, 'FontWeight', 'bold');
title('Optimization Results', 'FontSize', 14);

disp(' DONE ');