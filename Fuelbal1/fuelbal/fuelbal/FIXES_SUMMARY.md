# Bug Fixes and UX Improvements Summary

## Date: January 2, 2026

### Issues Fixed

#### 1. **Auto-Decimal Formatting for Input Fields** ✅
- **Problem**: Input fields didn't automatically format decimal places, leading to inconsistent data entry
- **Solution**: Created `DecimalTextField` component with smart decimal formatting
  - **Gallon quantities**: Automatically format to 1 decimal place
  - **Dollar values**: Automatically format to 2 decimal places
  - Real-time filtering to prevent invalid input
  - Auto-formats on blur (when field loses focus)
- **Files Modified**:
  - `AddAircraftView.swift` - Tank capacity fields now use 1 decimal place
  - `FuelOptionsView.swift` - All fuel and cost entry fields formatted properly
    - Price per gallon: 2 decimals
    - Total cost: 2 decimals
    - Gallons added: 1 decimal

#### 2. **"LOCATION" Changed to "NOTES"** ✅
- **Problem**: Field labeled "LOCATION" in fuel stop with saved state was confusing
- **Solution**: Changed label to "NOTES" to match the new flight cost entry panel
- **Location**: `AddFuelOptionsPanel` in `FuelOptionsView.swift`
- **Placeholder text**: Changed to "KLAS, FBO, etc." for clarity

#### 3. **Enlarged Buttons and Input Fields** ✅
- **Problem**: NewFlightCostEntryPanel fields and buttons were too small and easy to accidentally dismiss
- **Solution**: Increased sizes throughout for better touch targets and usability
  - **NewFlightCostEntryPanel**:
    - Font sizes increased from 9pt → 10pt (labels), 14pt → 16pt (inputs)
    - Padding increased from 8px → 10px (horizontal), 8px → 12px (vertical)
    - Button height increased from 12pt → 16pt
    - Corner radius increased from 8 → 10
    - Stroke width increased from 1 → 1.5
  - **AddFuelOptionsPanel**:
    - Quick-fill buttons: 11pt → 12pt fonts, 12px → 14px padding
    - Input fields: 12pt → 14pt fonts, padding increased
    - Buttons: minHeight 44 → 48, fontSize 13pt → 14pt, cornerRadius 8 → 10
    - Stroke width increased to 1.5

#### 4. **"Keep Flying" Bug Fixed** ✅
- **Problem**: When selecting "KEEP FLYING" without adding fuel:
  - Totalizer was resetting to 0
  - Previous tank swaps were wiped
  - Fuel burn progress was lost
  - Only the leg number was supposed to change
- **Root Cause**: `resumeWithoutFuel()` was calling `endCurrentLeg()` and creating a new leg from scratch, resetting all state
- **Solution**: Modified `resumeWithoutFuel()` in `FuelState.swift` to:
  - **NOT** end the current leg
  - **NOT** reset swap log, tankBurned, currentTank, phase, totalizer
  - **ONLY** increment leg number
  - **PRESERVE** all flight state (fuel burn, swaps, current tank, phase, mode, targets)
  - Update leg start time while maintaining all existing progress
- **Result**: When continuing without fuel:
  - Totalizer continues from last reading ✅
  - Swap log preserved ✅
  - Tank burn progress preserved ✅
  - Current tank maintained ✅
  - Flight phase maintained ✅
  - Only leg number increments ✅

### Technical Implementation Details

#### DecimalTextField Component
```swift
struct DecimalTextField: View {
    @Binding var text: String
    let placeholder: String
    let decimalPlaces: Int
    let font: Font
    let foregroundColor: Color
    
    @FocusState private var isFocused: Bool
    
    // Features:
    // - Filters input to numbers and decimal point only
    // - Prevents multiple decimal points
    // - Limits decimal places during typing
    // - Auto-formats with proper decimals on blur
}
```

#### Usage Examples
```swift
// For gallon quantities (1 decimal)
DecimalTextField(
    text: $gallonsAdded,
    placeholder: "45.2",
    decimalPlaces: 1,
    font: .system(size: 16, weight: .bold, design: .monospaced),
    foregroundColor: .accentText
)

// For dollar amounts (2 decimals)
DecimalTextField(
    text: $pricePerGallon,
    placeholder: "6.50",
    decimalPlaces: 2,
    font: .system(size: 16, weight: .bold, design: .monospaced),
    foregroundColor: .accentText
)
```

### Testing Checklist

- [ ] Test "Keep Flying" preserves totalizer reading
- [ ] Test "Keep Flying" preserves swap log
- [ ] Test "Keep Flying" preserves fuel burn progress
- [ ] Test "Keep Flying" only increments leg number
- [ ] Test decimal formatting on gallon fields (1 decimal)
- [ ] Test decimal formatting on dollar fields (2 decimals)
- [ ] Test auto-format on blur for all DecimalTextField instances
- [ ] Test enlarged buttons are easier to tap
- [ ] Test "NOTES" field appears in saved fuel state add fuel panel
- [ ] Test NewFlightCostEntryPanel is less sensitive to accidental dismissal

### Files Modified
1. `FuelState.swift` - Fixed `resumeWithoutFuel()` logic
2. `FuelOptionsView.swift` - Added DecimalTextField, enlarged panels, changed LOCATION → NOTES
3. `AddAircraftView.swift` - Added DecimalTextField for tank capacity fields

### User Benefits
- ✅ Consistent decimal formatting prevents data entry errors
- ✅ Larger touch targets reduce accidental dismissals and mis-taps
- ✅ "Keep Flying" now works correctly, preserving flight progress
- ✅ Better field labeling (NOTES vs LOCATION) improves clarity
- ✅ Professional auto-formatting improves perceived app quality
