# Phase 4: Function Naming Cleanup - COMPLETE

## Overview
Renamed `endTrip()` to `endLeg()` to match the correct domain model where legs are the primary unit, not trips.

---

## Changes Made

### 1. FuelState.swift - Function Rename

**Location:** Line ~1240

**Before:**
```swift
func endTrip() {
    // Finalize current leg if active
    if currentLeg != nil {
        endCurrentLeg()
    }
    // ... rest of implementation
}
```

**After:**
```swift
func endLeg() {
    // Finalize current leg if active
    if currentLeg != nil {
        endCurrentLeg()
    }
    // ... rest of implementation
}
```

**Note:** The internal logic remains exactly the same - only the function name changed.

---

### 2. FuelOptionsView.swift - Update Call Site

**Location:** Line ~239

**Before:**
```swift
// End Trip button
Button(action: {
    fuel.endTrip()
}) {
    Text("END TRIP")
    // ... button styling
}
```

**After:**
```swift
// End Trip button
Button(action: {
    fuel.endLeg()
}) {
    Text("END TRIP")
    // ... button styling
}
```

**Note:** Button label stays "END TRIP" for user familiarity, but internally calls `endLeg()`.

---

## Domain Model Clarification

### Correct Terminology

**Legs:**
- Primary unit of flight tracking
- Represents a segment of flying
- Can have multiple legs per trip
- Each leg has its own fuel state

**Burn Cycles:**
- Represents a fuel loading session
- Increments when fuel is added
- Multiple legs can share a burn cycle
- Tracked via `burnCycleNumber`

**Trips:**
- Collection of legs (future feature)
- Can span multiple days
- Contains historical data
- Currently not the primary tracking unit

---

## Verification: addFuel() Increments burnCycleNumber ✅

**Location:** `FuelState.swift`, line ~807

```swift
func addFuel(newTanks: [String: Double], pricePerGallon: Double? = nil, 
             totalCost: Double? = nil, location: String? = nil) {
    // Adding fuel starts a new burn cycle
    burnCycleNumber += 1  // ✅ CONFIRMED
    
    // End current leg first
    endCurrentLeg()
    
    // ... rest of implementation
}
```

**Confirmed:** ✅ `addFuel()` correctly increments `burnCycleNumber`

---

## Function Naming Summary

### Renamed Functions
| Old Name | New Name | Purpose |
|----------|----------|---------|
| `endTrip()` | `endLeg()` | End current leg and clear flight state |

### Kept Functions (No Change)
| Function | Purpose | Why Kept |
|----------|---------|----------|
| `cancelFlight()` | Cancel active flight | Internal helper, not user-facing |
| `clearFlight()` | Clear all flight data | Internal helper, not user-facing |
| `startFlight()` | Start new leg with fuel preset | Accurate - starts a flight leg |
| `addFuel()` | Add fuel and continue | Accurate - adds fuel to existing leg |
| `resumeWithoutFuel()` | Continue without adding fuel | Accurate - resumes leg |
| `endCurrentLeg()` | Finalize current leg data | Accurate - internal leg management |

---

## Call Sites Updated

### Direct Calls to endLeg()
1. ✅ **FuelOptionsView.swift** - "END TRIP" button (line ~239)

### No Changes Needed
- ❌ No calls in `shutdown()` - ends via `endCurrentLeg()`
- ❌ No calls in `cancelFlight()` - ends via `endCurrentLeg()`
- ❌ No other direct calls found

**Note:** The function is primarily called from the UI "END TRIP" button.

---

## User Experience

### Button Label
**Kept as "END TRIP"** for user clarity:
- Users think in terms of "trips" (journeys)
- "END LEG" might be confusing to pilots
- Internal naming is correct (`endLeg()`), but UI uses familiar terminology

### Behavior
When user taps "END TRIP":
1. Current leg is finalized via `endCurrentLeg()`
2. Trip is archived (if one exists)
3. All flight state is cleared
4. App returns to aircraft selection

**Result:** Clean slate for next flight

---

## Domain Model Alignment

### Before Phase 4 (Confused)
- Function named `endTrip()` but actually ended leg
- Unclear what "trip" meant in context
- Terminology didn't match implementation

### After Phase 4 (Clear)
- Function named `endLeg()` matches what it does
- Legs are primary unit (correct)
- Burn cycles tracked separately (correct)
- Trips are historical collections (correct)

