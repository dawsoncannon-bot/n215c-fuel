# Tank Order and Starting Tank Fix

## 🐛 Issues Fixed

### Issue 1: Tank Display Order Was Wrong
**Problem**: Tanks displayed alphabetically (lMain, lTip, rMain, rTip)
**Correct**: Should display by physical position (lTip, lMain, rMain, rTip)

**File**: `FlightView.swift`
**Fix**: Added `tankOrder()` function with explicit ordering
```swift
private func tankOrder(_ key: String) -> Int {
    switch key {
    case "lTip": return 0
    case "lMain": return 1
    case "center": return 2
    case "rMain": return 3
    case "rTip": return 4
    case "aft": return 5
    default: return 999
    }
}
```

### Issue 2: Starting on Wrong Tank
**Problem**: Flight started on first tank in array (lTip after ordering fix)
**Correct**: Should always start on MAINS, never tips

**File**: `FuelState.swift`
**Fix**: Added `determineStartingTank()` function with priority logic:
1. L MAIN (preferred)
2. R MAIN
3. CENTER
4. First available (fallback)

## ✅ Cherokee Six Burn Pattern Logic

### Correct Operational Procedure:
1. **Start on L MAIN** (or R MAIN)
2. **Burn mains** until empty/low
3. **Switch to tips** only when necessary
4. **Alternate between sides** for balance

### Why This Matters:
- **Safety**: Mains are primary fuel source
- **CG Management**: Tips affect weight distribution
- **Fuel Management**: Simpler to manage mains first
- **POH Compliance**: Follows manufacturer procedures

### PA-32 Cherokee Six (4-tank) Specifics:
- **84 gal total**: 17 L tip, 25 L main, 25 R main, 17 R tip
- **No BOTH position**: Individual tank selector
- **Burn pattern**: Alternate mains first, then tips as needed
- **Phase**: Starts in "mains" phase, transitions to "tips" when appropriate

## 🎯 Testing Checklist

### Tank Display:
- [ ] PA-32 shows: L TIP | L MAIN | R MAIN | R TIP
- [ ] PA-28 (2-tank) shows: L MAIN | R MAIN
- [ ] Order matches physical aircraft layout

### Starting Tank:
- [ ] PA-32 starts on L MAIN (not L TIP)
- [ ] PA-28 starts on L MAIN
- [ ] C172 starts on L MAIN
- [ ] All aircraft start on main tanks

### Burn Logic:
- [ ] Can't select tips until mains phase complete
- [ ] Phase indicator shows "MAINS" at start
- [ ] Swap targets calculate correctly
- [ ] Tank selection respects phase

## 📝 Implementation Notes

**Tank ordering is critical for**:
- Visual clarity (matches aircraft diagram)
- User comprehension (left to right, outboard to inboard)
- Fuel planning (tips are auxiliary/extended range)

**Starting tank selection ensures**:
- Operational safety (use primary tanks first)
- POH compliance (follow manufacturer procedures)
- Predictable behavior (always same starting point)

---

## 🔧 Related Files Modified

1. **FlightView.swift** - Tank display ordering
2. **FuelState.swift** - Starting tank selection logic

Both changes ensure the app matches real-world PA-32 Cherokee Six operations! ✈️
