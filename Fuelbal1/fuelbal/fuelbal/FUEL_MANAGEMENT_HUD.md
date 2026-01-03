# Fuel Management HUD Feature

## Overview
The Fuel Management HUD provides real-time predictive fuel management through a combination of historical burn data (Average GPH) and live instrument observations (Observed GPH). This creates a sophisticated countdown-to-swap timer that adapts to changing flight conditions.

## Key Components

### 1. Average GPH (Historical Data)
**Calculation:**
```swift
Average GPH = Total Fuel Burned ÷ Engine Run Time (hours)
```

**Data Source:**
- Uses totalizer readings logged during tank swaps
- Tracks actual time elapsed since engine start
- Provides historical perspective on actual fuel consumption

**Display:**
- Shows current average GPH based on all fuel burned since engine start
- Updates automatically as flight progresses
- Labeled "AVG GPH - ACTUAL BURN"

**Use Case:**
- Compare predicted vs. actual burn rates
- Verify fuel flow gauge accuracy
- Post-flight analysis of fuel consumption

---

### 2. Observed GPH (Predictive Data)
**Input Method:**
- Tap the "OBSERVED" field to open input sheet
- Enter current GPH reading from aircraft fuel flow instrument
- Can be updated as many times as needed during flight

**Purpose:**
- Provides real-time prediction based on current conditions
- Adapts to changing phases of flight (climbout vs. cruise)
- More accurate than static burn rates

**Display:**
- Shows most recent observed GPH value
- Green highlight when active
- Labeled "OBSERVED - INSTRUMENT"

---

### 3. Countdown-to-Swap Timer

#### Overview
The countdown timer predicts when you should swap tanks based on:
1. Current fuel remaining in active tank
2. Safety reserve (0.9 gallons)
3. Observed GPH history with piecewise calculation

#### Advanced Calculation

The timer uses a **piecewise burn rate calculation** that accounts for changing GPH throughout the flight:

```
For each GPH observation segment:
  - Calculate time spent at that GPH
  - Calculate fuel burned during that segment
  - Accumulate total burn

Remaining fuel to burn = Available fuel - Already burned
Time to swap = Remaining fuel ÷ Current observed GPH
```

**Example Scenario:**

```
Leg Start: L MAIN has 25 gallons available (24.1 after safety reserve)

00:03:00 - Climbout phase
  User logs Observed GPH: 18.0
  Timer starts calculating...
  
00:10:00 - Level off, reduce power
  User logs Observed GPH: 12.5
  Timer recalculates:
    - 7 minutes at 18 GPH = 2.1 gal burned
    - Remaining: 24.1 - 2.1 = 22.0 gal
    - Time to swap: 22.0 ÷ 12.5 = 1.76 hours = 1:45:36
    
00:25:00 - Cruise established
  User logs Observed GPH: 11.8
  Timer recalculates:
    - Previous burn: 2.1 gal
    - Last 15 min at 12.5 GPH = 3.125 gal
    - Total burned: 5.225 gal
    - Remaining: 24.1 - 5.225 = 18.875 gal
    - Time to swap: 18.875 ÷ 11.8 = 1.6 hours = 1:36:00
```

#### Piecewise Burn Calculation

The system maintains a log of all observed GPH entries with timestamps:

```swift
struct ObservedGPHEntry {
    let timestamp: Date
    let legTime: TimeInterval  // When observation was made
    let observedGPH: Double    // GPH value at that time
}
```

**Algorithm:**
1. Iterate through all GPH observations since last swap
2. For each segment between observations:
   - Calculate duration of segment
   - Apply that segment's GPH to calculate fuel burned
   - Accumulate total burn
3. For current segment (after last observation):
   - Use most recent GPH
   - Calculate from last observation to now
4. Subtract total burn from available fuel
5. Predict remaining time at current GPH

**Why This Matters:**
- **Climbout accuracy**: High initial GPH doesn't throw off entire calculation
- **Adaptive predictions**: Timer adjusts as you change power settings
- **Multiple updates**: Each new GPH observation refines the prediction
- **Historical integrity**: Previous burn segments are preserved with their actual GPH

---

### 4. Display States

