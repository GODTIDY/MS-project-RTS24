%% ---------- user inputs ----------
files  = {'Pg_C.csv','Pg_G.csv'};              % Pg 文件
labels = {'C'     ,'G'     };                  % 场景标签
costs  = [66416430.61 , 56103520.63];          % 对应系统成本 ($)
mapFile = 'gen_fuel_map.csv';                  % GenID → Factor
outFile = 'cost_emission_summary_two.csv';     % 输出
%% ----------------------------------

map = readtable(mapFile);        % GenID, Factor

allEmis = zeros(numel(files),1); % 先占位
for k = 1:numel(files)
    pg = readtable(files{k},'ReadVariableNames',false,...
                   'Delimiter',',');          % GenID, Energy
    pg.Properties.VariableNames = {'GenID','Energy_MWh'};
    
    M = innerjoin(pg,map,'Keys','GenID');     % 加排放因子
    allEmis(k) = sum(M.Energy_MWh .* M.Factor,'omitnan');
end

summary = table(string(labels(:)), costs(:), allEmis, ...
                'VariableNames',{'Scenario','Cost','Emission_t'});

writetable(summary,outFile);
disp(summary);
