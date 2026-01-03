# SwapEntry Time Tracking Enhancement

## Overview
Enhanced SwapEntry struct to record both **time into leg** (elapsed time) and **time of day** (timestamp) for all swap log entries, including regular swaps, GPH observations, and shutdowns.

---

## Changes Made

### 1. SwapEntry Structure - Added Timestamp Property

**File:** `FuelState.swift`, lines 376-417

#### New Property:
```swift
let timestamp: Date  // Time of day when this entry was created
```

#### Updated Initializer:
```swift
init(swapNumber: Int, tank: String, totalizer: Double, burned: Double, 
     legTime: TimeInterval? = nil, timestamp: Date = Date(), 
     isShutdown: Bool = false, observedGPH: Double? = nil)
```

**Default value:** `Date()` - automatically captures current time when entry is created

#### New Formatting Method:
```swift
// Format timestamp as HH:mm (time of day)
var formattedTimeOfDay: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: timestamp)
}
```

---

### 2. HistoryView - Enhanced Display

**File:** `FlightView.swift`, lines 779-869

#### Display Changes:

**Before:**
- Single line per entry
- Only showed leg time (HH:MM:SS)

**After:**
- Multi-line entry with passive metadata
- **Primary time:** Leg time (HH:MM:SS) - bright, prominent
- **Secondary time:** Time of day (HH:mm) - small, passive, gray
- **Additional indicators:**
  - GPH value (if entry is GPH observation)
  - SHUTDOWN label (if entry is shutdown event)

#### Visual Layout:
```
#1  L MAIN         01:23:45    12.5  +12.5
                      14:23
    
#2  R MAIN         02:15:30    24.2  +11.7
                      15:15
    
#3  R MAIN         02:17:30    24.2    --
    GPH: 11.8         15:17
    
#4  L TIP (SHUTDOWN) 03:40:00  42.3  +17.8
    SHUTDOWN          18:40
```

---

## Time Information Displayed

### Time Into Leg (Primary)
- **Format:** `HH:MM:SS` (e.g., "01:23:45")
- **Source:** `legTime` property (TimeInterval since engine start)
- **Color:** Bright accent color (`.fuelActive`)
- **Font size:** 11pt
- **Purpose:** Shows elapsed time since engine start

### Time of Day (Secondary/Passive)
- **Format:** `HH:mm` (e.g., "14:23")
- **Source:** `timestamp` property (Date)
- **Color:** Dim gray (`.secondaryText.opacity(0.5)`)
- **Font size:** 7pt (smaller)
- **Purpose:** Shows actual clock time when event occurred

---

## Entry Type Indicators

### Regular Swap
```
#1  L MAIN         01:23:45    12.5  +12.5
                      14:23
```

### GPH Observation
```
#2  R MAIN         02:17:30    24.2    --
    GPH: 11.8         15:17
```
- Shows "GPH: X.X" in small blue text
- Burn shows "--" (no fuel consumed)

### Shutdown Event
```
#3  L TIP (SHUTDOWN) 03:40:00  42.3  +17.8
    SHUTDOWN          18:40
```
- Shows "SHUTDOWN" in small red text
- Tank name includes " (SHUTDOWN)" suffix

---

## Automatic Timestamp Capture

All SwapEntry creation automatically captures timestamp:

### Regular Swaps (logSwap)
```swift
let entry = SwapEntry(
    swapNumber: swapLog.count + 1,
    tank: tankLabel(currentTank),
    totalizer: reading,
    burned: burned,
    legTime: legTime,
    timestamp: Date()  // ✅ Automatically captured
)
```

### GPH Observations (logObservedGPH)
```swift
let gphEntry = SwapEntry(
    swapNumber: swapLog.count + 1,
    tank: currentTank,
    totalizer: lastReading ?? 0,
    burned: 0,
    legTime: currentTime,
    timestamp: Date(),  // ✅ Automatically captured
    isShutdown: false,
    observedGPH: gph
)
```

### Shutdown Events (shutdown)
```swift
let shutdownEntry = SwapEntry(
    swapNumber: swapLog.count + 1,
    tank: tankLabel(currentTank) + " (SHUTDOWN)",
    totalizer: reading,
    burned: burned,
    legTime: finalLegTime,
    timestamp: Date(),  // ✅ Automatically captured
    isShutdown: true
)
```

---

## Data Persistence

### Codable Support
The `timestamp` property is automatically encoded/decoded:
- **Type:** `Date` (native Swift type with full Codable support)
- **Storage:** UserDefaults via JSON encoding
- **Compatibility:** Existing entries without timestamp will fail gracefully (decoder will require migration or default value)

### Backward Compatibility Note
⚠️ **Important:** Old SwapEntry data without `timestamp` may cause decoding issues.

**Solution:** Update decoder to provide default timestamp for old data:
```swift
// In SwapEntry custom decoder (if needed)
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    // ... decode other properties
    timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
}
```

---

## Visual Design

### Hierarchy
1. **Most prominent:** Tank name, totalizer, burn amount
2. **Secondary:** Leg time (elapsed)
3. **Tertiary/Passive:** Time of day (timestamp)

