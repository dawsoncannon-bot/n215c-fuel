# Bonanza Fuel System Deep Dive

## 🎯 Critical Rules (Burn Into Muscle Memory)

1. **NO Bonanza has a BOTH position**
2. **Tip tanks NEVER feed the engine directly**
3. **ALL tip fuel must be transferred to a main**
4. **You must manage tank balance manually**
5. **You can dump fuel overboard if you transfer too long**

---

## Template Coverage Added

### ✅ 11 Bonanza Configurations Now in Database

#### V-Tail Family (Model 35)
- ✅ **Standard (No Tips)** - 40 gal usable
- ✅ **With 20 Gal Tips** - 60 gal usable
- ✅ **With 40 Gal Tips** - 80 gal usable

#### Straight-Tail / Debonair (Model 33)
- ✅ **Standard (No Tips)** - 50 gal usable
- ✅ **With Tips** - 70-80 gal usable

#### Long-Body (A36 / G36)
- ✅ **Standard (No Tips)** - 74 gal usable
- ✅ **With 20 Gal Tips** - 94 gal usable
- ✅ **With 40 Gal Tips** - 114 gal usable

#### Turbo (B36TC)
- ✅ **Standard (No Tips)** - 74 gal usable
- ✅ **With Tips** - 110+ gal usable

---

## Fuel System Architecture

### All Bonanzas Use:
- **Selector**: LEFT / RIGHT / OFF (never BOTH)
- **Main Tanks**: Feed engine directly
- **Tip Tanks** (if installed): TRANSFER ONLY via electric pumps

### Transfer System Gotchas

| Issue | Why It Matters | Mitigation |
|-------|----------------|------------|
| **Transfer slower than burn** | Tips may empty before mains fill | Start transfers early; monitor constantly |
| **Must have room in main** | Main tank full = overboard venting | Never top off mains when planning tip usage |
| **Electrical pump dependency** | Pump failure = tip fuel unusable | Check electrical system; have backup plan |
| **No crossfeed** | Can't transfer L tip → R main | Must manage each side independently |
| **Manual balance required** | Imbalance affects handling | Discipline in transfer timing per side |

---

## Comparison to Other Complex Systems

### Bonanza vs C210
| Feature | Bonanza Tips | C210 Aux |
|---------|--------------|----------|
| Transfer destination | Any main (L or R) | Usually to RIGHT main |
| Transfer rate | Slower than burn (critical) | Varies by model |
| Overboard risk | HIGH if main full | MODERATE |
| Manual management | Required for balance | Less critical (aux to one side) |
| Pilot workload | VERY HIGH | HIGH |

### Bonanza vs PA-32 Cherokee Six (4-tank)
| Feature | Bonanza Tips | PA-32 4-Tank |
|---------|--------------|--------------|
| Tank selection | Transfer to mains first | DIRECT feed from any tank |
| Complexity | Transfer timing + balance | Tank selection discipline |
| Usability | Tips unusable if pump fails | All tanks directly usable |
| Overboard risk | HIGH | LOW |
| Pilot workload | VERY HIGH | MODERATE |

### Bonanza vs PA-28 / Mooney (Simple 2-Tank)
| Feature | Bonanza (With Tips) | Simple 2-Tank |
|---------|---------------------|---------------|
| Fuel sources | 4 tanks (2 feed, 2 transfer) | 2 tanks (both feed) |
| Selector complexity | L/R + transfer management | L/R/OFF only |
| Pre-flight planning | CRITICAL (transfer strategy) | Simple (just switch tanks) |
| In-flight workload | VERY HIGH | LOW |
| Failure modes | Pump failure, overboard vent | Minimal |

---

## Bonanza-Specific Planning Considerations

### V-Tail (Model 35) - 40/60/80 Gal Configs

**Standard (40 gal)**
- ✅ Simple: Just switch L/R
- ✅ No transfer management
- ❌ Limited range

**With 20 Gal Tips (60 gal)**
- ⚠️ Transfer planning required
- ⚠️ 20 gal tips = ~33% of total fuel is transfer-only
- 💡 Strategy: Burn mains down 10 gal each side before starting transfers

**With 40 Gal Tips (80 gal)**
- 🔴 Complex: 40 gal tips = **50% of fuel is transfer-only**
- 🔴 Transfer rate becomes **critical path** for mission
- 🔴 Must burn mains significantly before transfers
- 💡 Strategy: Target 10-12 gal remaining per main before transfer start

---

### Straight-Tail (Model 33) - 50/70 Gal Configs

**Standard (50 gal)**
- ✅ Larger mains than V-tail
- ✅ No transfer complexity
- ✅ Good for local/regional

**With Tips (70 gal)**
- ⚠️ Tips = ~29% of total fuel
- ⚠️ Electrical pump dependency
- 💡 Strategy: Imbalance risk if you favor one side during transfers

---

### Long-Body (A36/G36) - 74/94/114 Gal Configs

**Standard (74 gal)**
- ✅ Huge mains (37 gal each)
- ✅ Excellent simple-ops range
- ✅ No transfer workload

**With 20 Gal Tips (94 gal)**
- ⚠️ Tips = ~21% of total fuel (lowest percentage)
- ⚠️ But: Large mains = CG sensitivity with full fuel
- 💡 Strategy: Can out-range your bladder

**With 40 Gal Tips (114 gal)**
- 🔴 Tips = ~35% of total fuel
- 🔴 "Long transfers at altitude" = electrical load
- 🔴 Can easily dump fuel overboard
- 💡 Strategy: Never top off mains if planning tip usage

---

### Turbo (B36TC) - 74/110+ Gal Configs

