% calc_curtail_utilisation_single.m
% ----------------------------------
% 读取 ChargeCurtail.csv  (AMPL display 格式，所有母线)
% 和 curtail_pg_clean.tab (BusID, Time, Scenario, CurtailPg)
% 计算全系统被电池吸收的弃电比例（%）
% 并绘制单柱图 + 在命令窗口输出
% ----------------------------------

fileCC  = 'ChargeCurtail.csv';
fileTot = 'curtail_pg_clean.tab';

if ~isfile(fileCC) || ~isfile(fileTot)
    error('⚠️  必须确保 %s 与 %s 同目录！', fileCC, fileTot);
end

%% ---------- 1) 读取总弃电 -----------
T = readtable(fileTot, 'FileType','text', ...
              'Delimiter','\t', 'VariableNamingRule','preserve');

if ~ismember('CurtailPg', T.Properties.VariableNames)
    error('Column "CurtailPg" not found in %s', fileTot);
end
totalCurt = sum(T.CurtailPg, 'omitnan');   % <-- 一定得到标量


%% ---------- 2) 读取被利用弃电 -------
CC = parseAMPLdisplay(fileCC);            % helper 函数见下
usedCurt = sum(CC.MW,'omitnan');          % [MWh]

utilPct = usedCurt / totalCurt * 100;

fprintf('\n===== Curtailment utilisation =====\n');
fprintf('Total curtailment : %10.2f  MWh\n', totalCurt);
fprintf('Utilised in BESS  : %10.2f  MWh\n', usedCurt);
fprintf('Utilisation ratio : %8.2f %%\n\n', utilPct);

%% ---------- 3) 简单柱状图 ----------
figure('Color','w');
bar(1, utilPct, 0.4, 'FaceColor',[0.2 0.6 0.8]);
set(gca,'XTick',[], 'XLim',[0.5 1.5]);
ylabel('Curtailment utilisation (\%)');
title('System-wide curtailment utilisation');
text(1, utilPct+1, sprintf('%.2f %%',utilPct), ...
     'HorizontalAlignment','center','FontSize',10);
grid on;

print(gcf,'curtail_utilisation.png','-dpng','-r300');
print(gcf,'curtail_utilisation.pdf','-dpdf','-painters');
fprintf('✅ 图像已保存 curtail_utilisation.[png|pdf]\n');

%% ---------- helper: 解析 AMPL display ----------
function T = parseAMPLdisplay(fname)
    txt  = fileread(fname);
    L    = regexp(txt,'\r?\n','split');
    hdr  = find(startsWith(strtrim(L),':'),1,'first');
    buses = str2double(strsplit(erase(L{hdr},':=')));
    buses = buses(~isnan(buses));

    data = str2num(char(L(hdr+1 : hdr+24))); %#ok<ST2NM>
    if size(data,2) ~= numel(buses)+1
        error('Column mismatch in %s (expect %d buses, got %d)', ...
              fname, numel(buses), size(data,2)-1);
    end

    Hour = data(:,1);
    vals = data(:,2:end);          % 先取矩阵，再展开成列向量
    [H,B] = ndgrid(Hour, buses);

    T       = table;
    T.BusID = B(:);
    T.Hour  = H(:);
    T.MW    = vals(:);
end
