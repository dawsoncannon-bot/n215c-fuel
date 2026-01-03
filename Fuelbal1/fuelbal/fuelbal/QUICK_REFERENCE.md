# Quick Reference Card: Fuel Management HUD

## At a Glance

### Three Key Numbers

```
┌─────────────────────────────────────┐
│  16:42  ← Time until you MUST swap │
│  11.2   ← What you're ACTUALLY burning │
│  11.8   ← What instrument SHOWS    │
└─────────────────────────────────────┘
```

---

## Quick Actions

| Action | When | How |
|--------|------|-----|
| **Start Timer** | Before takeoff | Press START ENGINE |
| **Log First GPH** | After climbout | Tap OBSERVED → Enter GPH |
| **Update GPH** | Power change | Tap OBSERVED → Enter new GPH |
| **Tank Swap** | Countdown at 0:00 | Log totalizer → Swap selector |
| **Stop Timer** | After landing | Press STOP ENGINE or SHUTDOWN |

---

## Understanding the Display

### Average GPH (Left Box)
```
AVG GPH
  11.2          ← Historical: What you've burned
ACTUAL BURN
```
- Calculated from totalizer readings
- Updates as you log swaps
- Compare to POH/expected values

### Observed GPH (Right Box)
```
OBSERVED
  11.8          ← Current: What instrument shows
INSTRUMENT
```
- **Tap to enter** current fuel flow
- Updates countdown timer
- Can update anytime

### Countdown Timer (Top, Large)
```
⏱️  TIME TO SWAP
     16:42      ← Minutes:Seconds until swap
Based on observed GPH
```
- Green = Normal (> 5 min)
- Orange = Urgent (< 5 min)
- Disappears after swap

---

## Typical Flight Flow

### 1. Engine Start
```
✓ Press START ENGINE
✓ Timer shows 00:00:00
✓ Observed GPH shows "TAP"
```

### 2. Takeoff & Climbout (High Power)
```
✓ Wheels up
✓ 1000' AGL
✓ Tap OBSERVED
✓ Enter: 18.0 GPH
✓ Countdown appears: ~16:00
```

### 3. Cruise (Normal Power)
```
✓ Level off
✓ Reduce power
✓ Tap OBSERVED
✓ Enter: 11.8 GPH
✓ Countdown updates: ~20:00
```

### 4. Monitor
```
✓ Watch countdown decrease
✓ Plan swap around waypoints
✓ Note when < 5:00 (orange)
```

### 5. Tank Swap
```
✓ At 0:00 (or when convenient)
✓ Read totalizer
✓ Log swap (e.g., 7.2)
✓ Switch tank selector
✓ Countdown disappears
✓ Log new GPH for new tank
```

### 6. Repeat
```
✓ Continue steps 2-5 for each tank
✓ Average GPH stabilizes over flight
```

### 7. Shutdown
```
✓ Final totalizer reading
✓ Press SHUTDOWN
✓ Timer stops
✓ All data saved
```

---

## Color Guide

| Color | Meaning | Where |
|-------|---------|-------|
| 🟢 **Green** | Active, normal | Countdown (>5min), Observed GPH |
| 🟠 **Orange** | Warning | Countdown (<5min) |
| 🔴 **Red** | Critical | Empty tanks |
| 🔵 **Blue** | Historical | Average GPH |
| ⚪ **Gray** | Inactive | Paused, disabled |

---

## Warning Signs

### ⚠️ Prepare to Swap (< 5 Minutes)
```
⚠️  TIME TO SWAP
     04:23
⚠️ PREPARE TO SWAP
```
**Action:** Plan your swap

### 🛑 Zero Fuel Warning
```
🛑 ZERO FUEL
   0.0
```
**Action:** Swap immediately

### ⚠️ Do Not Exceed
```
⚠️ DO NOT EXCEED
     7.3
```
**Action:** Swap at or before this reading

---

## Pro Tips

### 1. Update GPH Frequently
- **Climbout**: High GPH (~18)
- **Cruise climb**: Medium GPH (~13)
- **Level cruise**: Low GPH (~11)
- More updates = better predictions

### 2. Compare Numbers
```
AVG: 11.2   OBS: 11.8
         ↑
    Close = Good calibration
    Far apart = Check instruments
```

