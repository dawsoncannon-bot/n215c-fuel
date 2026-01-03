# Fuel Management HUD - UI Mockup

## Complete In-Flight View

```
┌─────────────────────────────────────────────────────────────────┐
│  [◄ BACK]              LEG #2 • TOP OFF               [START]   │
│                           84.0 GAL                      ENGINE   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                     ⏱️  TIME TO SWAP                      │  │
│  │                         16:42                             │  │
│  │                 Based on observed GPH                     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────┐    ┌───────────────────────────┐   │
│  │      AVG GPH          │    │       OBSERVED            │   │
│  │        11.2           │    │         11.8              │   │
│  │    ACTUAL BURN        │    │      INSTRUMENT           │   │
│  └───────────────────────┘    └───────────────────────────┘   │
│                                                                  │
│  🕐 LEG TIME: 01:23:45                                          │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              MAINS • BALANCED                             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  SAFETY RESERVE: 0.9 GAL                                        │
│                                                                  │
│  ┌──────┐  ┌──────┐  ┌────────────┐  ┌──────┐  ┌──────┐      │
│  │L TIP │  │L MAIN│  │  BURNING   │  │R MAIN│  │R TIP │      │
│  │      │  │▓▓▓▓▓▓│  │   L MAIN   │  │▓▓▓▓▓▓│  │      │      │
│  │▓▓▓▓▓▓│  │▓▓▓▓▓▓│  │            │  │▓▓▓▓▓▓│  │▓▓▓▓▓▓│      │
│  │▓▓▓▓▓▓│  │▓▓▓▓▓▓│  │   NEXT     │  │▓▓▓▓▓▓│  │▓▓▓▓▓▓│      │
│  │▓▓▓▓▓▓│  │▓▓▓▓▓▓│  │  R MAIN    │  │▓▓▓▓▓▓│  │▓▓▓▓▓▓│      │
│  │▓▓▓▓▓▓│  │      │  │            │  │▓▓▓▓▓▓│  │▓▓▓▓▓▓│      │
│  │ 17.0 │  │ 15.2 │  │            │  │ 24.8 │  │ 17.0 │      │
│  └──────┘  └──────┘  └────────────┘  └──────┘  └──────┘      │
│                                                                  │
│  ┌─────────────────────┐    ┌─────────────────────────────┐   │
│  │   LAST READING      │    │      SWAP AT                │   │
│  │       7.2           │    │       17.2                  │   │
│  └─────────────────────┘    └─────────────────────────────┘   │
│                                                                  │
│  [UNDO]                                                          │
│                                                                  │
│  TOTALIZER USED                                                 │
│  ┌────────────────────────────────────┐  ┌──────────────┐     │
│  │              0.0                   │  │  LOG SWAP    │     │
│  └────────────────────────────────────┘  └──────────────┘     │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  RECENT SWAPS                                             │  │
│  │  #    TANK       TIME      TOTAL   BURN                   │  │
│  │  ─────────────────────────────────────────────────────    │  │
│  │  #3   R MAIN   01:15:22    17.2    +10.0                 │  │
│  │  #2   L MAIN   00:55:45    7.2     +10.2                 │  │
│  │  #1   R MAIN   00:07:23    --      +7.0                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## HUD States

### State 1: No GPH Logged (Initial)
```
┌─────────────────────────────────────────┐
│  ┌─────────────────┐  ┌──────────────┐ │
│  │    AVG GPH      │  │   OBSERVED   │ │
│  │      --         │  │     TAP      │ │  ← Prompts user
│  │  ACTUAL BURN    │  │  INSTRUMENT  │ │     to tap
│  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────┘