#### Active Countdown (Normal)
```
┌──────────────────────────────────┐
│    ⏱️  TIME TO SWAP              │
│        16:42                     │
│   Based on observed GPH          │
└──────────────────────────────────┘
```
- Large green numbers
- Shows MM:SS format
- Updates every second

#### Urgent Warning (< 5 minutes)
```
┌──────────────────────────────────┐
│  ⚠️  TIME TO SWAP                │
│        04:23                     │
│   ⚠️ PREPARE TO SWAP            │
└──────────────────────────────────┘
```
- Orange color scheme
- Warning icon
- Thicker border
- Orange background tint
- "PREPARE TO SWAP" message

#### No Prediction (No GPH Data)
```
┌──────────────────────────────────┐
│  OBSERVED                        │
│    TAP                           │
│  INSTRUMENT                      │
└──────────────────────────────────┘
```
- Gray "TAP" text
- Prompts user to enter first GPH observation
- Countdown timer doesn't appear until GPH is logged

---

### 5. Behavior on Tank Swap

When you log a tank swap:
1. **Observed GPH log is cleared** - Fresh start for new tank
2. **Countdown timer resets to 0** - No prediction yet
3. **User must log new GPH** - Appropriate for new tank's fuel state
4. **Average GPH continues** - Still calculated from total burn / total time

**Why Clear GPH Log?**
- Different tanks may have different fuel levels
- Different phase of flight (tips vs. mains)
- Pilot might use different power settings
- Fresh predictions are more accurate than stale data

---

## UI Layout

### In-Flight HUD Structure

```
┌─────────────────────────────────────────┐
│  Header (Leg #, Total Fuel, Engine)    │
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐ │
│  │ ⏱️  TIME TO SWAP      16:42       │ │  ← COUNTDOWN TIMER
│  │  Based on observed GPH            │ │     (top, prominent)
│  └───────────────────────────────────┘ │
│                                         │
│  ┌─────────────┐  ┌─────────────────┐ │
│  │  AVG GPH    │  │  OBSERVED       │ │  ← HUD DISPLAYS
│  │   11.2      │  │   11.8          │ │     (side by side)
│  │ ACTUAL BURN │  │  INSTRUMENT     │ │
│  └─────────────┘  └─────────────────┘ │
│                                         │
│  🕐 LEG TIME: 01:23:45                 │  ← Leg timer (compact)
├─────────────────────────────────────────┤
│  Phase Indicator                        │
│  Tank Gauges                            │
│  Swap Targets                           │
│  Input Section                          │
│  History                                │
└─────────────────────────────────────────┘
```

---

## Usage Workflow

### Pre-Flight
1. Start flight and engine
2. HUD appears with "TAP" on Observed GPH field
3. Average GPH shows "--" (no burn data yet)

### Climbout
1. Pilot taps "OBSERVED" field
2. Enters current GPH from instrument (e.g., 18.5)
3. Countdown timer appears showing predicted time to swap
4. Example: "18:23" (18 minutes 23 seconds)

### Level Off / Power Reduction
1. Pilot notices GPH decrease on instrument
2. Taps "OBSERVED" again
3. Enters new GPH (e.g., 12.8)
4. Timer recalculates, showing more time remaining
5. Example: "23:45" (23 minutes 45 seconds)

### Cruise
1. Power settings stabilize
2. Pilot updates observed GPH one more time (e.g., 11.5)
3. Timer shows final prediction
4. Average GPH begins to converge with observed GPH

### Approaching Swap Time
1. Countdown reaches < 5:00
2. Display turns orange
3. Warning triangle appears
4. "⚠️ PREPARE TO SWAP" message shown

### Tank Swap
1. Pilot logs totalizer reading and swaps tank
2. Countdown timer disappears
3. Observed GPH clears (shows "TAP" again)
4. Average GPH updates with new burn data
5. Process repeats for new tank

---

## Technical Details

### Data Persistence
All GPH observations and timer state are saved:
- `observedGPHLog: [ObservedGPHEntry]` - All GPH observations for current tank
- `predictedTimeToSwap: TimeInterval` - Current countdown value
- Saved to UserDefaults with flight state
- Preserved across app restarts

