clear all; clc; close all;

disp('Loading data');
addpath(genpath(pwd));
preprocessing; 

model_name = 'EST'; 
load_system(model_name);


set_param(model_name, 'InitFcn', '');
set_param(model_name, 'StopFcn', '');
set_param(model_name, 'PreLoadFcn', '');


try
    czas_symulacji = evalin('base', 'stopt');
    set_param(model_name, 'StopTime', num2str(czas_symulacji));
catch
    set_param(model_name, 'StopTime', '31536000');
end

volumes_m3 = 5:2.5:40;
num_tests = length(volumes_m3);
final_energies = zeros(num_tests, 1);

disp(' Optimalization ');
for k = 1:num_tests
 
    V_ads = volumes_m3(k);
    EStorageMax = V_ads * 220 * 3.6e6; 
    
    m_ads = 720 * V_ads;
    m_w_max = 0.35 * m_ads;
    m_w_min = 0.02 * m_ads;
    
    V_tank = 1.2 * V_ads;
    r_tank = (V_tank/(2*pi))^(1/3);
    A_tank = 6*pi*r_tank^2;
    m_tank = 7850 * A_tank * 0.005;
    
    C_s = m_ads*900 + m_w_min*4184 + m_tank*502;
    

    assignin('base', 'V_ads', V_ads);
    assignin('base', 'EStorageMax', EStorageMax);
    assignin('base', 'Max_Capacity_J', EStorageMax);
    assignin('base', 'm_ads', m_ads);
    assignin('base', 'm_w_max', m_w_max);
    assignin('base', 'm_w_min', m_w_min);
    assignin('base', 'A_tank', A_tank);
    assignin('base', 'C_s', C_s);
    assignin('base', 'm_eq', m_w_max);
    

    assignin('base', 'm_w_0', m_w_max);  
    assignin('base', 'EStorageInitial', 0); 
    
    fprintf('Volume test %4.1f m3 ... ', V_ads);
    
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