(No countdown timer visible)
```

### State 2: GPH Logged, Normal Operation
```
┌───────────────────────────────────────────┐
│  ┌─────────────────────────────────────┐  │
│  │      ⏱️  TIME TO SWAP               │  │
│  │          16:42                      │  │  ← Countdown
│  │    Based on observed GPH            │  │     (green)
│  └─────────────────────────────────────┘  │
│                                            │
│  ┌─────────────────┐  ┌──────────────┐   │
│  │    AVG GPH      │  │   OBSERVED   │   │
│  │      11.2       │  │     11.8     │   │
│  │  ACTUAL BURN    │  │  INSTRUMENT  │   │
│  └─────────────────┘  └──────────────┘   │
└───────────────────────────────────────────┘
```

### State 3: Urgent Warning (< 5 Minutes)
```
┌───────────────────────────────────────────┐
│  ┌─────────────────────────────────────┐  │
│  │   ⚠️  TIME TO SWAP                  │  │
│  │          04:23                      │  │  ← Orange
│  │    ⚠️ PREPARE TO SWAP               │  │     border
│  └─────────────────────────────────────┘  │     (urgent)
│         (Orange background tint)           │
│                                            │
│  ┌─────────────────┐  ┌──────────────┐   │
│  │    AVG GPH      │  │   OBSERVED   │   │
│  │      11.2       │  │     11.8     │   │
│  │  ACTUAL BURN    │  │  INSTRUMENT  │   │
│  └─────────────────┘  └──────────────┘   │
└───────────────────────────────────────────┘
```

### State 4: After Tank Swap
```
┌───────────────────────────────────────────┐
│  (Countdown timer not visible)             │
│                                            │
│  ┌─────────────────┐  ┌──────────────┐   │
│  │    AVG GPH      │  │   OBSERVED   │   │
│  │      11.4       │  │     TAP      │   │  ← Reset to
│  │  ACTUAL BURN    │  │  INSTRUMENT  │   │     "TAP"
│  └─────────────────┘  └──────────────┘   │
└───────────────────────────────────────────┘

(User needs to log GPH for new tank)
```

---

## GPH Input Sheet

```
┌───────────────────────────────────────────┐
│                                            │
│         OBSERVED GPH                       │
│                                            │
│   Enter current GPH from instrument        │
│                                            │
│   Current: 11.8 GPH                        │  ← Shows
│                                            │     current
│                                            │
│   ┌──────────────────────────────┐        │
│   │            12.5              │        │  ← Input
│   │                              │        │     field
│   └──────────────────────────────┘        │
│                                            │
│   ┌───────────┐    ┌───────────┐         │
│   │  Cancel   │    │  Log GPH  │         │
│   └───────────┘    └───────────┘         │
│                                            │
└───────────────────────────────────────────┘
```

---

## Leg Timer Display Variations

### Active (Engine Running)
```
🕐 LEG TIME: 01:23:45
    (green text)
```

### Paused (Engine Stopped)
```
🕐 LEG TIME: 01:23:45  ⏸️
    (gray text, pause icon)
```

### Compact in Corner
```
┌────────────────────┐
│ 🕐 LEG: 01:23:45   │  ← Small, dark background
└────────────────────┘    Stays out of the way
```

---

## Color Coding

### Countdown Timer
- **Green** (00:00 - 59:59): Normal operations
- **Orange** (< 05:00): Urgent warning
- **Red** (00:00): Time to swap

### HUD Fields
- **Blue** (.accentText): Average GPH (historical data)
- **Green** (.fuelActive): Observed GPH (current prediction)
- **Gray**: Inactive/unpopulated fields

### Tank Gauges
- **Green** (.fuelActive): Currently burning
- **Blue** (.accentText): Normal level
- **Orange/Red** (.fuelLow): Low or empty

---

## Responsive Layout

### iPhone SE (Small Screen)
```
┌───────────────────────────┐
│  Countdown (stacked)      │
│  ┌─────────────────────┐  │
│  │  TIME TO SWAP       │  │
│  │     16:42           │  │
│  └─────────────────────┘  │
│                           │
│  HUD (narrower)           │
│  ┌─────┐    ┌──────┐     │
│  │ AVG │    │ OBS  │     │
│  │11.2 │    │11.8  │     │
│  └─────┘    └──────┘     │
└───────────────────────────┘
```

### iPhone Pro Max (Large Screen)
```
┌─────────────────────────────────────────┐
│  Countdown (full width)                  │
│  ┌────────────────────────────────────┐  │
│  │      TIME TO SWAP      16:42       │  │
│  └────────────────────────────────────┘  │
│                                           │
│  HUD (wide, spacious)                    │
│  ┌──────────────┐    ┌──────────────┐   │
│  │   AVG GPH    │    │   OBSERVED   │   │
│  │     11.2     │    │     11.8     │   │
│  └──────────────┘    └──────────────┘   │
└─────────────────────────────────────────┘
```

### iPad (Tablet)
```
┌───────────────────────────────────────────────────────┐
│  All elements wider with more padding                  │
│  Larger fonts, more breathing room                     │
│  Side-by-side layout for more components               │
└───────────────────────────────────────────────────────┘
```

---

## Dark Mode (Default)

**Background Colors:**
- App Background: Dark gray (#1C1C1E)
- Card Background: Slightly lighter (#2C2C2E)
- Input Fields: Very dark (#000000 with 30% opacity)

**Text Colors:**
- Primary: White (#FFFFFF)
- Secondary: Light gray (60% opacity)
- Accent: Cyan blue (#64D2FF)
- Active: Green (#32D74B)
- Warning: Orange (#FF9F0A)
- Critical: Red (#FF453A)

---

## Animation States

### Countdown Timer Transitions

**Normal → Urgent (at 5:00 remaining):**
```
┌────────────────┐       ┌────────────────┐
│  ⏱️  05:00     │  →   │  ⚠️  04:59     │
│  (green)       │       │  (orange)      │
└────────────────┘       └────────────────┘
     (Smooth color fade, border grows thicker)