### Timer Update Mechanism
```swift
// Every 1 second:
1. Update leg timer (currentLegTime)
2. Call updateCountdownTimer()
   a. Calculate piecewise burn
   b. Determine remaining fuel
   c. Predict time to swap at current GPH
   d. Update predictedTimeToSwap
```

### Safety Considerations
- Always accounts for 0.9 gallon safety reserve
- Timer reaches 0:00 when safety reserve is reached
- Does not allow burning below safety reserve
- Urgent warning at 5 minutes provides buffer

### Edge Cases Handled
1. **No GPH observations** - Timer doesn't show (requires at least one)
2. **Insufficient fuel** - Timer shows 0:00 immediately
3. **Tank swap** - Clears observations (fresh predictions)
4. **Engine stop** - Timer pauses, preserves state
5. **Invalid GPH** - Input validation prevents < 0 or > 100 GPH

---

## Benefits

### 1. Adaptive Accuracy
Unlike static burn rate calculations, this system:
- Adapts to actual flight conditions
- Handles climbout vs. cruise differences
- Responds to power setting changes
- Provides increasingly accurate predictions

### 2. Proactive Management
Pilots can:
- See exact time remaining before swap
- Plan swaps around traffic patterns, checkpoints, etc.
- Receive advance warning (5-minute alert)
- Reduce cognitive load during critical phases

### 3. Data-Driven Decisions
Comparing Average GPH vs. Observed GPH reveals:
- Instrument accuracy
- Fuel flow gauge calibration
- Actual vs. expected performance
- Engine efficiency variations

### 4. Training Tool
- Teaches fuel management principles
- Demonstrates impact of power settings on burn rate
- Builds pilot proficiency in fuel planning
- Provides immediate feedback

---

## Future Enhancements

Potential additions:
1. **GPH History Graph** - Visualize GPH changes over time
2. **Auto-GPH Detection** - Integration with external fuel flow sensors
3. **Predictive Alerts** - "Consider climbing now for better efficiency"
4. **Burn Rate Profiles** - Save typical GPH patterns for common routes
5. **Multi-Tank Preview** - Show predicted swap times for all tanks
6. **Wind Correction** - Adjust predictions based on groundspeed
7. **Altitude Compensation** - Factor in density altitude effects

---

## Example Flight

**Scenario: KPHX → KSLC (500 nm, 3.5 hours)**

```
00:00:00 - Engine Start, L MAIN (25 gal)
00:00:30 - Takeoff, wheels up
00:03:00 - 1000 AGL, Log GPH: 18.0
           Timer: 16:12 (based on high climbout burn)

00:08:00 - Level at 8,500', reduce power
           Log GPH: 13.5
           Timer: 19:34 (recalculated, more time)

00:15:00 - Cruise established
           Log GPH: 11.8
           Timer: 20:08 (stable prediction)

00:30:00 - Timer: 05:24, still green
00:33:00 - Timer: 02:24, turns ORANGE
           "⚠️ PREPARE TO SWAP"

00:35:12 - Swap to R MAIN
           Log Totalizer: 7.2 gal
           Average GPH shows: 12.3 (actual)
           Observed: TAP (ready for new input)

00:36:00 - Cruise on R MAIN
           Log GPH: 11.6
           Timer: 21:45 (fresh prediction)

[Process continues through flight...]

03:32:45 - Shutdown at KSLC
           Total burn: 43.2 gal
           Average GPH: 12.2 (entire flight)
```

**Post-Flight Analysis:**
- Climbout: ~18 GPH (as expected)
- Cruise: ~11.7 GPH average (efficient)
- Multiple GPH updates provided accurate swap timing
- No fuel surprises, smooth operations

---

## Summary

The Fuel Management HUD transforms fuel management from reactive to **proactive**. By combining historical burn data with real-time observations, pilots gain:

✅ **Accurate predictions** that adapt to flight conditions  
✅ **Early warnings** to plan swaps strategically  
✅ **Data insights** comparing predicted vs. actual performance  
✅ **Reduced workload** through automation and clear guidance  
✅ **Enhanced safety** with countdown alerts and safety reserves  

This system handles the mathematical complexity while providing simple, actionable information: **"16:42 until you need to swap tanks."**
