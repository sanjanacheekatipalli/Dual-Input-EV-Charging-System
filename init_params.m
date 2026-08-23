%% matlab/init_params.m
% and run_scenarios.m.
%
% RUN ORDER:
%   1. init_params    
%   2. run_scenarios
%   3. plot_results
%


%% Time base
total_time = 8*3600;      % total charging window, in seconds (8 hours)
dt = 60;                  % time step, in seconds — must match the
t = (0:dt:total_time)';   % time vector used to build scenario profiles

%% Battery
capacity_Wh = 40000;      % battery capacity in Wh (e.g. 40 kWh EV pack)
                           % — set this to match the vehicle you cited
                           % in Chapter 1/2

%% Solar PV
P_rated = 300;             % rated PV panel power, in W

%% Wireless Power Transfer
eta_max  = 0.92;           % maximum WPT efficiency
P_in_wpt = 1500;           % available input power to the WPT transmitter, in W

%% Traditional (baseline) charger
P_base = 1000;              % fixed grid charging power, in W, for comparison

% Time vector (adjust duration/step to match your simulation)
t = (0:60:86400)';   % example: 24 hours in 60s steps, change to your actual dt

% Irradiance profile (W/m^2) - replace with your actual data/profile
irradiance = 1000 * max(0, sin(pi * mod(t,86400) / 86400));  % simple daytime curve
irradiance_ts = timeseries(irradiance, t);
irradiance_ts.Name = 'irradiance_ts';

% Coupling profile (e.g. coupling coefficient for WPT, 0-1)
coupling = 0.8 * ones(size(t));   % replace with your actual coupling variation
coupling_ts = timeseries(coupling, t);
coupling_ts.Name = 'coupling_ts';

fprintf('Parameters initialized:\n');
fprintf('  total_time = %d s (%.1f hours)\n', total_time, total_time/3600);
fprintf('  dt = %d s\n', dt);
fprintf('  capacity_Wh = %d Wh\n', capacity_Wh);
fprintf('  P_rated (PV) = %d W\n', P_rated);
fprintf('  eta_max (WPT) = %.2f\n', eta_max);
fprintf('  P_in_wpt = %d W\n', P_in_wpt);
fprintf('  P_base (baseline) = %d W\n', P_base);
