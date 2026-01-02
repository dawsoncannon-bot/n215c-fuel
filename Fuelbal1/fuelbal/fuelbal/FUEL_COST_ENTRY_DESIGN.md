# Flexible Fuel Cost Entry - Design Recommendations

## 🎯 The Problem

**Different receipts provide different information:**

1. **Full-service FBO receipt**:
   - ✅ Gallons added: 45.2
   - ✅ Price/gallon: $6.26
   - ✅ Subtotal: $282.95
   - ✅ Taxes/fees: $8.50
   - ✅ **Total: $291.45**

2. **Self-serve pump receipt**:
   - ✅ **Total paid: $291.45**
   - ❌ No itemization
   - ❌ No price/gallon shown

3. **Handwritten receipt / Venmo payment**:
   - ✅ **"Paid John $300 for fuel"**
   - ❌ No gallons
   - ❌ No breakdown

4. **Fuel card statement**:
   - ✅ Price/gallon: $6.26
   - ✅ **Total: $291.45**
   - ❓ Maybe gallons, maybe not

---

## 💡 **Recommended Solution: Auto-Calculate Missing Values**

### Core Principle:
**Enter what you have → System calculates the rest**

### Three Entry Patterns:

#### Pattern 1: **Price/Gal + Gallons** → Calculate Total
```
User enters:
  $/GAL: $6.26
  GALLONS: 45.2 (added automatically since we know preset)
  
System calculates:
  TOTAL: $282.95 (base)
  
User can override:
  TOTAL: $291.45 (adds $8.50 for taxes/fees)
```

#### Pattern 2: **Total Only** → Calculate Price/Gal
```
User enters:
  TOTAL: $291.45
  GALLONS: 45.2 (known from preset)
  
System calculates:
  $/GAL: $6.45 (effective price including taxes)
```

#### Pattern 3: **Price/Gal + Total** → Verify Against Gallons
```
User enters:
  $/GAL: $6.26
  TOTAL: $291.45
  GALLONS: 45.2 (known)
  
System validates:
  Expected base: $282.95
  Taxes/fees: $8.50 (difference)
  Effective $/gal: $6.45
```

---

## 🎨 **UI Design Recommendation**

### Option A: **Smart Auto-Calculate with Clear Hierarchy** (RECOMMENDED)

```
╔═══════════════════════════════════════════╗
║ FUEL COST (OPTIONAL) - TOP OFF           ║
║                                           ║
║ [$/GAL: $6.26]  [TOTAL: $291.45]        ║
║                                           ║
║ 💡 Added 45.2 gal (from TOP OFF preset)  ║
║    Effective: $6.45/gal (incl. taxes)    ║
║                                           ║
║ [NOTES: KLAS Signature, self-serve...]   ║
║                                           ║
║ [Skip] [Start]                            ║
╚═══════════════════════════════════════════╝
```

**Benefits:**
- ✅ Enter either $/gal OR total (or both)
- ✅ System shows calculated effective rate
- ✅ Clear what gallons are being tracked
- ✅ Taxes/fees captured in total
- ✅ No redundant "gallons" field (we already know from preset)

---

### Option B: **Tab-Based Entry Modes**

```
╔═══════════════════════════════════════════╗
║ FUEL COST (OPTIONAL) - TOP OFF           ║
║                                           ║
║ [By Price] [By Total] [Full Receipt]     ║
║                                           ║
║ ┌─ BY TOTAL ────────────────────────┐    ║
║ │                                    │    ║
║ │  TOTAL PAID: $291.45              │    ║
║ │                                    │    ║
║ │  💡 45.2 gal → $6.45/gal          │    ║
║ │                                    │    ║
║ └────────────────────────────────────┘    ║
║                                           ║
║ [NOTES: KLAS Signature...]                ║
║ [Skip] [Start]                            ║
╚═══════════════════════════════════════════╝
```

**Modes:**
1. **By Price**: Enter $/gal → Calculates total (can override)
2. **By Total**: Enter total → Calculates effective $/gal
3. **Full Receipt**: Enter both → Shows breakdown

**Benefits:**
- ✅ Explicit choice of entry method
- ✅ Focused UI per mode
- ✅ Clear mental model

**Drawbacks:**
- ❌ Extra tap to switch modes
- ❌ More complex UI

---

### Option C: **Single Smart Field with Inline Calculation** (SIMPLEST)

```
╔═══════════════════════════════════════════╗
║ FUEL COST (OPTIONAL) - TOP OFF           ║
║                                           ║
║ ┌─────────────────────────────────────┐  ║
║ │ $/GAL: $6.26                        │  ║
║ │ ────────────────────────────────    │  ║
║ │ TOTAL: $291.45                      │  ║
║ │                                      │  ║
║ │ 45.2 gal • Effective: $6.45/gal     │  ║
║ │ (includes $8.50 taxes/fees)         │  ║
║ └─────────────────────────────────────┘  ║
║                                           ║
║ [NOTES: Airport, FBO, etc...]             ║
║ [Skip] [Start]                            ║
╚═══════════════════════════════════════════╗
```

