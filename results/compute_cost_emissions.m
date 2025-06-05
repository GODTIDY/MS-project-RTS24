
costFile = 'hfactor_cost_1_100.csv';   
mapFile  = 'gen_fuel_map.csv';         
pgPat    = 'Pg_h%d.csv';               


nums = str2double( regexp(fileread(costFile), '\d+\.?\d*', 'match') ).';
assert(mod(numel(nums),2)==0, '⚠ The figures in the cost documents should appear in pairs');

hFactor = nums(1:2:end);
Cost    = nums(2:2:end);
N       = numel(hFactor);

mapTab = readtable(mapFile);       
genID  = mapTab.GenID;            
factor = mapTab.Factor;


Emission = NaN(N,1);

for k = 1:N
    pgFile = sprintf(pgPat, hFactor(k));
    if ~isfile(pgFile)
        warning('%s  NaN', pgFile);  continue
    end


    pg = readtable(pgFile,'ReadVariableNames',false,...
                   'Delimiter',{' ','\t',','});


    if isnumeric(pg.Var1)
        gid = pg.Var1;
    else
        gid = str2double(pg.Var1);
    end

    if isnumeric(pg.Var2)
        mwh = pg.Var2;
    else
        mwh = str2double(pg.Var2);
    end


    [tf, loc] = ismember(gid, genID);
    if any(~tf)
        warning('Pg include unkown GenID，ignored');
    end
    Emission(k) = sum( mwh(tf) .* factor(loc(tf)) , 'omitnan');
end


resTbl = table(hFactor, Cost, Emission, ...
               'VariableNames',{'hFactor','Cost','Emission_t'});
writetable(resTbl,'cost_emission_summary.csv');
disp('✅ cost_emission_summary.csv saved');

figure;
yyaxis left
plot(resTbl.hFactor, resTbl.Cost/1e6,'-o','LineWidth',1.6);
ylabel('System cost (Million $)');

yyaxis right
plot(resTbl.hFactor, resTbl.Emission_t,'--s','LineWidth',1.6);
ylabel('Annual CO_2 (t)');

xlabel('hFactor'); grid on
title('RTS-24 Battery — Cost vs Emissions');


% saveas(gcf,'cost_emis.png');          % PNG

outName = 'cost_vs_emissions_RTS24';   

% ① PNG：300 dpi
print(gcf, sprintf('%s.png',outName), '-dpng', '-r500');


print(gcf, sprintf('%s.pdf',outName), '-dpdf', '-painters');

disp('✅  The image has been exported.：');
disp([outName '.png']);
disp([outName '.pdf']);