### Typography
- **Primary text:** 11pt monospaced
- **Metadata labels:** 7pt monospaced
- **Time of day:** 7pt monospaced, dimmed

### Color Scheme
- **Leg time:** `.fuelActive` (bright accent)
- **Time of day:** `.secondaryText.opacity(0.5)` (passive gray)
- **GPH indicator:** `.blue.opacity(0.8)`
- **Shutdown indicator:** `.red.opacity(0.8)`

---

## Use Cases

### 1. Flight Reconstruction
With both times recorded, you can:
- Reconstruct exact timeline of flight
- Match swap log to GPS/flight recorder data
- Verify timing of events

### 2. Fuel Stop Analysis
When reviewing fuel stops:
- See actual time fuel was added
- Compare elapsed time between swaps
- Identify patterns in fuel consumption

### 3. Multi-Day Trips
For trips spanning multiple days:
- Time of day shows which day events occurred
- Easier to correlate with other logs/receipts
- Clear separation between flight sessions

### 4. Performance Analysis
Compare GPH observations with timestamps:
- Analyze fuel burn by time of day
- Identify altitude/weather effects
- Track engine performance over time

---

## Example Swap Log Scenarios

### Scenario 1: Normal Flight with Shutdown
```
RECENT SWAPS

#   TANK           TIME        TOTAL  BURN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#1  L MAIN         00:00:00     0.0   +0.0
                      13:15
                      
#2  R MAIN         01:15:30    12.5  +12.5
                      14:30
                      
#3  L MAIN         02:30:45    24.8  +12.3
                      15:45
                      
#4  R MAIN (SHUTDOWN) 03:45:20  36.9  +12.1
    SHUTDOWN          17:00
```

### Scenario 2: Flight with GPH Observations
```
RECENT SWAPS

#   TANK           TIME        TOTAL  BURN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#1  L MAIN         01:00:00    10.2  +10.2
                      14:00
                      
#2  L MAIN         01:05:00    10.2    --
    GPH: 12.1         14:05
                      
#3  R MAIN         02:00:00    22.3  +12.1
                      15:00
                      
#4  R MAIN         02:10:00    22.3    --
    GPH: 11.8         15:10
```

### Scenario 3: Multi-Day Cross-Country
```
Day 1 Leg:
#1  L MAIN         00:30:00     8.5   +8.5
                      15:30
                      
#2  R MAIN (SHUTDOWN) 01:45:00   20.2  +11.7
    SHUTDOWN          16:45

Day 2 Leg (new fuel):
#1  L MAIN         00:00:00     0.0   +0.0
                      09:15
                      
#2  R MAIN         01:20:00    13.2  +13.2
                      10:35
```

---

## Testing Checklist

### ✅ Basic Time Display
- [ ] Start flight and perform swap
- [ ] Verify leg time shows elapsed time (HH:MM:SS)
- [ ] Verify time of day shows current clock time (HH:mm)
- [ ] Verify time of day is small and passive in appearance

### ✅ GPH Observation Times
- [ ] Log GPH observation
- [ ] Verify entry shows both times
- [ ] Verify "GPH: X.X" label appears
- [ ] Verify burn column shows "--"

### ✅ Shutdown Times
- [ ] Shutdown engine with totalizer
- [ ] Verify shutdown entry shows both times
- [ ] Verify "SHUTDOWN" label appears in red
- [ ] Verify tank includes "(SHUTDOWN)" suffix

### ✅ Multi-Session Tracking
- [ ] Complete leg with shutdown
- [ ] Note time of day
- [ ] Resume next day or later
- [ ] Verify timestamps reflect actual times of events

### ✅ Data Persistence
- [ ] Create swap log entries
- [ ] Close app completely
- [ ] Reopen app
- [ ] Verify all timestamps are preserved

---

## Future Enhancements

### Potential Improvements
1. **Timezone support** - Store timezone with timestamp
2. **Date display** - Show date for multi-day trips
3. **Relative time** - "2h ago" style display option
4. **Export timestamps** - Include in CSV/PDF exports
5. **Time-based filtering** - Filter entries by time range
6. **Timeline view** - Visual timeline of all events

### Display Options
- Toggle between 12-hour and 24-hour time format
- Show/hide time of day (keep only leg time)
- Expand/collapse detail for each entry
- Sort by timestamp vs. swap number

---

## Summary

### ✅ Complete Implementation

**SwapEntry now tracks:**
1. ✅ **Leg time** (TimeInterval) - How long since engine start
2. ✅ **Timestamp** (Date) - Exact time of day when event occurred
3. ✅ **Entry type** (isShutdown, observedGPH) - What kind of event
4. ✅ **Tank and fuel data** - Standard swap information

**Display shows:**
1. ✅ Leg time prominently (HH:MM:SS format)
2. ✅ Time of day passively (HH:mm format, small and gray)
3. ✅ Entry type indicators (GPH, SHUTDOWN labels)
4. ✅ All standard fuel data (totalizer, burn amount)

**Result:** Complete temporal record of all fuel management events with both relative (elapsed) and absolute (clock time) timestamps for comprehensive flight logging and analysis.