**Smart Logic:**
- Leave $/gal blank → Calculates from total ÷ gallons
- Leave total blank → Calculates from $/gal × gallons
- Fill both → Shows difference as taxes/fees
- Fill neither → Both optional, skip cost tracking

**Benefits:**
- ✅ No mode switching
- ✅ Enter what you have, skip the rest
- ✅ Always shows effective rate
- ✅ Simplest UX

---

## 🔧 **Implementation Details**

### Data Model Enhancement

```swift
struct FuelStop: Codable {
    var fuelAdded: [String: Double]      // Per tank
    var pricePerGallon: Double?          // Base price (from receipt)
    var totalCost: Double?               // Total paid (incl. taxes)
    var effectivePricePerGallon: Double? // NEW: Calculated from total ÷ gallons
    var taxesAndFees: Double?            // NEW: Difference between base and total
    var notes: String?
    var postFuelLevels: [String: Double]?
    
    // NEW: Total gallons added (for easy access)
    var totalGallonsAdded: Double {
        fuelAdded.values.reduce(0, +)
    }
    
    // NEW: Calculate effective price from total
    var calculatedEffectivePrice: Double? {
        guard let total = totalCost, totalGallonsAdded > 0 else { return nil }
        return total / totalGallonsAdded
    }
    
    // NEW: Calculate taxes/fees if both prices provided
    var calculatedTaxesAndFees: Double? {
        guard let base = pricePerGallon, 
              let effective = effectivePricePerGallon else { return nil }
        return (effective - base) * totalGallonsAdded
    }
}
```

### Calculation Logic

```swift
// In NewFlightCostEntryPanel

var calculatedTotal: Double? {
    guard let price = Double(pricePerGallon) else { return nil }
    return price * fuelAmount
}

var calculatedPricePerGallon: Double? {
    guard let total = Double(totalCost) else { return nil }
    return total / fuelAmount
}

var taxesAndFees: Double? {
    guard let base = Double(pricePerGallon),
          let total = Double(totalCost) else { return nil }
    let baseTotal = base * fuelAmount
    return total - baseTotal
}

var effectivePrice: Double? {
    // If total provided, use it for effective price
    if let total = Double(totalCost) {
        return total / fuelAmount
    }
    // Otherwise use base price
    return Double(pricePerGallon)
}

var summaryText: String {
    if let price = Double(pricePerGallon), let total = Double(totalCost) {
        let baseTotal = price * fuelAmount
        let fees = total - baseTotal
        return String(format: "%.1f gal @ $%.2f/gal = $%.2f + $%.2f fees = $%.2f", 
                      fuelAmount, price, baseTotal, fees, total)
    } else if let total = Double(totalCost) {
        let effective = total / fuelAmount
        return String(format: "%.1f gal • $%.2f total → $%.2f/gal effective", 
                      fuelAmount, total, effective)
    } else if let price = Double(pricePerGallon) {
        let total = price * fuelAmount
        return String(format: "%.1f gal @ $%.2f/gal = $%.2f", 
                      fuelAmount, price, total)
    } else {
        return String(format: "%.1f gal added", fuelAmount)
    }
}
```

---

## 🎯 **Final Recommendation: Option C + Smart Feedback**

### Updated UI:

```swift
struct NewFlightCostEntryPanel: View {
    let fuelAmount: Double
    let presetName: String
    @Binding var pricePerGallon: String
    @Binding var totalCost: String
    @Binding var notes: String
    let onStart: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            Text("FUEL COST (OPTIONAL) - \(presetName)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(2)
            
            // Smart cost fields
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    // Price per gallon
                    VStack(alignment: .leading, spacing: 4) {
                        Text("$/GAL")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        
                        HStack(spacing: 2) {
                            Text("$")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondaryText)
                            TextField("6.50", text: $pricePerGallon)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.accentText)
                                .keyboardType(.decimalPad)
                                .frame(width: 45)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(6)
                    }
                    .frame(width: 70)
                    
                    // Total cost
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        
                        HStack(spacing: 2) {
                            Text("$")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondaryText)
                            TextField("352", text: $totalCost)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.accentText)
                                .keyboardType(.decimalPad)
                                .frame(width: 50)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(6)
                    }
                    .frame(width: 80)
                    
                    // Smart calculation display
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BREAKDOWN")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        
                        Text(calculationSummary)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.accentText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(6)
                }
                
                // Helper hint
                Text("Enter price OR total (or both to track taxes)")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.secondaryText.opacity(0.6))
                    .italic()
            }
            
            // Notes field (full width)
            VStack(alignment: .leading, spacing: 4) {
                Text("NOTES")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondaryText)
                
                TextField("Airport, FBO, who paid, etc.", text: $notes)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.accentText)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
            }
            
            // Buttons
            HStack(spacing: 10) {
                Button("Skip") { onSkip() }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.cardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentText, lineWidth: 1)
                    )
                
                Button("Start") { onStart() }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentText)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Calculation Logic
    
    var calculationSummary: String {
        let price = Double(pricePerGallon)
        let total = Double(totalCost)
        
        if let p = price, let t = total {
            // Both provided - show breakdown
            let baseTotal = p * fuelAmount
            let fees = t - baseTotal
            let effective = t / fuelAmount
            
            if abs(fees) < 0.01 {
                return String(format: "%.1f gal\n$%.2f/gal", fuelAmount, effective)
            } else {
                return String(format: "%.1f gal • $%.2f/gal\n+ $%.2f fees = $%.2f/gal", 
                             fuelAmount, p, fees, effective)
            }
        } else if let t = total {
            // Only total - calculate effective price
            let effective = t / fuelAmount
            return String(format: "%.1f gal\n$%.2f/gal effective", fuelAmount, effective)
        } else if let p = price {
            // Only price - calculate total
            let calcTotal = p * fuelAmount
            return String(format: "%.1f gal\n= $%.2f total", fuelAmount, calcTotal)
        } else {
            // Nothing entered
            return String(format: "%.1f gal\nfrom %@", fuelAmount, presetName)
        }
    }
}
```

