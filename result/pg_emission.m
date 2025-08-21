%% -------- CONFIG --------
pgFiles = {'Pg_C.csv','Pg_G.csv'};   % order matters → C then G
labels  = {'C','G'};                 % legend text
mapFile = 'gen_fuel_map.csv';        % GenID → factor
outFig  = 'emis_bar_C_vs_G.png';     % output graphic
%% ------------------------

map = readtable(mapFile);            % GenID | Factor
emisMat = [];                        % rows = GenID, cols = scenarios

for f = 1:numel(pgFiles)
    pg = readtable(pgFiles{f},'ReadVariableNames',false,...
                   'Delimiter',',');
    pg.Properties.VariableNames = {'GenID','Energy_MWh'};
    
    M  = innerjoin(pg,map,'Keys','GenID');
    emis = M.Energy_MWh .* M.Factor;          % t CO₂ per unit
    
    if f==1
        genList = M.GenID; emisMat = emis;
    else
        emisMat = [emisMat, emis];            % append second column
    end
end

%% -------- PLOT ----------
figure('Position',[50 50 1000 350]);
b = bar(genList, emisMat, 'grouped');
b(1).FaceColor = [0.0 0.45 0.74];    % blue for C
b(2).FaceColor = [0.85 0.33 0.10];   % red  for G

xlabel('Generator ID');
ylabel('Annual CO_2 (t)');
title('Per-unit emission comparison: Curtail-only vs Grid-charging');
legend(labels,'Location','northwest');
grid on; box on;

print(outFig,'-dpng','-r300');       % 300 dpi PNG
disp(['Saved ', outFig]);
