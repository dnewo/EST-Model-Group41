% Pre-processing script for the EST Simulink model. This script is invoked
% before the Simulink model starts running (initFcn callback function).

%% Load the supply and demand data

timeUnit   = 's';

supplyFile = "Team41_supplyData.csv";
supplyUnit = "kW";

% load the supply data
Supply = loadSupplyData(supplyFile, timeUnit, supplyUnit);

demandFile = "Team41_demandData.csv";
demandUnit = "kW";

% load the demand data
Demand = loadDemandData(demandFile, timeUnit, demandUnit);

%% Simulation settings

deltat = 5*unit("min");
stopt  = min([Supply.Timeinfo.End, Demand.Timeinfo.End]);

%% SYSTEM PARAMETERS

%% Transport from Supply

% Battery and heater assumptions
efficiencyBattery = 0.90;   
efficiencyHeater  = 1.00;  

% Cable design assumptions
L_cable = 20*unit("m");     % cable length from battery/PV system to heater
V_system = 400;             % assumed DC voltage in V

% Copper cable properties
rho_copper = 1.72e-8;        % copper resistivity (at ~20 deg C) at Ohm m
A_cable = 6e-6*unit("m2");   % 6mm^2 cross-section

% Resistance per metre and total cable resistance
Rprime_cable = rho_copper/A_cable;          
R_cable = L_cable*Rprime_cable;               


%% Injection and Storage System
%* indicates constant paremeters that can be changed, while the others parameters are rooted in equations based on these.
% at the moment we are using silica gel as the sorption material, which reacts with water. 

aInjection = 0; % Overall dissipation coefficient. This is ignored at the moment. 

%overall and initial conditions
EStorageMax     = 7000*unit("kWh");             % *Maximum energy
EStorageMin     = 0.0*unit("kWh");              % Minimum energy
EStorageInitial = 2.0*unit("kWh");              % Initial energy


T_ambient = (8+273.15)*unit("K");            % *expected ambient temperature
T_w = (50+273.15)*unit("K");                    % *average temperature of water in supply and return flows
T_s_0 = T_ambient;                              % *initial sorbent temperature.

%tank constants
f_space = 1.2;                                  % *extra space factor for vapour flow, heat exchanger components, and packing imperfections
t_wall = 0.005*unit("m");                       % *tank wall thickness
rho_tank = 7850*unit("kg")/unit("m3");          % *density of tank wall material (steel in this case)
c_tank = 502*unit("J")/(unit("kg")*unit("K"));  % *estimated specific heat capacity of steel 304 that forms the tank.

%thermal conductivities of reactor
k_steel = 16.3;                                 % W/(m K), thermal conductivity of stainless steel 304
h_inside = 10;                                  % W/(m^2 K), rough internal effective value
h_outside = 5;                                  % W/(m^2 K), natural convection to basement air                                   

U_tank = 1 / (1/h_inside + t_wall/k_steel + 1/h_outside);

%sorption constants
rho_bulk = 720*unit("kg")/unit("m3");           % *bulk density of sorption material.
q_ads = 220*unit("kWh")/unit("m3");             % *storage density of sorption material. 
X_max = 0.35;                                   % *maximum water loading of sorption material.      
X_min = 0.02;                                   % *minimum water content from loss on drying of sorption material.
c_w = 4184*unit("J")/(unit("kg")*unit("K"));    % *specific heat capacity of water.
c_ads = 900*unit("J")/(unit("kg")*unit("K"));   % *estimated specific heat capacity of sorption material.
E = 4.09e4*unit("J")/unit("mol");               % *sorption material activation energy.
R = 8.314*unit("J")/(unit("mol")*unit("K"));    % universal gas constant.
D_0 = 2.54e-4*unit("m2")/unit("s");             % *diffusivity pre-exponential factor for sorption material. 
d_p = 4e-3*unit("m");                           % *sorption material bead diameter
deltaH = 2.38E6*unit("J")/unit("kg");           % *adsorption/desorption enthalpy for material. 

%calculated constants
V_ads = EStorageMax/q_ads;                      % volume of silica gel.

V_tank = f_space*V_ads;                         % overall volume of tank. 
r_tank = (V_tank/(2*pi))^(1/3);                 % radius of the tank
A_tank = 6*pi*r_tank^2;                         % closed cylindrical tank surface area.
m_tank = rho_tank*A_tank*t_wall;                % mass of the tank itself

m_ads = rho_bulk*V_ads;                         % mass of adsorpents in the storage tank. 
m_w_max = X_max*m_ads;                          % maximum mass of water stored in sorption     
m_w_min = X_min*m_ads;                          % minimum mass of water stored in sorption
m_eq = m_w_max;                                 % amount of water in the adsorbent in undisturbed state.

C_s = m_ads*c_ads + m_w_min*c_w + m_tank*c_tank; % dry initial effective heat capacity of reactor system.

k_0 = (15*D_0)/(d_p/2)^2;                       % base adsorption/desorption rate constant. 

m_w_0 = m_w_min;                                 %*initial mass of water stored in sorption

% extraction system
aExtraction = 0.1; % Dissipation coefficient

%% Transport to demand - heat exchanger (NOT YET IMPLEMENTED)
% transport to demand
aDemandTransport = 0.01; % Dissipation coefficient

% IMPLEMENT LATER: Heat exchanger assumptions
%{
U_exchanger = 300;      % in W/(m^2 K) : overall heat transfer coefficient
A_exchanger = 5;        % m^2 : effective heat exchange area

UA_exchanger = U_exchanger*A_exchanger;  % in W/K
%}

%% Transport to demand, pipe heat loss model

% Pipe geometry assumptions
L_pipe = 20*unit("m");                % m, estimated pipe length to demand
d_pipe = 0.025*unit("m");             % m, outer pipe diameter

% Pipe surface area
A_pipe = pi*d_pipe*L_pipe;            % m^2

% Effective heat-loss coefficient for insulated pipe
U_pipe = 1.5;                         % W/(m^2 K)

% Combined pipe heat-loss coefficient
UA_pipe = U_pipe*A_pipe;              % [W/K]