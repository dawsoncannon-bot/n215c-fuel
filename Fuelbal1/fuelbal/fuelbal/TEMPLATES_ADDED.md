# Aircraft Templates Added ✅

## Summary
Added **14 verified aircraft fuel configurations** to the template database based on POH-verified usable fuel data.

---

## CESSNA (3 templates)

### ✅ C172 Skyhawk (Late Models - S)
- **Usable**: 26.5 gal L / 26.5 gal R = **53 gal total**
- **Selector**: BOTH normally used (not true crossfeed)
- **Note**: Earlier models differ - verify POH

### ✅ C182 Skylane (Later Models)
- **Usable**: 44 gal L / 44 gal R = **88 gal total**
- **Selector**: BOTH available; some POHs specify for normal ops
- **Note**: Verify year

### ✅ C210 Centurion
- **Usable**: 45 gal L / 44 gal R = **89 gal total**
- **Selector**: L/R/OFF only (no BOTH)
- **Note**: Some versions use aux tanks that transfer (often to right)

---

## PIPER (8 templates)

### ✅ PA-28-140 Cherokee
- **Usable**: 18 gal L / 18 gal R = **36 gal total**
- **Selector**: L/R/OFF only (no BOTH)
- **Note**: Small unusable fuel varies by year

### ✅ PA-28-180 Cherokee
- **Usable**: 24 gal L / 24 gal R = **48 gal total**
- **Selector**: L/R/OFF only (no BOTH)
- **Note**: Verify early vs later POHs

### ✅ PA-28-181 Archer
- **Usable**: 24 gal L / 24 gal R = **48 gal total**
- **Selector**: L/R/OFF only (no BOTH)
- **Note**: Very consistent across fleet

### ✅ PA-28R-180 Arrow I (Hershey Bar Wing)
- **Usable**: 24 gal L / 24 gal R = **48 gal total**
- **Selector**: L/R/OFF only (no BOTH)
- **Note**: Same fuel logic as other PA-28s

### ✅ PA-28R-200 Arrow II (Hershey Bar Wing)
- **Usable**: 24 gal L / 24 gal R = **48 gal total**
- **Selector**: L/R/OFF only (no BOTH)
- **Note**: Wing planform does not change fuel logic

### ✅ PA-32-260 Cherokee Six (84 Gal - 4 Tanks)
- **Usable**: 17 gal L Tip / 25 gal L Main / 25 gal R Main / 17 gal R Tip = **84 gal total**
- **Selector**: Individual tank selection (no BOTH)
- **Note**: Slight unusable per tank varies by POH

### ✅ PA-32 Saratoga (Fixed Gear)
- **Usable**: 51 gal L / 51 gal R = **102 gal total**
- **Selector**: L/R/OFF only (no BOTH)
- **Note**: Some sources quote 107 total with ~5 unusable

### ✅ PA-32R-300 Lance (Retractable)
- **Usable**: 47 gal L / 47 gal R = **94 gal total**
- **Selector**: L/R/OFF only (no BOTH)
- **Note**: Retractable gear version of PA-32

---

## MOONEY (3 templates)

### ✅ M20C
- **Usable**: 24 gal L / 24 gal R = **48 gal total**
- **Selector**: L/R/OFF only (no BOTH)
- **Note**: Some docs list 52 total with ~4 unusable

### ✅ M20J
- **Usable**: 32 gal L / 32 gal R = **64 gal total**
- **Selector**: L/R/OFF only (no BOTH)
- **Note**: Very consistent across J models

### ✅ M20R Ovation
- **Usable**: 44.5 gal L / 44.5 gal R = **89 gal total**
- **Selector**: L/R/OFF only (no BOTH)
- **Note**: Confirm exact usable per POH and mods

---

## Key Observations

### Fuel Selector Patterns:
- **Cessna**: Typically has BOTH position (C172, C182)
  - Exception: C210 uses L/R/OFF
- **Piper PA-28 family**: All use L/R/OFF (no BOTH)
- **Piper PA-32**: Individual tank selection or L/R/OFF
- **Mooney**: All use L/R/OFF (no BOTH)

### Important Gotchas Captured:
1. **C210**: Aux tanks that transfer (often to right side)
2. **PA-32-260**: Individual tank selection, not just L/R
3. **C172/C182**: BOTH is not true crossfeed
4. **Variations by year**: Many models have POH differences across production years

### Still Needed (Placeholders):
- Beechcraft (A36 Bonanza variants)
- Cirrus (SR20, SR22)
- Other manufacturers as needed

---

## User Experience Flow

1. User taps "ADD NEW AIRCRAFT"
2. Taps "BROWSE FUEL CONFIG TEMPLATES"
3. Selects category (Cessna, Piper, Mooney)
4. Browses 14+ verified configurations
5. Taps template → auto-fills:
   - Manufacturer
   - Model
   - ICAO code
   - Fuel type
   - All tank capacities
6. User enters tail number
7. User can modify any pre-filled values
8. Saves their custom aircraft

---

## Testing Checklist

- [ ] Template browser shows all 14 templates
- [ ] Category filtering works (Cessna: 3, Piper: 8, Mooney: 3)
- [ ] Search finds templates by manufacturer/model
- [ ] Tapping template fills AddAircraftView correctly
- [ ] Tank capacities appear in correct fields
- [ ] Notes display properly on template cards
- [ ] User can still modify pre-filled values
- [ ] Saved aircraft appears on selection screen

---

## Next Steps

### Additional Templates to Consider:
1. **Beechcraft A36 Bonanza** (with/without tips)
2. **Cirrus SR20/SR22**
3. **Diamond DA40/DA42**
4. **Earlier C172 variants** (pre-S models)
5. **Piper PA-32 105 gal config** (if main/bladder breakdown available)

### Enhancement Ideas:
- Export templates as CSV for kneeboard reference
- Add column for "aux/tip/transfer behavior" flags
- Include gross weight and useful load for planning
- Add performance data (cruise speed, fuel burn)

---

## Template Count by Manufacturer

| Manufacturer | Templates | Coverage |
|--------------|-----------|----------|
| Cessna       | 3         | 172, 182, 210 |
| Piper        | 8         | PA-28 family (5), PA-32 family (3) |
| Mooney       | 3         | M20C, M20J, M20R |
| Beechcraft   | 0         | Awaiting data |
| Cirrus       | 0         | Awaiting data |
| **TOTAL**    | **14**    | **3 manufacturers** |

---

## Data Verification Status

✅ **All 14 templates verified from user-provided POH data**
- Usable fuel capacities confirmed
- Fuel selector behavior documented
- Important gotchas and variations noted
- Year/model differences flagged

🔄 **Awaiting data for**:
- Beechcraft models
- Cirrus models
- Additional variants of existing models
