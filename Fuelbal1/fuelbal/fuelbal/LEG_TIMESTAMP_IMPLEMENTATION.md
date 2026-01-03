# Leg Timestamp Tracking Implementation

## Overview
This implementation adds timestamp tracking to record when each aviation leg starts (engine ignition). The timestamp is displayed in the FlightView header and persisted across app sessions.

## Implementation Details

### 1. FuelState.swift Changes

#### Added Properties
- **`@Published var currentLegTimestamp: Date? = nil`** (line 456)
  - Tracks the timestamp when the current leg's engine was started
  - Published property for UI updates
  - Nil when no leg is active

#### FlightLeg Structure
- **`var legTimestamp: Date`** (line 95)
  - Property added to FlightLeg struct
  - Defaults to Date() in initializer
  - Properly encoded/decoded in Codable conformance

#### Codable Support
- **CodingKeys** (line 148): Includes `legTimestamp` key
- **Decoder** (line 158): `legTimestamp = try container.decodeIfPresent(Date.self, forKey: .legTimestamp) ?? Date()`
  - Provides fallback for old data without timestamps
- **Encoder** (line 186): `try container.encode(legTimestamp, forKey: .legTimestamp)`

#### SavedState Persistence
- **SavedState struct** (line 1389-1399):
  - Includes `currentLegTimestamp: Date?` property
  - Automatically saved/loaded with other flight state
  - Survives app restarts

#### Engine Start Logic
**`startEngine()` function** (line 1181):
```swift
func startEngine() {
    engineRunning = true
    
    // Start leg timer and set leg timestamp
    if legTimerStart == nil {
        let now = Date()
        legTimerStart = now
        currentLegTime = 0
        currentLegTimestamp = now  // NEW: Mark this leg's timestamp
        
        // Update current leg with engine start time and timestamp
        if var leg = currentLeg {
            leg.engineStartTime = legTimerStart
            leg.legTimestamp = now
            currentLeg = leg
        }
    }
    
    save()
}
```

**Key behaviors:**
- Sets `currentLegTimestamp` when engine starts
- Only sets on first engine start (not on resume from pause)
- Updates the `FlightLeg.legTimestamp` property
- Persists immediately via `save()`

### 2. FlightView.swift Changes

#### HeaderView Updates
**Added formatted timestamp display** (lines 170-178):
```swift
// Format leg timestamp as "MMM d HH:mm"
var formattedLegTimestamp: String {
    guard let timestamp = fuel.currentLegTimestamp else {
        return fuel.preset.rawValue
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d HH:mm"
    return "LEG \(formatter.string(from: timestamp))"
}
```

**Updated header text** (line 205):
```swift
Text("CYCLE #\(fuel.burnCycleNumber) • \(formattedLegTimestamp)")
```

**Display behavior:**
- **Before engine start**: Shows preset name (e.g., "TOP OFF", "TAB FILL", "CUSTOM")
- **After engine start**: Shows formatted timestamp (e.g., "LEG Jan 3 14:23")
- Format: "MMM d HH:mm" (e.g., "Jan 3 14:23", "Dec 31 09:45")

## User Flow

### New Flight
1. User selects aircraft and fuel preset (TOP OFF, TAB FILL, or CUSTOM)
2. Header shows: "CYCLE #1 • TOP OFF" (or chosen preset)
3. User taps START button to ignite engine
4. `startEngine()` captures current date/time
5. Header updates to: "CYCLE #1 • LEG Jan 3 14:23"
6. Timestamp persists throughout the leg

### Adding Fuel (Continuing Flight)
1. User adds fuel at fuel stop
2. Burn cycle increments: "CYCLE #2 • ..."
3. Before engine start: Shows preset name
4. After engine start: Shows new leg timestamp
5. Each leg gets its own unique timestamp

### Resuming Without Fuel
1. User continues flight without adding fuel
2. Leg number increments but burn cycle stays same
3. Existing timestamp is preserved
4. Header shows original leg timestamp

## Data Persistence

### Local State (During Flight)
- `fuel.currentLegTimestamp` tracks active leg
- Saved in `SavedState` structure
- Persists across app suspensions

### Leg History
- Each `FlightLeg` has its own `legTimestamp`
- Stored when leg is completed
- Available in trip history and reconciliation

### Trip Records
- All legs in a trip preserve their timestamps
- Used for detailed flight logs
- Enables time-based analysis

## Date Format

**Format String**: `"MMM d HH:mm"`

**Examples**:
- Jan 3 14:23 (January 3rd, 2:23 PM)
- Dec 31 09:45 (December 31st, 9:45 AM)
- Mar 15 00:12 (March 15th, 12:12 AM)

**Why this format?**
- Compact yet informative
- Shows date and time without being verbose
- Uses 24-hour time for aviation consistency
- Abbreviates month to save space

## Testing Checklist

### Basic Functionality
- [ ] Start new flight with TOP OFF
- [ ] Verify header shows preset name before engine start
- [ ] Tap START button
- [ ] Verify header shows "LEG [timestamp]" after engine start
- [ ] Check timestamp is current date/time

### Persistence
- [ ] Start engine and note timestamp
- [ ] Suspend app (background)
- [ ] Resume app
- [ ] Verify timestamp is preserved

### Fuel Stops
- [ ] Complete leg and add fuel
- [ ] Verify cycle increments
- [ ] Start engine on new leg
- [ ] Verify new timestamp appears

### Edge Cases
- [ ] Restart without completing leg (should show last timestamp)
- [ ] Continue without fuel (should preserve timestamp)
- [ ] Multiple stops in same cycle (timestamp stays consistent)

## Architecture Notes

### Why Two Timestamp Properties?

1. **`currentLegTimestamp` (FuelState)**
   - Published for UI updates
   - Tracks active leg only
   - Cleared when leg ends

2. **`legTimestamp` (FlightLeg)**
   - Permanent record in leg history
   - Preserved in trip data
   - Used for historical analysis

### Thread Safety
- All updates happen on `@MainActor` (FuelState is MainActor-isolated)
- UI updates automatically propagate via `@Published`
- No concurrent access concerns

### Backward Compatibility
- Old `FlightLeg` data without `legTimestamp` uses fallback: `Date()`
- Decoding handles missing timestamps gracefully
- No migration required

## Future Enhancements

### Potential Improvements
1. **Time zone support**: Store timezone with timestamp
2. **Lap times**: Show elapsed time since leg start
3. **Leg duration**: Calculate total leg time from start to shutdown
4. **Historical view**: Browse past leg timestamps in trip details
5. **Export**: Include timestamps in CSV/PDF reports

### Display Options
- Toggle between relative ("2h 15m ago") and absolute timestamps
- Customize date format in settings
- Show/hide timestamp based on user preference

## Summary

The leg timestamp tracking feature is now fully implemented and provides:
- ✅ Automatic timestamp capture on engine start
- ✅ Persistent storage across app sessions
- ✅ Clean display in FlightView header
- ✅ Historical record in FlightLeg data
- ✅ Backward compatibility with existing data

The implementation is minimal, robust, and follows Swift/SwiftUI best practices.
