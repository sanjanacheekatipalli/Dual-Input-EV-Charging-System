%% plot_results.m
% Loads scenario_results.mat and generates the figures for your
% Results and Discussion chapter. Saves each as a .png in the
% current folder, ready to insert into your dissertation.
%
% All data plotted here — including the baseline — comes from the
% Simulink circuit simulation, not a separate MATLAB calculation.

load('scenario_results.mat', 'results');
scenarios = {'sunny','cloudy','mixed'};
colors = struct('sunny',[0.90 0.60 0.10], 'cloudy',[0.30 0.30 0.60], 'mixed',[0.10 0.60 0.30]);

%% Figure 1: Power vs time (PV, WPT, selected) — one subplot per scenario
figure('Position',[100 100 900 700]);
for i = 1:numel(scenarios)
    s = scenarios{i};
    subplot(3,1,i);
    hours = results.(s).time/3600;
    plot(hours, results.(s).P_pv, 'LineWidth', 1.3); hold on;
    plot(hours, results.(s).P_wpt, 'LineWidth', 1.3);
    plot(hours, results.(s).P_selected, 'k--', 'LineWidth', 1.3);
    legend('P_{pv}','P_{wpt}','P_{selected}', 'Location','best');
    title(['Power distribution — ' s ' scenario']);
    xlabel('Time (hours)'); ylabel('Power (W)'); grid on;
end
saveas(gcf, 'fig_power_distribution.png');

%% Figure 2: Efficiency comparison — dual-source vs traditional baseline
figure('Position',[100 100 700 450]);
avg_eta = zeros(1,numel(scenarios));
for i = 1:numel(scenarios)
    s = scenarios{i};
    valid = results.(s).source == 2;   % only meaningful where WPT is active
    if any(valid)
        avg_eta(i) = mean(results.(s).eta_wpt(valid));
    else
        avg_eta(i) = mean(results.(s).eta_wpt);
    end
end
bar([avg_eta*100, 100]);  % last bar = assumed 100% grid baseline (no conversion loss)
set(gca, 'XTickLabel', {'Sunny (dual)','Cloudy (dual)','Mixed (dual)','Baseline (grid)'});
ylabel('Average efficiency (%)');
title('Efficiency comparison: intelligent dual-source vs traditional charging');
grid on;
saveas(gcf, 'fig_efficiency_comparison.png');

%% Figure 3: SOC vs time — all scenarios + baseline overlay
figure('Position',[100 100 800 500]);
hold on;
for i = 1:numel(scenarios)
    s = scenarios{i};
    plot(results.(s).time/3600, results.(s).SOC, 'LineWidth', 1.5, ...
        'Color', colors.(s));
end
plot(results.baseline.time/3600, results.baseline.SOC, 'k--', 'LineWidth', 1.5);
legend([scenarios, {'Baseline (traditional)'}], 'Location','southeast');
xlabel('Time (hours)'); ylabel('State of Charge (%)');
title('Battery SOC over time: dual-source scenarios vs baseline');
grid on;
saveas(gcf, 'fig_soc_comparison.png');

%% Figure 4: Source-switching timeline
figure('Position',[100 100 900 500]);
for i = 1:numel(scenarios)
    s = scenarios{i};
    subplot(3,1,i);
    stairs(results.(s).time/3600, results.(s).source, 'LineWidth', 1.3);
    ylim([-0.5 2.5]); yticks([0 1 2]);
    yticklabels({'Off/Full','PV','WPT'});
    title(['Source selection over time — ' s]);
    xlabel('Time (hours)'); grid on;
end
saveas(gcf, 'fig_source_switching.png');

fprintf('\nAll four figures saved as PNG files in the current folder:\n');
fprintf('  fig_power_distribution.png\n');
fprintf('  fig_efficiency_comparison.png\n');
fprintf('  fig_soc_comparison.png\n');
fprintf('  fig_source_switching.png\n');