### 3. Plan Swaps Strategically
- Don't wait for 0:00
- Swap before:
  - Entering traffic pattern
  - Starting approach
  - Complex airspace
  - IMC conditions

### 4. Trust the Math
- Countdown accounts for:
  - Variable burn rates
  - Safety reserves
  - Multiple GPH changes
- It's smarter than mental math!

### 5. Track Patterns
- Note typical GPH for:
  - Climbout
  - Cruise at different altitudes
  - Different power settings
- Build your personal profiles

---

## Troubleshooting

### "Countdown shows --:--"
**Problem:** No GPH logged  
**Fix:** Tap OBSERVED → Enter GPH

### "Countdown seems wrong"
**Problem:** Old/stale GPH data  
**Fix:** Update OBSERVED with current reading

### "Can't see countdown"
**Problem:** Not enough fuel in tank  
**Fix:** Normal - tank may be too low

### "Timer not running"
**Problem:** Engine not started  
**Fix:** Press START ENGINE

### "After swap, no countdown"
**Problem:** GPH log cleared (expected)  
**Fix:** Log GPH for new tank

---

## Data You Get

### Per Leg
- Total engine time (HH:MM:SS)
- Engine start/stop times
- Fuel burned
- Average GPH
- Swap timestamps

### Per Swap
- Exact time of swap
- Tank switched to
- Fuel burned
- Totalizer reading

### Per Flight
- All leg data
- Total fuel consumed
- Cost data (if entered)
- Historical trends

---

## Keyboard Shortcuts

| Input | Accept | Range |
|-------|--------|-------|
| **Totalizer** | Any value ≥ last | 0-999.9 |
| **Observed GPH** | 0.1-99.9 | Typical: 8-20 |

---

## Memory Aids

**"3 Numbers Tell the Story"**
1. **Time** = When to act
2. **Average** = What happened
3. **Observed** = What's happening

**"Update on Changes"**
- Power change → Update GPH
- Altitude change → Update GPH
- Long cruise → Update periodically

**"Orange = Attention"**
- < 5 min warning
- Plan your swap now

**"Swap Resets GPH"**
- New tank = New predictions
- Always log GPH after swap

---

## Integration with Existing Features

### Works With:
- ✅ Swap targets (still shown)
- ✅ Tank gauges (still displayed)
- ✅ History (now includes timestamps)
- ✅ Trip tracking (includes timer data)
- ✅ Fuel reconciliation (more accurate)

### Replaces:
- ❌ Manual countdown math
- ❌ Guessing swap times
- ❌ Uncertainty about burn rates

### Enhances:
- ✨ Decision making
- ✨ Fuel planning
- ✨ Safety margins
- ✨ Post-flight analysis

---

## One-Page Cheat Sheet

```
┌──────────────────────────────────────────────────┐
│  FUEL MANAGEMENT HUD QUICK START                 │
├──────────────────────────────────────────────────┤
│  1. START ENGINE                                 │
│     ↓                                             │
│  2. TAP "OBSERVED"                               │
│     ↓                                             │
│  3. ENTER CURRENT GPH                            │
│     ↓                                             │
│  4. WATCH COUNTDOWN                              │
│     ↓                                             │
│  5. UPDATE GPH ON POWER CHANGES                  │
│     ↓                                             │
│  6. SWAP WHEN COUNTDOWN REACHES 0:00             │
│     ↓                                             │
│  7. LOG TOTALIZER & NEW GPH                      │
│     ↓                                             │
│  8. REPEAT FOR EACH TANK                         │
│     ↓                                             │
│  9. SHUTDOWN → DATA SAVED                        │
└──────────────────────────────────────────────────┘

COLORS:
🟢 Green = Normal     🟠 Orange = Warning (< 5 min)
🔵 Blue = Historical  ⚪ Gray = Inactive

KEY INSIGHT:
More GPH updates = More accurate predictions
Update when power settings change!
```

---

## Support

**Questions?** Check:
- `FUEL_MANAGEMENT_HUD.md` - Detailed explanation
- `LEG_TIMER_FEATURE.md` - Timer specifics
- `IMPLEMENTATION_SUMMARY.md` - Technical details
- `UI_MOCKUP.md` - Visual reference

**Remember:** The system does the complex math. You just need to:
1. Log GPH when it changes
2. Swap when countdown says to
3. Trust the predictions!

Happy (and safe) flying! ✈️
