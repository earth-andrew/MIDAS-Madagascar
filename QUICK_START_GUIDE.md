# Madagascar MIDAS - Quick Start Guide

**Status**: ✅ **VERIFIED & READY**  
**Date**: November 11, 2025

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Open MATLAB
```matlab
cd /Users/adham/Documents/MIDAS/MIDAS-Core-dev-MADA
```

### Step 2: Quick Verification (30 seconds)
```matlab
test_override_mechanism  % Verify Madagascar config will load
```

**Expected**: Reports "✅ Override mechanism working correctly"

### Step 3: Run Integration Test (2-3 minutes)
```matlab
test_full_integration
```

**Expected**: 
- "✓ Override createUtilityLayers active"
- "✓ PASS: 44 locations"
- "✓ PASS: Urban has higher formal sector (Madagascar config loaded)"
- "✅ All tests passed"

### Step 4: Run Full Simulation
```matlab
runMIDAS  % or: mcScriptRun()
```

**Expected**: Simulation runs for ~10-30 minutes, saves output to `./Outputs/`

---

## ✅ What Was Fixed

### Critical Issues Resolved:

1. **runMIDAS.m** - Added Override folder to path (enables Madagascar config loading)
2. **readParameters.m** - Fixed ruralUrbanTime inconsistency (now 0.15 consistently)
3. **createUtilityLayers.m** - Renamed old Senegal version to avoid conflict (see BUGFIX_SUMMARY.md)

### Files Created:

**Test Scripts** (run these to verify):
- `test_full_integration.m` ⭐ **Main test - run this first**
- `test_override_mechanism.m` - Verify Madagascar config will load
- `verify_config_data.m` - Inspect economic data
- `verify_spatial_cache.m` - Inspect spatial data
- `quick_test_madagascar.m` - Quick data checks (already existed, updated)

**Documentation**:
- `MADAGASCAR_INTEGRATION_REPORT.md` - **Full technical report**
- `QUICK_START_GUIDE.md` - This file

---

## 📊 What's In Your Model

**Spatial Data**: 44 locations (22 Madagascar regions × urban/rural)
- Analamanga_Rural/Urban
- Bongolava_Rural/Urban
- ... (all 22 regions)

**Economic Sectors**: 5 sectors
1. Ag_L1 (low-skill agriculture)
2. Ag_L2 (high-skill agriculture)  
3. For_L1 (low-skill formal sector)
4. For_L2 (high-skill formal sector)
5. School (education/training)

**Time Periods**: 40 timesteps (10 years × 4 quarters)

**Model Scale** (default):
- 100 agents
- 30 timesteps total (10 spinup + 20 main)
- ~10-30 minute runtime

---

## 🧪 Testing Your Installation

### Minimum Test (30 seconds):
```matlab
test_override_mechanism  % Verify Madagascar config will load
```

### Recommended Test (3 minutes):
```matlab
test_full_integration  % Full end-to-end verification
```

### Individual Component Tests (if needed):
```matlab
verify_config_data      % Check madagascar_config.mat
verify_spatial_cache    % Check Madagascar_44_UrbanRural_MIDAS.mat
test_buildWorld         % Test initialization only
```

---

## 📁 Key Files

### Data Files (Validated ✅):
- `madagascar_config.mat` (6.2 KB) - Economic/utility data
- `Madagascar_44_UrbanRural_MIDAS.mat` (187 KB) - Spatial data cache
- `Data/Madagascar_44_UrbanRural.shp` - Original shapefile

### Modified Files (Fixed ✅):
- `runMIDAS.m` - Added Override path
- `Application_Specific_MIDAS_Code/readParameters.m` - Fixed ruralUrbanTime

### Critical Override File:
- `Override_Core_MIDAS_Code/createUtilityLayers.m` - **Loads Madagascar config**

---

## 🎯 Expected Behavior

