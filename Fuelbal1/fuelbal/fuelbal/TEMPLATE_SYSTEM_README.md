# Aircraft Template System - Implementation Summary

## ✅ What Was Built

### 1. **Clean Aircraft Selection View**
- Shows only **N215C** (your preset) and **custom aircraft** you create
- No flooding with dozens of presets
- Clean, focused user experience

### 2. **Template System (Separate from Presets)**
- **Templates** = Reference configurations for fuel systems
- **NOT displayed** on the main aircraft selection screen
- Accessed via "Browse Fuel Config Templates" button when adding aircraft

### 3. **New Files Created**

#### `AircraftTemplate.swift`
- `AircraftTemplate` struct: Contains verified fuel configurations
- `TemplateCategory` enum: Organizes by manufacturer (Cessna, Piper, Beechcraft, etc.)
- `AircraftTemplateLibrary`: Central repository for all templates
- Currently has **one verified template**: PA-32 Cherokee Six (84 gal, 4 tanks)
- **Placeholders** ready for your verified data

#### `TemplateBrowserView.swift`
- Beautiful browsing interface for templates
- Category filtering (Cessna, Piper, Beechcraft, Cirrus, Mooney, Other)
- Search functionality
- Shows full tank configuration for each template
- Displays capacity, ICAO, fuel type, and notes

### 4. **Updated `AddAircraftView.swift`**
- Added "BROWSE FUEL CONFIG TEMPLATES" button
- Tapping template auto-fills manufacturer, model, ICAO, fuel type, and all tank capacities
- User still enters their own tail number
- User can modify any pre-filled values

### 5. **Reverted `Aircraft.swift`**
- Back to just N215C as the only preset
- No flooding of preset array

---

## 🎯 How It Works

### User Flow:
1. **Aircraft Selection Screen**: Shows N215C + any custom aircraft
2. Tap **"ADD NEW AIRCRAFT"**
3. See **"BROWSE FUEL CONFIG TEMPLATES"** button
4. Browse templates by category (currently mostly placeholders)
5. Select template → auto-fills configuration
6. Enter tail number and modify if needed
7. Save → appears on aircraft selection screen

---

## 📋 Next Steps: Add Your Verified Data

### Template Structure Example:
```swift
AircraftTemplate(
    manufacturer: "Piper",
    model: "PA-32R Lance",
    variant: "105 Gal (2 Tanks)", // or "With Tip Tanks", "Standard", etc.
    icao: "PA32",
    fuelType: .avgas,
    tankConfig: [
        .lMain: 52.5,  // VERIFIED USABLE FUEL ONLY
        .rMain: 52.5
    ],
    notes: "Main and bladder combined per side"
)
```

### Templates Awaiting Your Data:

#### Piper:
- [ ] **PA-32 Cherokee Six** - 105 gal (2 tanks) - main/bladder breakdown
- [ ] **PA-32R Lance** - Different wing/fuel system
- [ ] PA-28 Warrior variants
- [ ] PA-28 Archer variants

#### Beechcraft:
- [ ] **A36 Bonanza** - Standard (no tips)
- [ ] **A36 Bonanza** - With tip tanks

#### Cessna:
- [ ] 172 Skyhawk (standard)
- [ ] 172 Skyhawk (long range)
- [ ] 182 Skylane variants
- [ ] 210 Centurion

#### Cirrus:
- [ ] SR20
- [ ] SR22

#### Mooney:
- [ ] M20 variants

---

## 🔧 Adding New Templates

Edit `AircraftTemplate.swift` → Find the appropriate category array → Add template:

```swift
private static let piperTemplates: [AircraftTemplate] = [
    // Existing PA-32 84 gal...
    
    // ADD YOUR NEW ONE:
    AircraftTemplate(
        manufacturer: "Piper",
        model: "PA-32 Cherokee Six",
        variant: "105 Gal (2 Tanks)",
        icao: "PA32",
        fuelType: .avgas,
        tankConfig: [
            .lMain: 52.5,  // YOUR VERIFIED NUMBER
            .rMain: 52.5   // YOUR VERIFIED NUMBER
        ],
        notes: "Optional description"
    ),
]
```

---

## 🎨 Key Design Decisions

1. **Presets ≠ Templates**
   - Presets = Your actual aircraft (N215C)
   - Templates = Reference library for creating new aircraft

2. **Verification Required**
   - Only add templates with POH-verified usable fuel capacities
   - Include variant info (tip tanks vs. no tips, different bladder configs)

3. **User Control**
   - Templates are suggestions, not forced
   - User can always enter manually
   - User can modify template-filled values

4. **Scalability**
   - Can add hundreds of templates without cluttering UI
   - Organized by category
   - Searchable

---

## 💬 Questions to Answer

When providing fuel configs, please specify:
- **Manufacturer & Model**
- **Variant** (e.g., "With Tip Tanks", "84 Gal Config")
- **ICAO code**
- **Fuel type** (AVGAS or JET-A)
- **USABLE gallons per tank** (not total capacity)
- **Tank positions** (L TIP, L MAIN, CENTER, R MAIN, R TIP, AFT)
- **Notes** (optional context)

Example format:
```
Beechcraft A36 Bonanza (With Tip Tanks)
ICAO: BE36
Fuel: AVGAS 100LL
Tanks:
  - L MAIN: 37 gal
  - R MAIN: 37 gal
  - L TIP: 10 gal
  - R TIP: 10 gal
Total: 94 gal usable
```
