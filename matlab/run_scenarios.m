%% run_scenarios.m
% Defines three charging scenarios (sunny, cloudy/night, mixed) and runs
% the Simulink model for each. The traditional single-source baseline is
% ALSO a real subsystem inside the same circuit (Baseline_Power ->
% Baseline_SOC), so every output — dual-source and baseline — comes from
% the Simulink simulation itself, not a separate MATLAB calculation.
%

% Requires: dual_source_ev_charging.slx
% Produces: scenario_results.mat (loaded by plot_results.m)

modelName = 'dual_source_ev_charging';
if ~bdIsLoaded(modelName)
    open_system(modelName);
end

% Force To Workspace blocks to write directly to the base workspace,
% regardless of whether sim()'s return value is captured. Without this,
% newer MATLAB releases route logged signals into the Simulink.SimulationOutput
% object instead, and evalin('base', 'P_pv_out') etc. below will fail with
% "Unrecognized function or variable".
set_param(modelName, 'ReturnWorkspaceOutputs', 'off');

% Requires init_params.m to have been run first (defines total_time, dt,
% t, capacity_Wh, P_base, etc.). Run it now if those variables aren't
% already in the workspace.
if ~exist('total_time', 'var') || ~exist('capacity_Wh', 'var')
    fprintf('init_params variables not found in workspace — running init_params.m now.\n');
    init_params;
end

scenarios = {'sunny', 'cloudy', 'mixed'};
results = struct();

for s = 1:numel(scenarios)
    name = scenarios{s};

    switch name
        case 'sunny'
            % Bell-curve irradiance peaking at midday, stable coupling
            irradiance = 1000 * max(0, sin(pi * t/total_time)).^1.5;
            coupling   = 0.30 * ones(size(t));
        case 'cloudy'
            % Near-zero irradiance (overcast/night), stable coupling
            % forces the controller to rely on WPT
            irradiance = 50 * ones(size(t));
            coupling   = 0.30 * ones(size(t));
        case 'mixed'
            % Bell-curve irradiance PLUS variable coupling (simulated
            % misalignment) to stress-test the intelligent switching
            irradiance = 1000 * max(0, sin(pi * t/total_time)).^1.5;
            coupling   = 0.20 + 0.15 * sin(2*pi*t/(3600*2)); % oscillating alignment
            coupling   = max(coupling, 0.05);
    end

    % Assign to base workspace as [time, data] matrices for From Workspace blocks
    assignin('base', 'irradiance_ts', [t, irradiance]);
    assignin('base', 'coupling_ts',   [t, coupling]);

    fprintf('Running scenario: %s ...\n', name);
    set_param(modelName, 'StopTime', num2str(total_time));
    sim(modelName);

    % Pull logged signals back from base workspace (To Workspace blocks
    % write here by default when using sim() at the command line)
    P_pv       = evalin('base', 'P_pv_out');
    P_wpt      = evalin('base', 'P_wpt_out');
    eta_wpt    = evalin('base', 'eta_wpt_out');
    P_selected = evalin('base', 'P_selected_out');
    source     = evalin('base', 'source_out');
    SOC        = evalin('base', 'SOC_out');
    SOC_base   = evalin('base', 'SOC_baseline_out');

    results.(name).time       = P_selected.time;
    results.(name).P_pv       = P_pv.signals.values;
    results.(name).P_wpt      = P_wpt.signals.values;
    results.(name).eta_wpt    = eta_wpt.signals.values;
    results.(name).P_selected = P_selected.signals.values;
    results.(name).source     = source.signals.values;
    results.(name).SOC        = SOC.signals.values;

    % Baseline circuit runs alongside every scenario with the same fixed
    % input, so its output is identical each time — captured here from
    % the last completed run (overwritten each iteration, same result).
    results.baseline.time = SOC_base.time;
    results.baseline.SOC  = SOC_base.signals.values;

    % Diagnostic: confirm real data was captured (not empty arrays)
    fprintf('  -> logged %d samples for "%s" (time span %.1f to %.1f hours)\n', ...
        numel(results.(name).time), name, ...
        results.(name).time(1)/3600, results.(name).time(end)/3600);
end

save('scenario_results.mat', 'results');
fprintf('\nAll scenarios complete. Saved to scenario_results.mat\n');
