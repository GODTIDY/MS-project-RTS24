############################################################
# AMPL Model: DC Power Flow with Battery Deployment
############################################################

# 1. 定义集合（Sets）
set I;                  # 节点集合      
set P;                  # 发电机集合
set L;                  # 线路集合（索引 BranchID）

# 2. 定义参数（Parameters）
param Pd {I} default 0;       # 节点有功负荷（MW）
param Bus {P};                # 发电机连接的节点编号
param Pmax {P};               # 发电机最大功率（MW）
param Pmin {P};               # 发电机最小功率（MW）
param Pc0 {P};                # 发电固定成本
param Pc1 {P};                # 发电成本一次项系数
param Pc2 {P};                # 发电成本二次项系数
param Pgm {P};                # 定义参数 Pgm（MATPOWER 计算的 Pg）
param FuelType {P};           # 发电机类型（1=可再生，0=非可再生）
param BatCost {I} default 0; # 电池单位容量（MWh）的安装成本

param FromBus {L};            # 线路起点
param ToBus {L};              # 线路终点
param X {L};                  # 线路电抗（p.u.）
param RateA {L};              # 线路最大功率（MW）

# **新增 Slack Bus 选择**
set SlackBus within I;         # 参考节点集合

# 3. **修改 StorageBus 计算**
set StorageBus within I := {i in I: sum {p in P} (if Bus[p] == i and FuelType[p] == 1 then 1 else 0) > 0};


# 4. 定义变量（Variables）
var Pg {P} >= 0;               # 发电机出力（MW）
var theta {I};                 # 节点电压相角（弧度）
var flow {L};                  # 线路功率流（MW）
var uload {I} >= 0;            # 允许的负荷未满足量（MW）

# **新增电池部署容量变量**
var Capacity {StorageBus} >= 0;  # 在可再生能源 BUS 处部署的电池容量（MWh）

# 5. 目标函数（Minimize Generation Cost + Battery Deployment Cost）
minimize TotalCost:
    sum {p in P} (Pc2[p] * Pg[p]^2 + Pc1[p] * Pg[p] + Pc0[p]) +
    sum {i in I} (9000 * uload[i]) +
    sum {i in StorageBus} (BatCost[i] * Capacity[i]); # 新增电池部署成本

# 6. 约束（Constraints）

# 6.1 **功率平衡约束**
subject to PowerBalance {i in I}:
    sum {l in L: FromBus[l] == i} flow[l] - sum {l in L: ToBus[l] == i} flow[l] =
    sum {p in P: Bus[p] == i} Pg[p] - Pd[i] + uload[i];

# 6.2 **线路功率约束**
subject to FlowDefinition {l in L}:
    flow[l] = (1 / X[l]) * (theta[FromBus[l]] - theta[ToBus[l]]);

subject to LineLimit_lower {l in L}:
    flow[l] >= -RateA[l];

subject to LineLimit_upper {l in L}:
    flow[l] <= RateA[l];

# 6.3 **发电机约束**
subject to Pg_min {p in P}:
    Pg[p] >= Pmin[p];

subject to Pg_max {p in P}:
    Pg[p] <= Pmax[p];

# 6.4 **参考节点约束（相角固定）**
subject to ReferenceBus {i in I: i == 1951}:  
    theta[i] = 0;

# 6.5 **电池容量上限约束**
subject to BatteryCapacityLimit {i in StorageBus}:
    Capacity[i] <= 100;  # 限制每个电池站点的最大容量（可调整）







