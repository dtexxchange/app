# USDT Exchange — Design System

Extracted from the web frontend (`apps/frontend`). All mobile apps must strictly follow these tokens to maintain visual consistency.

---

## Color Palette

| Token             | Hex / Value                   | Usage                                         |
|-------------------|-------------------------------|-----------------------------------------------|
| `bg-dark`         | `#0A0B0D`                     | Page / scaffold background                    |
| `bg-card`         | `#15171C`                     | Cards, tiles, bottom sheets                   |
| `primary`         | `#00FF9D`                     | Accent, CTA buttons, icons, borders highlight |
| `primary-dim`     | `rgba(0,255,157, 0.2)`        | Glow / shadow under primary buttons           |
| `primary-subtle`  | `rgba(0,255,157, 0.05–0.1)`   | Card ambient background, icon bg              |
| `accent-blue`     | `#3B82F6`                     | Secondary accent, deposit icon bg             |
| `text-main`       | `#FFFFFF`                     | Headings, primary body text                   |
| `text-dim`        | `#94A3B8`                     | Subtext, labels, placeholders                 |
| `border`          | `rgba(255,255,255, 0.05)`     | Card borders, dividers                        |
| `input-fill`      | `rgba(255,255,255, 0.03–0.05)`| Text-field backgrounds                        |
| `danger`          | `#F87171` (red-400)           | Errors, logout button hover, rejected status  |

---

## Typography

| Role              | Font Family | Weight      | Size (web equiv.) |
|-------------------|-------------|-------------|-------------------|
| Display / Titles  | **Outfit**  | 700 (Bold)  | 28–48 sp          |
| Section Headers   | **Outfit**  | 600         | 20–24 sp          |
| Body / Labels     | **Inter**   | 400–500     | 14–16 sp          |
| Captions / Tags   | **Inter**   | 600–700     | 10–12 sp          |
| Monospace amounts | **Outfit**  | 700         | 36–60 sp          |

---

## Spacing & Radius

| Token      | Value  | Usage                                  |
|------------|--------|----------------------------------------|
| `radius-sm`| 12 dp  | Input fields, small buttons, tags      |
| `radius-md`| 16 dp  | Transaction tiles, info rows           |
| `radius-lg`| 24 dp  | Cards, bottom sheets, auth panel       |
| `radius-xl`| 32 dp  | Balance card                           |
| Padding    | 24 dp  | Standard page horizontal padding       |

---

## Component Tokens

### Cards / Glass Panel
```
background:   #15171C
border:       1px solid rgba(255,255,255,0.05)
borderRadius: 24 dp
padding:      24–32 dp
```
Ambient glow (optional): `primaryColor.withOpacity(0.05)` blur circle in corner.

### Primary Button (`btn-primary`)
```
background:   #00FF9D
foreground:   #000000
borderRadius: 12 dp
paddingV:     16 dp
elevation/shadow: 0 4dp 20dp rgba(0,255,157,0.2)
```

### Ghost / Secondary Button
```
background:   rgba(255,255,255,0.05)
foreground:   #FFFFFF
border:       1px solid rgba(255,255,255,0.1)
borderRadius: 12 dp
```

### Danger Button (logout etc.)
```
background:   rgba(248,113,113,0.1)
foreground:   #F87171
border:       1px solid rgba(248,113,113,0.2)
borderRadius: 12 dp
```

### Input Field
```
background:   rgba(255,255,255,0.03)
border (idle):   rgba(255,255,255,0.10)
border (focus):  #00FF9D
borderRadius: 12 dp
textColor:    #FFFFFF
labelColor:   #94A3B8
```

### Status Badges
| Status    | Background               | Border               | Text         |
|-----------|--------------------------|----------------------|--------------|
| PENDING   | `rgba(59,130,246,0.05)` | `rgba(59,130,246,0.2)` | `#3B82F6`  |
| COMPLETED | `rgba(0,255,157,0.05)`  | `rgba(0,255,157,0.2)`  | `#00FF9D`  |
| REJECTED  | `rgba(248,113,113,0.05)`| `rgba(248,113,113,0.2)`| `#F87171`  |

### Transaction Row Icon
| Type     | Icon bg                     | Icon color   |
|----------|-----------------------------|--------------|
| DEPOSIT  | `rgba(0,255,157,0.10)`      | `#00FF9D`    |
| EXCHANGE | `rgba(255,255,255,0.05)`    | `#FFFFFF`    |

---

## Icons
The web uses **Lucide** icons. In Flutter, use `Icons` equivalents:
| Lucide          | Material Icons              |
|-----------------|-----------------------------|
| `Diamond`       | `diamond_outlined`          |
| `Wallet`        | `account_balance_wallet`    |
| `ArrowDownLeft` | `arrow_downward`            |
| `ArrowUpRight`  | `arrow_upward`              |
| `History`       | `receipt_long`              |
| `LogOut`        | `logout`                    |
| `ShieldCheck`   | `shield_outlined`           |
| `KeyRound`      | `key_outlined`              |
| `Activity`      | `show_chart`                |
| `Clock`         | `access_time`               |
| `CheckCircle2`  | `check_circle_outline`      |
| `XCircle`       | `cancel_outlined`           |
| `Person`        | `person_outline`            |
| `Settings`      | `settings_outlined`         |

---

## Bottom Navigation Bar
```
background:  #0A0B0D
topBorder:   rgba(255,255,255,0.05)
selectedIcon / label: #00FF9D
unselected:  rgba(255,255,255,0.5)
indicator:   rgba(0,255,157,0.15) rounded pill
tabs: [Home, History, Profile]
```

---

## Logo Mark
```
Icon:  Diamond (or equivalent)
Container: 
  - size: 40×40 (navbar) / 80×80 (auth page)
  - bg: rgba(0,255,157,0.10)
  - border: rgba(0,255,157,0.20)
  - radius: 16–24 dp
  - shadow: 0 0 30px rgba(0,255,157,0.15)
App name: "USDT.EX" — Font: Outfit Bold, ".EX" in gray
```

---

## Auth Screen Specifics
- Full-screen dark background with two ambient glow blobs (primary top-left, blue bottom-right, `opacity: 0.15–0.20`, `blur: 100–150dp`)
- Centered glass panel: `bg-card #15171C`, border, radius 24
- Logo mark at top, `Diamond` icon
- Title: "Workspace Access" (`text-main`, Outfit Bold 28sp)
- Subtitle: `text-dim`, 14sp
- Two-step flow: Email → OTP (slide animation between steps)
- Security disclaimer at bottom: shield icon + small gray text
- Admin app: same design, subtitle says "Admin Workspace"

---

## Home / Dashboard Specifics
- Balance card spans full width on mobile: Outfit Bold 48–56sp balance amount + "USDT" in primary green
- Two action buttons below balance: `Add Money` (primary) and `Exchange` (ghost)
- Transaction list: card container, each row is a tile with icon + type + amount + status badge + date
- Amount format: `+1,234.00 USDT` in primary for deposits, `-1,234.00 USDT` in white for exchanges
- Empty state: centered icon + `text-dim` message

---

## Profile Screen
- User avatar: circle, `bg-card`, large initial letter in primary color, Outfit Bold 40sp
- Email row, Status row inside card tiles
- Danger logout button at bottom
