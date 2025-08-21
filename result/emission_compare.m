%% -------- PLOT ----------
% 差值：G - C  （如需 C - G，把减法顺序调换）
diffEmis = emisMat(:,2) - emisMat(:,1);

% 为了兼容非数值 GenID，使用 1..N 作为横轴，并设置自定义刻度标签
x = 1:numel(genList);

figure('Position',[50 50 1000 350]);
plot(x, diffEmis, '-o', 'LineWidth', 1.8, 'MarkerSize', 5);
hold on;
yline(0,'k--','LineWidth',1);    % 中水平线 y=0
hold off;

xlim([0.5, numel(genList)+0.5]);
xticks(x);
xticklabels(string(genList));
xtickangle(0);                   % 如标签挤在一起可改为 45

xlabel('Generator ID');
ylabel('\Delta Annual CO_2 (t)  \{G - C\}');
title('Per-unit emission difference: Grid-charging minus Curtail-only');
grid on; box on;

% 导出文件名（不改前面配置也可用）
outFig = 'emis_diff_G_minus_C.png';
print(outFig,'-dpng','-r300');
disp(['Saved ', outFig]);