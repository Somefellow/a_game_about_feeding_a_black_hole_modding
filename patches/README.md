# Mod Patches

Each patch is a change applied on top of the original game. This file describes what each one does from a player's perspective.

---

## Auto-buy upgrades on the upgrade screen

**File:** `UpgradeScreen.gd.patch`

When the upgrade screen opens, all affordable upgrades are automatically purchased one by one. Roguelike choice cards are also handled — the cheapest available option is picked. Each purchase has a short pause so you can see what was bought. Once all affordable upgrades are spent, the screen closes on its own after 1.5 seconds.

---

## Auto-advance tier and end-of-run summary screens

**Files:** `TierSummary.gd.patch`, `End_of_Run_Summary.gd.patch`

After the score animation finishes on the between-tier summary and the end-of-run summary, the screen automatically advances to the next stage (upgrades or the main menu) after 1.5 seconds — no click required.

---

## Smarter auto-targeting for the clicker

**File:** `Singletons__Clicker.gd.patch`

The clicker (the cursor that automatically damages objects) uses a scoring system to pick the best target instead of just picking the largest one:

1. **Comets and UFOs** are top priority — they are time-limited and die on contact, so hitting them first maximises reward.
2. **Modified objects** (electric, radioactive, golden asteroids etc.) rank above plain ones.
3. Among equal-tier targets, **low-health objects** are preferred so kills happen faster, and **closer objects** break ties.

The clicker also re-evaluates its target on a short timer rather than only when the current target dies, but only switches if the new target scores at least 20% better — preventing constant jittery switching.

---

## Wait for matter to be collected before ending a session

**File:** `ObjectManager.gd.patch`

When the last object in a session is destroyed, matter chunks fly toward the black hole and award XP when consumed. Previously the session ended immediately, causing those final chunks to be lost. Now the session waits until all matter chunks have been fully absorbed before the end-of-session screen appears.
