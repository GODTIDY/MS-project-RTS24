########################################
# AMPL Model: Two-Stage Battery Optimization
########################################

# =====================
# SET DEFINITIONS
# =====================
set I; set P; set L;
set T ordered := 1..24;
set S := {"Winter","Spring","Summer","Autumn"};
set StorageBus := {3,5,7,16,21,23};

# ========== Sensitivity framework ==========
set H := {2,3,4,5,6,7};                       # hFactor pool
set ShutSwitch := {0,1};                  # AllowShutdown 
set Penalty := {0,5,10};                  # $/MWh 
# =======================
# =====================
# PARAMETER DEFINITIONS
# =====================
param Bus {P};
param Pd       {I,T,S} >= 0;
param WindPg   {I,T,S} >= 0;
param CurtailPg{I,T,S} >= 0;

param Pmax {P};  param Pmin {P};
param Pc0  {P};  param Pc1  {P};  param Pc2 {P};

param FromBus {L};  param ToBus {L};
param X {L};        param RateA {L};

param scen_weight {s in S} >= 0;
param ResCost{h in {2,3,4,5,6,7}};
### -------- switch ----------
param AllowShutdown default 0;     # =1 allow Pg down to 0； =0 constraint Pmin (old setting)
param SiteCapSwitch   default 0;   # 1 = cap active, 0 = inactive
####test sensitivity test###
#param eps := 1e-4;           # Tolerate numerical errors
param hFactor default 4;                 
param ChargeGridPenalty default 100;       # $/MWh, Virtual cost of on-grid charging
param CurtPeakScale default 1;           # Peak wind curtailment amplification coefficient
param Result{H, ShutSwitch, Penalty};   # Store system costs
param BatteryEta    default 0.95;   # η_c = η_d
param SOCband       default 0.60;   # SOC_max − SOC_min
param RateAScale    default 1;      # Line capacity scaling 0.8–1.0
param LoadScale     default 1;      # Load ±15 %
param VoLL          default 9000;   # Overload penalty (/MWh)
param BaseCost;         

# Result buckets
param ResPenalty  {p in {0,5,10,20}};
param ResRate     {r in {0.8,1}};
param ResLoad     {ls in {0.85,1,1.15}};
param ResVoLL     {v in {5000,9000,15000}};

param ResPenCore  {3..6, 1..2, 1..2, {0,10}};
param ResRateCore {3..6, 1..2, 1..2, {0.8,1}};
param ResLoadCore {3..6, 1..2, 1..2, {1,1.15}};


########################################################

# =====================
# BATTERY PARAMETERS
# =====================
param eta_c := BatteryEta;
param eta_d := BatteryEta;

param SOC_min := 0.5 - SOCband/2;
param SOC_max := 0.5 + SOCband/2;

# --------Peak wind power curtailment----------------
param CurtPeak {i in StorageBus} :=
      CurtPeakScale * max {t in T, s in S} CurtailPg[i,t,s];


#####test# =====================
# STAGE-1 VARIABLES
# =====================
var Capacity {i in StorageBus} >= 0;                                                                    #3.5


# =====================
# STAGE-2 VARIABLES
# =====================
var Pg        {p in P, t in T, s in S} >= 0;
var PgBattery {i in StorageBus, t in T, s in S} >= 0;
var theta     {i in I, t in T, s in S};
var flow      {l in L, t in T, s in S};
var uload     {i in I, t in T, s in S} >= 0;

# ----- Battery -----
var Charge       {i in StorageBus, t in T, s in S} >= 0;
var Discharge    {i in StorageBus, t in T, s in S} >= 0;
var SOC          {i in StorageBus, t in T, s in S} >= 0;

### ---- charging sources -------------------------------
var ChargeCurtail {i in StorageBus, t in T, s in S} >= 0;  
var ChargeGrid    {i in StorageBus, t in T, s in S} >= 0; 


# =====================
# OBJECTIVE
# =====================
minimize Total_Cost:                                                                                    #3.1
    sum {s in S} scen_weight[s] * (
        sum {t in T, p in P} (Pc2[p]*Pg[p,t,s]^2 + Pc1[p]*Pg[p,t,s] + Pc0[p])
      + sum {i in I, t in T} VoLL*uload[i,t,s]
      + sum {i in StorageBus, t in T} ChargeGridPenalty * ChargeGrid[i,t,s]
    );