---

## Implementation Details

### What endLeg() Does

1. **Finalize Current Leg**
   ```swift
   if currentLeg != nil {
       endCurrentLeg()
   }
   ```

2. **Archive Trip (if exists)**
   ```swift
   if var trip = currentTrip {
       trip.endDate = Date()
       archiveTrip(trip)
   }
   ```

3. **Clear Flight State**
   ```swift
   currentTrip = nil
   showFlightView = false
   engineRunning = false
   preset = .topoff
   customFuel = [:]
   currentTank = "lMain"
   swapLog = []
   tankBurned = ["lTip": 0, "lMain": 0, "rMain": 0, "rTip": 0]
   phase = .mains
   fuelExhausted = false
   flightMode = nil
   swap2Targets = nil
   ```

4. **Persist Changes**
   ```swift
   save()
   ```

---

## Testing Checklist

### ✅ Basic Functionality
- [ ] Start new flight
- [ ] Perform some tank swaps
- [ ] Tap "END TRIP" button
- [ ] Verify flight ends and data is saved
- [ ] Verify return to aircraft selection screen

### ✅ Data Persistence
- [ ] Start flight and make swaps
- [ ] Tap "END TRIP"
- [ ] Check that leg data is saved to open legs
- [ ] Verify swap log is preserved

### ✅ Multi-Leg Scenario
- [ ] Start flight (Leg 1)
- [ ] Perform swaps
- [ ] Add fuel (starts Leg 2, Burn Cycle 2)
- [ ] Perform more swaps
- [ ] Tap "END TRIP"
- [ ] Verify both legs are saved
- [ ] Verify burn cycle numbers are correct

### ✅ State Reset
- [ ] End trip
- [ ] Start new flight
- [ ] Verify burn cycle resets to #1
- [ ] Verify all tanks start fresh
- [ ] Verify no old data carries over

---

## Files Modified

| File | Lines | Changes |
|------|-------|---------|
| `FuelState.swift` | ~1240 | Renamed `endTrip()` → `endLeg()` |
| `FuelOptionsView.swift` | ~239 | Updated call from `fuel.endTrip()` → `fuel.endLeg()` |

---

## No Breaking Changes

✅ **Internal rename only:**
- Function signature unchanged (no parameters)
- Logic unchanged (exact same implementation)
- Only 1 call site to update
- No database schema changes
- No data migration needed

---

## Documentation Files

For related documentation, see:
- **`LEG_TIMESTAMP_IMPLEMENTATION.md`** - Leg timestamp tracking (Phase 2)
- **`PHASE3_SWAP_ENTRY_VERIFICATION.md`** - SwapEntry enhancements (Phase 3)
- **`SWAP_ENTRY_TIME_TRACKING.md`** - Time tracking in swap entries
- **`PHASE4_FUNCTION_NAMING.md`** - This document (Phase 4)

---

## Future Considerations

### Trip vs Leg Terminology

**Current State:**
- Legs are tracked individually
- Trips are future collections of legs
- UI uses "trip" terminology for user familiarity

**Future Enhancement:**
- True trip management (multi-leg trips)
- Trip planning features
- Trip-level analytics
- Trip cost summaries

**Why This Matters:**
- Internal code now uses correct terminology (`endLeg()`)
- External UI can maintain user-friendly language ("END TRIP")
- When true trip features are added, naming will be consistent

---

## Summary

### ✅ Phase 4 Complete

**What Changed:**
- ✅ Renamed `endTrip()` → `endLeg()`
- ✅ Updated call in FuelOptionsView
- ✅ Verified `addFuel()` increments `burnCycleNumber`

**What Stayed the Same:**
- ✅ Function logic unchanged
- ✅ UI labels unchanged ("END TRIP" button)
- ✅ User experience unchanged
- ✅ Data structures unchanged

**Result:**
- ✅ Correct domain model naming
- ✅ Clear distinction: legs vs burn cycles vs trips
- ✅ Ready for future trip management features
- ✅ Code is more maintainable and understandable

---

## Build & Test

**Ready to build!** 🚀

```bash
⌘ + B   # Build
⌘ + R   # Run and test
```

**Test the "END TRIP" button:**
1. Start new flight
2. Perform tank swaps
3. Tap "END TRIP" button
4. Verify flight ends correctly
5. Verify data is saved

**Everything should work exactly as before, with cleaner internal naming!** ✨