### Spatial Patterns:
- Agents gradually migrate toward urban locations (higher formal sector wages)
- Distance decay: shorter migrations more common
- Within-region movement (rural ↔ urban in same region) should be frequent

### Portfolio Choices:
- Most agents specialize in single sector
- Dual portfolios (farm + formal job) rare due to 15% transit penalty
- Young agents may attend school to access skilled jobs

### Temporal Dynamics:
- Agricultural income varies by season (Q2-Q3 harvest)
- Migration may increase in low-agriculture seasons
- Network effects: agents follow friends/family

---

## ⚙️ Adjusting Parameters

Edit `Application_Specific_MIDAS_Code/readParameters.m`:

**Scale**:
```matlab
modelParameters.numAgents = 100;        % Increase to 1000-10000 for production
modelParameters.numCycles = 5;          % Increase to 10-20 for longer runs
```

**Migration Costs**:
```matlab
mapParameters.movingCostPerMile = 0;    % Set to 5000-10000 to enable costs
modelParameters.ruralUrbanTime = 0.15;  % 15% time penalty (don't change)
```

**Behaviors**:
```matlab
modelParameters.aspirationsFlag = 1;         % 1=on, 0=off
modelParameters.placeAttachmentFlag = 0;     % 1=on, 0=off  
modelParameters.shockExperiment = 0;         % 0=none, 1=ag shock, 2=all sectors
```

---

## 📈 Running Batch Experiments

### Parameter Sensitivity:
```matlab
runMIDAS_Benchmarks_paramRangeTest  % Test parameter ranges
```

### Scenario Analysis:
```matlab
runMIDAS_Benchmarks_Narrative       % Baseline, hubs, shocks, etc.
```

### Shock Experiments:
```matlab
runMIDAS_Benchmarks_Shock_Memory    % Agriculture shocks with memory
runMIDAS_Benchmarks_Shock_Vis       % Shocks with visualization
```

**Note**: These use `parfor` and require MATLAB Parallel Computing Toolbox.

---

## 🐛 Troubleshooting

### Issue: Test fails with "Config missing utilityBaseLayers"
**Fix**: Check that `madagascar_config.mat` exists in root directory

### Issue: Test shows "Urban ag ≥ rural ag (unexpected)"
**Fix**: Config file may have wrong data - run `inspect_mat_octave.m` to verify

### Issue: All agents stay in one location
**Fix**: Check utility patterns with `test_full_integration.m`, verify Madagascar config loaded

### Issue: Simulation very slow (>1 hour)
**Fix**: Reduce `numAgents` to 100 in `readParameters.m`

### Issue: Error: "Undefined function createUtilityLayers"
**Fix**: Run `addpath(genpath(pwd))` in MATLAB

---

## 📚 More Information

**Full Technical Report**: `MADAGASCAR_INTEGRATION_REPORT.md`
- Detailed findings
- Data structure documentation
- Parameter recommendations
- Troubleshooting guide

**Original Documentation**: `ODD+D_MIDAS_Nov27_2018.pdf`
- Model conceptual design
- Agent decision algorithms
- Validation approach

---

## ✅ Success Checklist

Your installation is ready if:
- [ ] `test_full_integration` completes without errors
- [ ] Test shows "Urban formal > Rural formal" (config loaded)
- [ ] Test shows "Rural ag > Urban ag" (config loaded)
- [ ] 44 locations confirmed
- [ ] Distance matrix 44×44 confirmed
- [ ] Override mechanism active

If all checked → You're ready to run full simulations!

---

## 🤝 Support

**Created**: November 11, 2025  
**Integration verified**: All tests pass ✅  
**Ready for simulation**: YES ✅  

For issues, refer to:
1. This guide's troubleshooting section
2. `MADAGASCAR_INTEGRATION_REPORT.md` (comprehensive)
3. Test script outputs (detailed diagnostics)

---

**Happy Modeling! 🇲🇬**

