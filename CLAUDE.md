# Pulse

iOS habit tracker and wellness journal with a personal AI Coach. Habit logs, twice-daily
check-ins, and free-text reflections form one personal corpus that a custom RAG pipeline
mines for insights (e.g. how sleep relates to habit completion or mood).

Full spec: `docs/SPEC.md`. Read it for the complete picture — this file is the condensed
version for day-to-day work.

Goals, in order: ship a clean App Store app; demonstrate real AI engineering skill through
a RAG system Joshua leads and can defend in interviews; keep scope tight — every feature
must make the product better, not just the resume.

## Phases

- **Phase 1 (current), local app** — Habits, twice-daily check-ins, reflections, Home
  dashboard, Profile, onboarding. All local in SwiftData. Claude Code builds this end to end.
- **Phase 2, backend and Coach** — Supabase backend, Sign in with Apple, sync, cloud RAG
  Coach, small eval set, consent flow, account deletion. Claude Code builds app/backend
  plumbing; Joshua and Claude Code pair on the RAG pipeline.
- **Later / undecided** — On-device RAG path, Passio food logging, widgets, Live Activities,
  Xcode Cloud, HealthKit (Phase 2 optional).

Non-goals: teaching Swift fundamentals (that's App Dev Club), AI features added purely for
show (tool-using agent Coach, formal cloud-vs-on-device benchmark), food logging/widgets/Live
Activities before the core app ships.

## Design rules

- iOS 26 Liquid Glass, first-party Apple feel. Dark mode first; light mode via
  `UIColor.traitCollection`.
- Lavender accent `#A78BFA`. Card layouts using `.regularMaterial` / `.ultraThinMaterial`.
  Atmospheric `MeshGradient` background on the Coach tab (Apple Journal-inspired).
- **All colors, spacing, radii, and strings come from `Utilities/Constants.swift`**
  (`PulseColors`, `PulseSpacing`, `PulseRadius`, `PulseStrings`). No hardcoded values in
  views — new work must use tokens, and add new tokens there rather than inlining values.
  Note: some existing views (ProfileView, CheckInView) still have hardcoded strings/colors
  from earlier scaffolding — fix opportunistically when touching that code, don't do a
  drive-by pass.
- Check In must be low friction — a full check-in should take seconds, or the twice-daily
  habit won't stick.
- Reflections live on Home, not their own tab — a visible button on Home opens the
  reflection editor. An off-by-default Profile-toggled reminder notification (sends only on
  days without a reflection, tapping it opens the editor directly) is speced but not built
  yet — don't build the reminder until asked. See `docs/SPEC.md` for full details.

## Folder structure

Feature-based:

```
Pulse/
  Features/
    Dashboard/Views/       DashboardView, ProfileView — reflection editor lands here too
    CheckIn/{Views,ViewModels}/
    Coach/{Views,ViewModels}/   ReflectionViewModel sits here for now; may move to
                                Dashboard since reflections live on Home, not their own tab
    Habits/ViewModels/          (no Views yet)
    ContentView.swift           tab root
  Models/                  Habit, HabitLog, CheckIn, Reflection (SwiftData @Model)
  Services/                Supabase, RAG, HealthKit, Notifications, Nutrition — not
                            created yet, land as each is needed (Phase 2+ mostly)
  Utilities/                Constants.swift (design tokens), Color(hex:) extension
  Resources/                 not created yet
PulseTests/, PulseUITests/  Swift Testing framework
```

SwiftData models: `Habit` (+ `HabitCategory`/`HabitType`/`HabitFrequency`), `HabitLog`,
`CheckIn` (user + biometric + nutrition fields), `Reflection` (has `isEmbedded` for RAG
ingestion tracking). Four `@Observable` ViewModels exist: `HabitViewModel`,
`CheckInViewModel`, `ReflectionViewModel`, `CoachViewModel` (currently returns a simulated
response — real RAG lands in Phase 2).

## AI architecture (Phase 2, for context)

Coach runs a custom RAG pipeline behind a `RAGProvider` protocol so an on-device path can be
added later without a rewrite. Numeric entries render to prose before embedding (numbers
embed poorly). Retrieval is hybrid: vector similarity + SQL aggregates for stats. API keys
live only in Supabase Edge Functions, never in the app binary. RLS isolates user data.
Deleting an entry deletes its embedding. A small eval set (20-30 questions against a fake
user history) checks retrieval quality and answer faithfulness; results go in the README.

## Workflow rules

- **Never commit, push, or merge.** Joshua does every commit and push himself. Propose a
  commit message when a change is ready; stop there.
- One feature per branch off `dev`, merged via PR. `main` holds stable milestones. SSH
  remote uses the `github-personal` alias.
- Start each feature in plan mode; get approach approval before writing code.
- Before merge, Joshua must be able to explain the diff in his own words — write for that.
- **App UI and backend plumbing**: build end to end once the plan is approved.
- **RAG work** (`Services/RAG`, RAG Edge Functions): collaborate, don't build solo. Lay out
  options with tradeoffs, explain concepts as they come up, pair on the code, write tests.
  Joshua makes final design calls and must be able to explain every line.
- Ask before adding any new dependency.
- Use design tokens from `Constants.swift`; keep the feature-based folder structure.

## Testing

Swift Testing framework (`import Testing`, `@Test`, `#expect`) for unit tests, XCUIAutomation
for UI tests. `PulseTests/`, `PulseUITests/`.
