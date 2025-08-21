function plot_charge_discharge_AMPL
% -----------------------------------------------
% Read AMPL “display” style matrices (whitespace-delimited) produced by
%   display Charge[...] > "Charge.csv";
%   display Discharge[...] > "Discharge.csv";
% Convert to long format and draw charge / discharge curves per bus.
% -----------------------------------------------

fileC = 'Charge.csv';
fileD = 'Discharge.csv';
drawDischarge = true;     % set false if you only have Charge.csv

% ---------- parse AMPL matrix ------------------
tblC = parseAMPLdisplay(fileC);

if drawDischarge && isfile(fileD)
    tblD = parseAMPLdisplay(fileD);
else
    drawDischarge = false;
end

buses  = unique(tblC.BusID);
colors = lines(numel(buses));

% -------------- plot ---------------------------
figure('Color','w');
if drawDischarge, tiledlayout(2,1,'TileSpacing','compact'); end

% ----- Charge -----
ax1 = nexttile;
hold(ax1,'on');
for k = 1:numel(buses)
    idx = tblC.BusID==buses(k);
    plot(ax1, tblC.Hour(idx), tblC.MW(idx), '-o', ...
        'Color', colors(k,:), 'LineWidth',1.4, ...
        'DisplayName', ['Bus ' num2str(buses(k))]);
end
title(ax1,'Hourly charge power'); ylabel(ax1,'MW');
grid(ax1,'on'); legend(ax1,'show','Location','best');

% ----- Discharge -----
if drawDischarge
    ax2 = nexttile;
    hold(ax2,'on');
    for k = 1:numel(buses)
        idx = tblD.BusID==buses(k);
        plot(ax2, tblD.Hour(idx), tblD.MW(idx), '-o', ...
            'Color', colors(k,:), 'LineWidth',1.4);
    end
    title(ax2,'Hourly discharge power'); xlabel(ax2,'Hour'); ylabel(ax2,'MW');
    grid(ax2,'on');
else
    xlabel(ax1,'Hour');
end

% -------------- export -------------------------
out = 'charge_discharge';
print(gcf,[out '.png'],'-dpng','-r300');
print(gcf,[out '.pdf'],'-dpdf','-vector');
fprintf('✅  Figure exported: %s.[png|pdf]\n', out);
end
% ============ helper: parse AMPL display =====================
function T = parseAMPLdisplay(fname)
% Returns table with columns: BusID, Hour, MW

txt = fileread(fname);
lines = regexp(txt,'\r?\n','split')';

% find bus-header line (starts with ':')
hdrIdx = find(startsWith(strtrim(lines),':'),1,'first');
if isempty(hdrIdx), error('Cannot locate bus header (":" line) in %s',fname); end

% bus IDs (numbers after ':')
busIDs = str2double(strsplit(strtrim(erase(lines{hdrIdx},':='))));
busIDs = busIDs(~isnan(busIDs));

% following 24 lines are numeric rows
data = str2num(char(lines(hdrIdx+1 : hdrIdx+24))); %#ok<ST2NM>

if size(data,2) ~= numel(busIDs)+1
    error('Column mismatch in %s (got %d buses, %d data cols)', ...
          fname,numel(busIDs), size(data,2)-1);
end

Hour = data(:,1);
vals = data(:,2:end);

% long format
[H,B]   = ndgrid(Hour, busIDs);
T       = table;
T.BusID = B(:);
T.Hour  = H(:);
T.MW    = vals(:);
end