```

**Pulse Effect at < 1:00:**
```
04:59 → 04:58 → ... → 01:00 → 00:59 ⚠️
                              (starts pulsing)
```

### GPH Input Button

**Inactive:**
```
┌──────────────┐
│   OBSERVED   │
│     TAP      │  ← Gray, subdued
│  INSTRUMENT  │
└──────────────┘
```

**Active:**
```
┌══════════════┐
│   OBSERVED   │
│     11.8     │  ← Green, highlighted border
│  INSTRUMENT  │
└══════════════┘
```

**Tap Animation:**
```
Normal → Scale 0.95 → Normal
      (0.1s)    (0.1s)
```

---

## Typography Hierarchy

```
1. Countdown Time: 48pt Bold Monospaced
   "16:42"

2. GPH Values: 28pt Bold Monospaced
   "11.8"

3. Tank Gauge Values: 14pt Bold Monospaced
   "15.2"

4. Leg Timer: 11pt Bold Monospaced
   "01:23:45"

5. Section Headers: 10pt Regular Monospaced Tracked
   "TIME TO SWAP"

6. Labels: 9pt Regular Monospaced Tracked
   "AVG GPH"

7. Descriptions: 8pt Regular Monospaced Tracked
   "ACTUAL BURN"
```

---

## Interaction Patterns

### Tap "Observed" Field
```
User Action: Tap
     ↓
Sheet slides up
     ↓
Keyboard appears
     ↓
User enters GPH
     ↓
Tap "Log GPH"
     ↓
Sheet dismisses
     ↓
Countdown appears/updates
```

### Tank Swap
```
User logs totalizer
     ↓
Swap recorded
     ↓
Countdown disappears
     ↓
Observed GPH shows "TAP"
     ↓
User logs new GPH
     ↓
Countdown reappears
```

### Engine Stop/Start
```
Engine Stop
     ↓
Timer pauses
     ↓
Countdown pauses
     ↓
Gray out indicators
     ↓
     [Time passes...]
     ↓
Engine Start
     ↓
Timer resumes
     ↓
Countdown resumes
     ↓
Normal colors return
```

---

## Accessibility

### VoiceOver Labels
- Countdown: "Time to swap, 16 minutes 42 seconds"
- Average GPH: "Average gallons per hour, 11.2"
- Observed GPH: "Observed gallons per hour, 11.8, tap to update"
- Leg Timer: "Leg time, 1 hour 23 minutes 45 seconds"

### Dynamic Type Support
- All text scales with system font size
- Minimum sizes enforced for critical numbers
- Layout adjusts for larger text

### Color Blind Modes
- Not relying solely on color for warnings
- Icons supplement colors (⚠️ for warnings)
- Text always accompanies colored elements

---

## Summary

The UI is designed to be:
- **Prominent** where it matters (countdown timer)
- **Unobtrusive** where it doesn't (leg timer)
- **Clear** with color-coded states
- **Responsive** to user actions
- **Accessible** for all users

The visual hierarchy ensures pilots can quickly grasp:
1. **How much time until swap** (biggest, top)
2. **Current burn rates** (medium, middle)
3. **Supporting data** (smaller, context)
