function plot_cost_emis_all(numCases, baseName, outName)
% Plot cost & emission lines for <numCases> CSV files.
% Each file named <baseName><k>.csv, k = 1…N.
% Saves <outName>.png / .pdf in current folder.
%
% Example:
%   plot_cost_emis_all(4,'cost_emission_summary','Cost_Emis_All')

if nargin < 3, outName = 'Cost_Emission_AllScenarios'; end
if nargin < 2, baseName = 'cost_emission_summary';    end
if nargin < 1, numCases = 4;                          end

files  = arrayfun(@(k) sprintf('%s%d.csv', baseName, k), ...
                  1:numCases, 'uni', 0);
colors = lines(numCases);

figure; hold on;
yyaxis left
costH = gobjects(1,numCases);
for i = 1:numCases
    T = readtable(files{i});
    costH(i) = plot(T.hFactor, T.Cost/1e6, '-', ...
        'Color', colors(i,:), 'LineWidth', 1.8);
end
ylabel('System cost (Million $)');

yyaxis right
emisH = gobjects(1,numCases);
for i = 1:numCases
    T = readtable(files{i});
    emisH(i) = plot(T.hFactor, T.Emission_t, '--', ...
        'Color', colors(i,:), 'LineWidth', 1.8);
end
ylabel('Annual CO_2 (t)');

grid on; box on;
xlabel('hFactor');
title('Cost & Emissions — Multiple Scenarios');

lgdHandles = reshape([costH; emisH],1,[]);
lgdLabels  = strings(1,2*numCases);
for i = 1:numCases
    lgdLabels(2*i-1) = sprintf('Cost  – Case %d', i);
    lgdLabels(2*i)   = sprintf('Emis. – Case %d', i);
end
legend(lgdHandles, lgdLabels, ...
       'Location','eastoutside', 'Orientation','vertical', ...
       'Box','off');

print(gcf,[outName '.png'],'-dpng','-r300');
print(gcf,[outName '.pdf'],'-dpdf','-painters');
fprintf('✅ Output saved as %s.[png|pdf]\n', outName);
end
