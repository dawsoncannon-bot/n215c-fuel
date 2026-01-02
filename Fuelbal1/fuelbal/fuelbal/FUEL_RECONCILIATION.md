# Fuel Reconciliation System

## 🎯 Core Concept

**When you enter fuel data (amount + cost), we can reverse-engineer your pre-fueling state.**

### Example:
```
You select: TOP OFF (84 gallons)
Receipt shows: 45.2 gallons added @ $6.26/gal = $283.00

Therefore:
Pre-fuel level = 84 - 45.2 = 38.8 gallons (ACTUAL)
```

This "inferred actual fuel" can be compared against tracked fuel to validate accuracy and identify variances.

---

## 🧮 How It Works

### 1. **Data Capture**
When adding fuel via `FuelOptionsView`:

```swift
struct FuelStop {
    var fuelAdded: [String: Double]        // How much was added per tank
    var postFuelLevels: [String: Double]?  // NEW: What levels you selected (TOP OFF = 84, TAB FILL = 70, etc.)
}
```

**Key insight**: The preset you select (TOP OFF, TABS, CUSTOM) defines `postFuelLevels`. Combined with `fuelAdded`, we can infer `preFuelLevels`.

---

### 2. **Inference Calculation**

```swift
var inferredPreFuelLevels: [String: Double]? {
    guard let postLevels = postFuelLevels else { return nil }
    
    var preLevels: [String: Double] = [:]
    for (tank, postLevel) in postLevels {
        let added = fuelAdded[tank] ?? 0
        preLevels[tank] = max(0, postLevel - added)
    }
    
    return preLevels
}
```

**Example per-tank**:
```
L Main: Post = 25 gal, Added = 12.3 gal → Pre = 12.7 gal
R Main: Post = 25 gal, Added = 11.8 gal → Pre = 13.2 gal
L Tip:  Post = 17 gal, Added = 10.5 gal → Pre = 6.5 gal
R Tip:  Post = 17 gal, Added = 10.6 gal → Pre = 6.4 gal
```

---

### 3. **Variance Detection**

Compare tracked vs inferred:

```swift
func calculateVariance(trackedPreFuel: [String: Double]) -> [String: Double]? {
    guard let actualPreFuel = inferredPreFuelLevels else { return nil }
    
    var variance: [String: Double] = [:]
    for (tank, trackedLevel) in trackedPreFuel {
        let actualLevel = actualPreFuel[tank] ?? 0
        variance[tank] = trackedLevel - actualLevel  // Positive = optimistic
    }
    
    return variance
}
```

**Interpretation**:
- **Positive variance**: Tracking thought you had MORE fuel than you actually did (optimistic)
- **Negative variance**: Tracking thought you had LESS fuel than you actually did (conservative)
- **Near zero**: Tracking is accurate

---

## 📊 Practical Use Cases

### 1. **Flight Accuracy Reports** ✅

Show pilots how close their tracking was:

```
╔═══════════════════════════════════════╗
║ LEG #2 RECONCILIATION                ║
║                                       ║
║ Tracked ending fuel:  40.2 gal       ║
║ Actual ending fuel:   38.8 gal       ║
║ Variance:             -1.4 gal       ║
║                                       ║
║ ⚠️ Tracking optimistic by 1.4 gal    ║
║                                       ║
║ Possible causes:                     ║
║ • Ground ops fuel burn               ║
║ • Measurement variance               ║
║ • Untracked consumption              ║
╚═══════════════════════════════════════╝
```

---

### 2. **Cost Per Flight Hour** 💰

Allocate fuel costs to specific legs based on **actual** consumption:

```swift
// Previous approach (estimated):
costPerLeg = (totalTripCost / totalLegs)

// New approach (actual):
for leg in trip.legs {
    let actualBurned = leg.inferredFuelBurned  // From receipt data
    let priceAtStop = correspondingFuelStop.pricePerGallon
    costForThisLeg = actualBurned * priceAtStop
}
```

**Example**:
```
Leg 1 (PHX → LVS):
  Burned:  45.2 gal (inferred from receipt)
  Price:   $6.26/gal
  Cost:    $283.00

Leg 2 (LVS → LAX):
  Burned:  52.1 gal (inferred from receipt)
  Price:   $6.45/gal
  Cost:    $336.00

Total Trip Cost: $619.00 (accurate per-leg allocation)
```

---

### 3. **Fuel System Health Monitoring** 🔧

Detect patterns that might indicate issues:

```
Trip Analysis:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Leg 1:  Tracking accurate (within 0.5 gal)
Leg 2:  Tracking optimistic by 1.8 gal ⚠️
Leg 3:  Tracking optimistic by 2.1 gal ⚠️
Leg 4:  Tracking optimistic by 2.3 gal ⚠️

🔔 Pattern detected:
Consistent optimistic tracking suggests:
• Fuel gauge calibration drift
• Totalizer accuracy issues
• Higher-than-expected consumption
```

---

### 4. **Cross-Check Fuel Stop Receipts** 🧾

Validate receipt data makes sense:

```swift
let fuelStop = FuelStop(
    fuelAdded: ["lMain": 20, "rMain": 18],  // What FBO says
    postFuelLevels: ["lMain": 25, "rMain": 25],  // What you selected
    totalCost: 150.00
)

// Inferred pre-fuel: lMain = 5, rMain = 7 (total: 12 gal)
// If tracked showed 25 gal pre-fuel → huge variance!
// Likely receipt error or mismatched tank assignment
```

---

## 🛠️ Implementation Details

### Data Structure

