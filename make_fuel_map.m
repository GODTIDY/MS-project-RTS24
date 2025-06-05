function make_fuel_map(matpowerFile, outFile)
% 从 Matpower .m 文件提取 UnitCode → FuelType → Factor
% 用法:  make_fuel_map('case24_ieee_rts.m','gen_fuel_map.csv')

txt = fileread(matpowerFile);

%% 1) 抓 gencost 段
expr = '(?ms)mpc\.gencost\s*=\s*\[(.*?)\];';
blk  = regexp(txt, expr, 'tokens', 'once');
assert(~isempty(blk), '⚠️  未找到 mpc.gencost 段！');
lines = regexp(blk{1}, '\r?\n', 'split');

%% 2) 过滤掉空行与纯注释行，只保留以数字开头的行
dataLines = lines(~cellfun(@isempty, regexp(lines,'^\s*\d')));

nGen  = numel(dataLines);
genID = (1:nGen)';

unit  = strings(nGen,1);
for k = 1:nGen
    % 行尾注释里抓 “U###”
    u = regexp(dataLines{k}, 'U\d+', 'match', 'once');
    if isempty(u), u = "NONE"; end
    unit(k) = u;
end

%% 3) UnitCode → FuelType / Factor
fuel   = strings(nGen,1); factor = zeros(nGen,1);

coal = ["U400","U350","U197","U155"];
ngcc = ["U100","U76"];
ngct = ["U50","U20","U12"];

for k = 1:nGen
    if     any(unit(k)==coal)
        fuel(k)="COAL"; factor(k)=0.95;
    elseif any(unit(k)==ngcc)
        fuel(k)="NGCC"; factor(k)=0.40;
    elseif any(unit(k)==ngct)
        fuel(k)="NGCT"; factor(k)=0.55;
    else
        fuel(k)="OTH";  factor(k)=0;      % 默认 0 t/MWh
    end
end

%% 4) 写 CSV
tbl = table(genID, unit, fuel, factor, ...
    'VariableNames', {'GenID','UnitCode','FuelType','Factor'});
writetable(tbl, outFile);
fprintf('✅ 生成 %s — 共 %d 机组\n', outFile, nGen);
end