**Standard (74 gal)**
- ⚠️ Higher fuel burn than NA
- ✅ No transfer complexity
- ✅ Good for fast missions

**With Tips (110+ gal)**
- 🔴 Turbo climb burn + tip transfer = **CRITICAL timing**
- 🔴 Must start transfers earlier than NA models
- 🔴 Electrical load higher (turbo systems + transfer pumps)
- 💡 Strategy: Transfer timing in climb is make-or-break

---

## Pre-Flight Planning Matrix

### Decision: Should You Fill Tips?

| Mission Profile | Fill Tips? | Why |
|-----------------|-----------|-----|
| Local (<100nm) | ❌ NO | Unnecessary complexity |
| Regional (100-300nm) | ⚠️ MAYBE | Only if mains insufficient; plan transfers |
| Cross-country (300-600nm) | ✅ YES | But requires disciplined transfer management |
| Maximum range | ✅ YES | No choice; be hyper-vigilant on transfers |

### Fuel Loading Strategy

| Tank Config | Loading Strategy | First Transfer Point |
|-------------|------------------|----------------------|
| V-Tail + 20 gal tips | Leave 10 gal airspace in each main | After 30-45 min cruise |
| V-Tail + 40 gal tips | Leave 12-15 gal airspace in each main | After 20-30 min cruise |
| A36 + 20 gal tips | Leave 5-7 gal airspace in each main | After 1 hr cruise |
| A36 + 40 gal tips | Leave 10-12 gal airspace in each main | After 30-45 min cruise |
| B36TC + tips | Leave 15+ gal airspace in each main | **Start in climb** |

---

## In-Flight Transfer Workflow

### Phase 1: Pre-Transfer Setup
1. ✅ Confirm electrical system normal
2. ✅ Note fuel remaining in both mains
3. ✅ Verify tip quantity
4. ✅ Ensure adequate airspace in selected main
5. ✅ Note time and fuel flow

### Phase 2: Transfer Execution
1. 🔄 Select tip transfer pump ON (L or R)
2. ⏱️ Monitor transfer rate (typically 5-10 gal/hr)
3. 👁️ Watch main tank gauge for filling
4. ⚠️ Set timer for 10-15 minutes
5. 🔄 Switch back to check tip quantity

### Phase 3: Balance Management
1. 📊 Compare L vs R main quantities
2. 🎯 Target: Keep within 5 gal of each other
3. 🔄 Alternate transfer sides as needed
4. 📝 Log transfer start/stop times
5. ⚠️ Never let one side get >10 gal ahead

### Phase 4: Final Tips Empty
1. ✅ Confirm both tips reading EMPTY
2. ✅ Turn off transfer pumps
3. ✅ Verify mains are balanced
4. ✅ Calculate remaining fuel vs destination
5. ✅ Return to simple L/R tank management

---

## Emergency Considerations

### Electrical Failure
- 🔴 **All tip fuel is now UNUSABLE**
- 🔴 Immediately recalculate range using MAINS ONLY
- 🔴 Declare emergency if insufficient fuel to destination
- 💡 This is why you NEVER plan tips for legal reserves

### Pump Failure (One Side)
- ⚠️ That side's tip fuel is unusable
- ⚠️ Will create fuel imbalance
- 💡 Can still transfer opposite side if pump works

### Overboard Venting Detected
- 🔴 STOP TRANSFERS IMMEDIATELY
- 🔴 You are dumping fuel and didn't mean to
- 🔴 Switch to appropriate main tank to burn down
- 💡 This happens when you transfer with full mains

---

## Workload Comparison Summary

### Simple Mission (Mains Only)
- **Pre-flight**: 5 minutes (standard fuel planning)
- **In-flight**: Switch L/R every 20-30 min
- **Workload**: LOW (same as PA-28 or Mooney)

### Complex Mission (With Tips)
- **Pre-flight**: 15-20 minutes (transfer strategy planning)
- **In-flight**: 
  - Monitor transfers every 10-15 min
  - Track quantities on 4 tanks
  - Manage balance constantly
  - Set multiple timers
- **Workload**: VERY HIGH (comparable to multi-engine fuel management)

---

## Why This Matters for Your App

### Current App Implications
1. Your app already handles **PA-32 4-tank** (individual selection)
2. Bonanza tips add a **new dimension**: Transfer-only tanks
3. Users need to track **TWO fuel states**:
   - Main tanks (feeding engine)
   - Tip tanks (transferring to mains)

### Potential App Enhancements
1. **Transfer tracking mode**
   - Log when transfer pumps are ON
   - Calculate transfer rate
   - Warn when main approaching full

2. **Balance calculator**
   - Show L vs R differential
   - Recommend which side to transfer next

3. **"Tips unusable" mode**
   - If electrical failure declared
   - Recalculate range using mains only

4. **Transfer planning worksheet**
   - Input: Trip fuel burn, tip quantity
   - Output: When to start transfers, which side first

---

## Next Steps

Would you like me to:

1. **Build transfer tracking into FuelState**
   - Add transfer pump state (L/R/OFF)
   - Track fuel transferred per side
   - Calculate transfer rates

2. **Create Bonanza-specific flight mode**
   - Separate UI for transfer management
   - Balance indicators
   - Transfer timer/alerts

3. **Add fuel system "complexity flags" to templates**
   - Simple (PA-28 style)
   - Individual selection (PA-32 style)
   - Transfer system (Bonanza/C210 style)
   - Then adapt UI based on aircraft type

4. **Build the "magic number" transfer table**
   - For each Bonanza config
   - "Start transfer when mains at X gallons"
   - "Stop transfer when tips at Y gallons"

Let me know which direction helps most! ✈️
