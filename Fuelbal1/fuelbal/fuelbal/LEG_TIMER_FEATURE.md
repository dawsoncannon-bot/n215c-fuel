# Leg Timer Feature

## Overview
The leg timer feature tracks elapsed engine time for each flight leg and timestamps each tank swap relative to engine start. This provides valuable data for fuel consumption analysis and helps pilots understand their fuel burn patterns over time.

## Key Components

### 1. Timer Tracking in `FuelState`
- **`legTimerStart: Date?`** - Timestamp when engine was started for current leg
- **`currentLegTime: TimeInterval`** - Current elapsed time since engine start (in seconds)
- **`formattedLegTime: String`** - Computed property that formats time as `HH:MM:SS`

### 2. Enhanced Data Structures

#### `SwapEntry`
Each tank swap now includes:
- **`legTime: TimeInterval?`** - Time elapsed since engine start when swap was logged
- **`formattedLegTime: String`** - Formatted timestamp as `HH:MM:SS`

#### `FlightLeg`
Each leg now tracks:
- **`engineStartTime: Date?`** - When engine was started
- **`engineStopTime: Date?`** - When engine was stopped
- **`totalEngineTime: TimeInterval?`** - Total engine run time for the leg
- **`formattedEngineTime: String`** - Formatted total time as `HH:MM:SS`

## Behavior

### Engine Start
When the pilot presses **START ENGINE**:
1. Timer starts from 00:00:00
2. `legTimerStart` is set to current time
3. Leg timer display appears in UI
4. Engine start time is recorded in current leg

### During Flight
- Timer updates every second while engine is running
- Each tank swap captures the current leg time
- Swap history shows timestamp for each swap

### Engine Stop
When the pilot presses **STOP ENGINE** or **SHUTDOWN**:
1. Timer stops
2. Total engine time is calculated and saved to leg
3. Timer display remains visible but stops updating
4. "ENGINE STOPPED" indicator appears
5. All swap timestamps are preserved

### New Leg
When continuing flight (add fuel or resume without fuel):
- Timer resets to 00:00:00 when engine starts
- Previous leg's timer data is preserved in history
- New swaps get new timestamps relative to new leg start

## UI Components

### Leg Timer Display (`LegTimerView`)
Appears below the header when engine is running or after engine stop:
- **Large time display** - Shows current leg time in `HH:MM:SS` format
- **Color coding**:
  - Green (`.fuelActive`) when engine running
  - Gray (`.secondaryText`) when engine stopped
- **Status indicator** - "ENGINE STOPPED" appears when timer is paused

### Enhanced History View
Swap history now includes:
- **Swap number** - Sequential swap number
- **Tank** - Which tank was active
- **Time** - Timestamp when swap occurred (HH:MM:SS)
- **Total** - Totalizer reading
- **Burn** - Fuel burned on that swap

## Use Cases

### 1. Fuel Burn Rate Analysis
Pilots can see exactly when each tank swap occurred, allowing calculation of:
- Gallons per hour burn rate between swaps
- Time spent on each tank
- Total engine run time vs. totalizer reading

### 2. Flight Leg Documentation
Each leg includes complete timing data:
- Engine start/stop times
- Total engine run time
- Individual swap timestamps

### 3. Pattern Recognition
Over multiple flights, pilots can identify:
- Typical burn rates at different phases of flight
- Climbout fuel consumption patterns
- Cruise efficiency variations

### 4. Reconciliation
When comparing tracked fuel vs. actual fuel receipts:
- Timer data helps verify burn calculations
- Provides context for any fuel discrepancies
- Helps identify measurement errors

## Example Scenario

**Leg #1 - Flight from KPHX to KSLC**

1. **Engine Start (00:00:00)**
   - Pilot starts engine
   - Timer begins
   - Burning L MAIN

2. **Swap #1 (00:07:23)**
   - Switch to R MAIN after climbout
   - 7.0 gal burned
   - Timestamp: 00:07:23

3. **Swap #2 (01:17:45)**
   - Switch to L MAIN
   - 10.2 gal burned
   - Timestamp: 01:17:45

4. **Swap #3 (02:27:12)**
   - Switch to R MAIN
   - 10.0 gal burned
   - Timestamp: 02:27:12

5. **Engine Shutdown (03:32:45)**
   - Final reading logged
   - Total leg time: 03:32:45
   - All swap timestamps preserved

**Analysis:**
- Average burn rate: ~2.8 gph across all tanks
- Climbout phase: 7.0 gal in 7.4 minutes = ~57 gph (expected high rate)
- Cruise phase: More consistent ~10 gal per hour

## Data Persistence

All timer data is:
- Saved to UserDefaults with current flight state
- Encoded in `FlightLeg` objects for trip history
- Preserved across app restarts
- Available for historical analysis

## Technical Implementation

### Timer Updates
- UI timer updates every 1 second via `Timer.scheduledTimer`
- Timer starts when `FlightView` appears
- Timer stops when `FlightView` disappears
- Updates only occur when engine is running

### Time Calculations
```swift
// Calculate elapsed time
let elapsed = Date().timeIntervalSince(legTimerStart)

// Format as HH:MM:SS
let hours = Int(elapsed) / 3600
let minutes = (Int(elapsed) % 3600) / 60
let seconds = Int(elapsed) % 60
return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
```

### Backwards Compatibility
- All timer fields are optional (`TimeInterval?`)
- Legacy legs without timer data will show `--:--:--`
- App continues to function normally if timer data is missing

## Future Enhancements

Potential additions to the timer feature:
1. **Pause/Resume** - Allow pilot to pause timer during ground operations
2. **Hobbs vs. Timer** - Compare leg timer to aircraft Hobbs meter
3. **Flight Time Logs** - Export timer data for logbook entries
4. **Burn Rate Warnings** - Alert if burn rate exceeds expected values
5. **Timer Splits** - Mark intermediate timestamps (waypoints, etc.)
6. **Multi-leg Totals** - Show cumulative time across all legs in a trip