# =====================
# CONSTRAINTS
# =====================

# ----- Power balance -----
subject to PowerBalance {i in I, t in T, s in S}:                                                       #3.6
      sum {p in P: Bus[p]==i} Pg[p,t,s]
    + (if i in StorageBus then PgBattery[i,t,s] else 0)
    + WindPg[i,t,s]
    + sum {l in L: ToBus[l]==i}   flow[l,t,s]
    - sum {l in L: FromBus[l]==i} flow[l,t,s]
    - (if i in StorageBus then ChargeGrid[i,t,s] else 0)   
    = LoadScale * Pd[i,t,s] - uload[i,t,s];

# ----- DC flow -----
subject to FlowDef {l in L, t in T, s in S}:                                                            #3.7
    flow[l,t,s] = (1/X[l]) * (theta[FromBus[l],t,s] - theta[ToBus[l],t,s]);

subject to LineLimit_lower {l in L, t in T, s in S}: flow[l,t,s] >= -RateAScale * RateA[l];             #3.16
subject to LineLimit_upper {l in L, t in T, s in S}: flow[l,t,s] <=  RateAScale * RateA[l];             #3.16

# ----- Lower limit of the unit (with shutdown switch) -----
subject to GenMin {p in P, t in T, s in S}:                                                             #3.15
    Pg[p,t,s] >= (1-AllowShutdown) * Pmin[p];              

subject to GenMax {p in P, t in T, s in S}:                                                             #3.15
    Pg[p,t,s] <= Pmax[p];

# ----- Reference busbar -----
subject to ReferenceBus {t in T, s in S}: theta[23,t,s] = 0;

# ----- Battery energy balance -----
subject to BatterySOC {i in StorageBus, t in T, s in S: t>1}:                                           #3.12
    SOC[i,t,s] = SOC[i,t-1,s] + eta_c*Charge[i,t,s] - (1/eta_d)*Discharge[i,t,s];

subject to BatteryInitEnd  {i in StorageBus, s in S}: SOC[i,1,s]       = 0.5*Capacity[i];               #3.14
subject to BatteryFinalSOC {i in StorageBus, s in S}: SOC[i,card(T),s] = 0.5*Capacity[i];               #3.14

# ----- limit of charging and discharging power ≤ the Curtpeak & SOC range -----
subject to ChargePeak {i in StorageBus, t in T, s in S}:                                                #3.11
    Charge[i,t,s]    <= Capacity[i]*0.25;

subject to DischargePeak {i in StorageBus, t in T, s in S}:                                             #3.11
    Discharge[i,t,s] <= Capacity[i]*0.25;
    
subject to DischargePeak1 {i in StorageBus, t in T, s in S}:                                            #3.17
    Discharge[i,t,s]+WindPg[i,t,s] <= max {tt in T, ss in S} WindPg[i,tt,ss];# / hFactor;    
        
subject to SOCLower {i in StorageBus, t in T, s in S}:                                                  #3.13
    SOC[i,t,s] >= SOC_min * Capacity[i];

subject to SOCUpper {i in StorageBus, t in T, s in S}:                                                  #3.13
    SOC[i,t,s] <= SOC_max * Capacity[i];

# ----- Charging source & Upper limit of power rationing -----
subject to ChargeDecompose {i in StorageBus, t in T, s in S}:                                           #3.9
    Charge[i,t,s] = ChargeCurtail[i,t,s] + ChargeGrid[i,t,s];           

subject to CurtailmentCap {i in StorageBus, t in T, s in S}:                                            #3.10
    ChargeCurtail[i,t,s] <= CurtailPg[i,t,s];                           

# ----- Battery discharge injection limit -----
subject to PgBatteryMatch {i in StorageBus, t in T, s in S}:                                            #3.18
    PgBattery[i,t,s] <= Discharge[i,t,s];

# ---------- SiteEnergyCap ≤ hfactor×CurtPeak ----------
#subject to SiteEnergyCap {i in StorageBus : SiteCapSwitch = 1}:
        #Capacity[i] <= hFactor * CurtPeak[i];

# ---------- TotalEnergy ≤ Σ 4×CurtPeak ----------
subject to TotalEnergyCap:                                                                               #3.8
    sum {i in StorageBus} Capacity[i] <= 4 * sum {i in StorageBus} CurtPeak[i];