---

## 📊 **User Scenarios**

### Scenario 1: Full-Service FBO (All Data)
**Receipt shows**: 45.2 gal @ $6.26/gal = $282.95 + $8.50 tax = $291.45

**User enters**:
- $/GAL: `6.26`
- TOTAL: `291.45`

**System displays**:
```
45.2 gal • $6.26/gal
+ $8.50 fees = $6.45/gal
```

**Stored data**:
- `pricePerGallon`: 6.26
- `totalCost`: 291.45
- `effectivePricePerGallon`: 6.45
- `taxesAndFees`: 8.50

---

### Scenario 2: Self-Serve Pump (Total Only)
**Receipt shows**: TOTAL: $291.45

**User enters**:
- $/GAL: *(blank)*
- TOTAL: `291.45`

**System displays**:
```
45.2 gal
$6.45/gal effective
```

**Stored data**:
- `pricePerGallon`: nil
- `totalCost`: 291.45
- `effectivePricePerGallon`: 6.45

---

### Scenario 3: Fuel Card (Price Only)
**Receipt shows**: $6.26/gal

**User enters**:
- $/GAL: `6.26`
- TOTAL: *(blank)*

**System displays**:
```
45.2 gal
= $282.95 total
```

**System auto-fills**:
- TOTAL: `282.95` (calculated, user can override)

**Stored data**:
- `pricePerGallon`: 6.26
- `totalCost`: 282.95
- `effectivePricePerGallon`: 6.26

---

## ✅ **Benefits of This Approach**

1. **Flexible Entry** - Enter what you have, system fills the gaps
2. **Captures Reality** - Total includes taxes/fees (big picture tracking)
3. **Shows Effective Cost** - Always displays actual $/gal paid
4. **No Redundancy** - Gallons already known from preset selection
5. **Streamlined UI** - Three fields maximum (price, total, notes)
6. **Smart Feedback** - Live calculation shows what's being tracked
7. **Optional Everything** - Can skip any/all fields

---

## 🎨 **Visual Mockup**

```
╔════════════════════════════════════════════════════╗
║ FUEL COST (OPTIONAL) - TOP OFF                   ║
║                                                    ║
║ ┌──────┐ ┌───────┐ ┌──────────────────────────┐  ║
║ │$/GAL │ │ TOTAL │ │ BREAKDOWN                │  ║
║ │ $6.26│ │ $291  │ │ 45.2 gal • $6.26/gal     │  ║
║ │      │ │       │ │ + $8.50 fees = $6.45/gal │  ║
║ └──────┘ └───────┘ └──────────────────────────┘  ║
║                                                    ║
║ 💡 Enter price OR total (or both to track taxes)  ║
║                                                    ║
║ ┌────────────────────────────────────────────────┐║
║ │ NOTES: KLAS Signature, self-serve, card fee   │║
║ └────────────────────────────────────────────────┘║
║                                                    ║
║ [Skip]                             [Start]        ║
╚════════════════════════════════════════════════════╝
```

---

## 🚀 **Implementation Priority**

### Phase 1 (MVP):
✅ Two fields: $/GAL and TOTAL
✅ Smart calculation display
✅ Store both values
✅ Calculate effective price

### Phase 2 (Enhanced):
✅ Auto-fill calculated value (with ability to override)
✅ Show taxes/fees breakdown
✅ Validate: warn if total < expected

### Phase 3 (Advanced):
✅ Smart defaults from previous stops
✅ Price alerts (unusually high/low)
✅ Receipt OCR integration

---

**This gives pilots maximum flexibility while preserving data integrity for big-picture cost tracking!** ✈️💰