```swift
struct FuelStop: Codable {
    var fuelAdded: [String: Double]         // From receipt
    var postFuelLevels: [String: Double]?   // From preset selection (TOP OFF, TAB FILL, CUSTOM)
    var pricePerGallon: Double?
    var totalCost: Double?
    
    // Computed properties
    var inferredPreFuelLevels: [String: Double]? { ... }
    var inferredPreFuelTotal: Double? { ... }
    
    func calculateVariance(trackedPreFuel: [String: Double]) -> [String: Double]? { ... }
    func totalVariance(trackedPreFuel: [String: Double]) -> Double? { ... }
}
```

### Trip-Level Reconciliation

```swift
struct Trip {
    func fuelReconciliation() -> [LegReconciliation] {
        // Matches legs with fuel stops
        // Computes variance per leg
        // Returns structured reconciliation data
    }
    
    var canReconcile: Bool {
        // True if trip has fuel stops with postFuelLevels data
    }
}

struct LegReconciliation {
    let legNumber: Int
    let trackedEndingFuel: [String: Double]
    let inferredActualFuel: [String: Double]?
    let variance: Double?
    
    var varianceDescription: String {
        // "Tracking optimistic by 1.4 gal"
        // "Within tolerance (±0.5 gal)"
        // "Tracking conservative by 0.8 gal"
    }
}
```

---

## 📱 UI Integration Ideas

### Option 1: Trip Detail View Enhancement

Add a "Reconciliation" section:

```swift
// In TripDetailView.swift
if trip.canReconcile {
    VStack(alignment: .leading, spacing: 12) {
        Text("FUEL RECONCILIATION")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(.secondaryText)
            .tracking(2)
        
        ForEach(trip.fuelReconciliation(), id: \.legNumber) { recon in
            ReconciliationCard(reconciliation: recon)
        }
    }
}
```

### Option 2: Export Enhancement

Include reconciliation in text reports:

```
FUEL RECONCILIATION:
-----------------------------------

Leg #1:
  Tracked:  40.2 gal
  Actual:   38.8 gal
  Variance: -1.4 gal (tracking optimistic)
  
Leg #2:
  Tracked:  42.1 gal
  Actual:   41.9 gal
  Variance: -0.2 gal (within tolerance)
```

### Option 3: Alert on Large Variance

```swift
if abs(variance) > 3.0 {
    // Show alert: "Fuel tracking off by 3+ gallons"
    // Suggest recalibration or system check
}
```

---

## 🎯 When Reconciliation Works

### ✅ **Requires**:
1. Fuel stop with cost/price data (triggers `postFuelLevels` capture)
2. Preset or custom fuel selection (defines post-fuel state)
3. Previous leg with swap log (defines tracked pre-fuel state)

### ❌ **Won't work when**:
1. Cost tracking skipped (no `postFuelLevels` captured)
2. First flight of aircraft (no previous tracked state)
3. Zero-fuel engine restarts (no fuel added, nothing to infer)

---

## 💡 Future Enhancements

### 1. **Predictive Fuel Planning**
Use historical variance to adjust future fuel estimates:
```
"Based on past trips, you typically burn 5% more than tracked.
Consider adding safety margin."
```

### 2. **Fleet Analytics**
Compare reconciliation across multiple aircraft:
```
N12345: Average variance = +0.3 gal (accurate)
N67890: Average variance = +2.1 gal (check gauges)
```

### 3. **Smart Receipt Parsing**
OCR fuel receipts to auto-populate cost data:
```
"Detected: 45.2 gal @ $6.26 = $283.00"
[Confirm] [Edit]
```

### 4. **Live Variance Tracking**
During flight, show real-time comparison:
```
Current tank: L Main
Tracked:  18.2 gal remaining
Expected: 16.8 gal (based on historical variance)
```

---

## 📈 Example Scenario

### Trip: Phoenix → Las Vegas → Los Angeles

**Leg 1: PHX → LVS**
- Started: TOP OFF (84 gal)
- Tracked burn: 45.0 gal
- Tracked ending: 39.0 gal

**Fuel Stop: Las Vegas**
- Selected: TOP OFF (84 gal)
- Receipt: 45.2 gal added
- Inferred pre-fuel: 38.8 gal

**Reconciliation**:
```
Tracked:  39.0 gal
Actual:   38.8 gal
Variance: +0.2 gal (within tolerance) ✅
```

**Leg 2: LVS → LAX**
- Started: TOP OFF (84 gal)
- Tracked burn: 52.0 gal
- Tracked ending: 32.0 gal

**Fuel Stop: Los Angeles**
- Selected: TOP OFF (84 gal)
- Receipt: 54.3 gal added
- Inferred pre-fuel: 29.7 gal

**Reconciliation**:
```
Tracked:  32.0 gal
Actual:   29.7 gal
Variance: +2.3 gal (tracking optimistic) ⚠️
```

**Trip Summary**:
```
Total variance: +2.5 gal across 2 legs
Average: +1.25 gal per leg

Recommendation:
• Check fuel gauge calibration
• Consider adding 1-2 gal safety margin
```

---

## ✅ Summary

This reconciliation system **turns optional cost tracking into a powerful validation tool**:

1. 🎯 **Validates tracking accuracy** - See how close your swaps matched reality
2. 💰 **Enables accurate cost allocation** - Know exactly what each leg cost
3. 🔧 **Detects system issues** - Spot fuel system problems early
4. 📊 **Improves planning** - Use historical data to refine future estimates

**The beauty**: This works **retroactively** on any fuel stop with cost data, even if you didn't initially plan to track it. The receipt itself becomes a validation checkpoint! 🚁✨
