# Decision Log

A running record of Pulse's design and architecture decisions, newest first. Each entry
says what was decided, why, and which alternatives were rejected. Claude Code proposes new
entries, and Joshua approves them before they're added.

### Versioned SwiftData schema and graceful store loading before release
*Sep 26, 2026*
- **Decision:** Before App Store submission, freeze the models as `SchemaV1` with a `SchemaMigrationPlan`. Replace the `fatalError` on store load with a recovery screen that offers Retry, and a data reset behind a confirmation.
- **Why:** After release, a schema change that can't migrate would crash the app or wipe data for every user. Until release, deleting and reinstalling the app is fine.
- **Rejected:** Versioning from day one, which is overhead while nothing has shipped. Keeping `fatalError`. Deleting and recreating the store automatically on failure, which loses data silently.

### Invalid schedules fail loudly
*Sep 26, 2026*
- **Decision:** The model asserts that a schedule has at least one weekday. The ViewModel rejects an empty schedule with a user-facing error before it reaches the model.
- **Why:** Quietly turning an empty schedule into daily would hide bugs and create habits the user never asked for.
- **Rejected:** Silently falling back to daily.

### Schedule history on each habit
*Sep 26, 2026*
- **Decision:** A habit stores `scheduleHistory`, a list of dated weekday periods. It always has at least one period. Changing the schedule adds a period starting today. `scheduledWeekdays` and `startDate` are computed from the history. Streaks use the schedule that was in effect on each day.
- **Why:** Editing a schedule shouldn't rewrite past streaks. A missed day has no log, so the schedule history has to be stored on the habit.
- **Rejected:** Saving the schedule on each log, since missed days have no log. A separate `@Model` for schedule periods, which adds boilerplate for the same result. A stored `startDate` alongside the history, which would give two records of when a habit started.

### Target saved on each quantity log
*Sep 26, 2026*
- **Decision:** Each quantity log stores `targetAtLog`, the habit's target that day. Changing the target updates today's log, and past logs stay as they were.
- **Why:** Changing a target shouldn't rewrite history or break streaks.
- **Rejected:** Comparing past logs against the current target.

### HabitType is yes/no vs quantity; good/bad habits dropped
*Sep 26, 2026*
- **Decision:** `HabitType` is now `.yesNo` or `.quantity`. Bad habits are written as positive yes/no habits, like "No alcohol".
- **Why:** Yes/no vs quantity is the distinction the app actually needs, and it's the "type" the Foundation Models setup returns.
- **Rejected:** Keeping the good/bad split, which had no UI and no use.

### On-device Foundation Models for custom habit setup
*Sep 26, 2026*
- **Decision:** The user describes a habit in plain language. A `@Generable` struct returns the type, a unit from the fixed list, the target, and the schedule. The user can edit the result on a confirmation screen before saving. If Foundation Models is unavailable, setup falls back to the yes/no custom habit form.
- **Why:** It's a real AI feature that helps users, the data stays on device, and it costs nothing to run.
- **Rejected:** A cloud LLM for habit setup. Letting the model set the step size.

### Streaks calculated from logs
*Sep 26, 2026*
- **Decision:** Streaks, longest streak, and totals are calculated from logs and the schedule history by `HabitProgress`. Nothing is stored.
- **Why:** They're always correct and easy to unit test. Undoing a check just deletes the log.
- **Rejected:** The stored counters `streak`, `longestStreak`, and `totalCompletions`.

### Schedule is daily or specific weekdays
*Sep 26, 2026*
- **Decision:** A habit runs every day or on chosen weekdays. Streaks only count scheduled days, so a rest day never breaks a streak.
- **Why:** It matches real routines, like training 3 times a week.
- **Rejected:** A custom frequency. Weekdays and weekends as special cases.

### Quantity completion is calculated; partial amounts are logged
*Sep 26, 2026*
- **Decision:** A quantity habit is complete when the logged amount reaches the target. Partial amounts are saved in the log. The completion percentage is always calculated, never stored.
- **Why:** A stored completion value would drift out of sync with the data.
- **Rejected:** Storing a completion percentage or an `isCompleted` flag.

### Step size derived from the unit; Steps use typed entry
*Sep 26, 2026*
- **Decision:** Units come from a fixed list: glasses, minutes, steps, pages, and times. Code sets each unit's step size. The user never sets it. Steps are typed in.
- **Why:** Users shouldn't have to configure increments, and tapping +1 toward 8,000 steps is unusable.
- **Rejected:** Letting the user set the step size.

### Preset habit library plus minimal custom habits
*Sep 26, 2026*
- **Decision:** There are 10 presets. Each preset fixes its type, unit, and step size, and the user sets only the target and schedule. Custom habits are yes/no, with just a name and a schedule.
- **Why:** Setup stays fast, and the app handles the fiddly settings.
- **Rejected:** A full habit form where the user sets every field.

### Dropped the evening check-in note
*Sep 26, 2026*
- **Decision:** Remove `CheckIn.reflection` and don't replace it. Check-ins are tap-only.
- **Why:** Reflections on Home already handle free text. Having two places to write splits the data and adds friction to check-ins.
- **Rejected:** Keeping the note under a new name, `note`.

### Mood trimmed to 5 cases, sleepQuality added
*Sep 26, 2026*
- **Decision:** `Mood` becomes great, good, okay, low, rough. `CheckIn` gets a new `sleepQuality: Int?` field, rated 1 to 5 in the morning check-in.
- **Why:** The old mood options tired, stressed, and calm overlapped the energy and stress sliders. The link between sleep and habits is a core Coach insight, and HealthKit sleep data won't exist until Phase 2.
- **Rejected:** The original 9-case `Mood` enum. Waiting for HealthKit sleep data.

### docs folder kept out of the app target
*Sep 26, 2026*
- **Decision:** `docs/` and `CLAUDE.md` appear in the Xcode navigator but aren't in any target.
- **Why:** Specs shouldn't ship inside the app.
- **Rejected:** Moving docs or `CLAUDE.md` into the `Pulse/` source folder. Everything in that folder gets bundled into the app.

### Claude Code never commits, pushes, or merges
*Sep 26, 2026*
- **Decision:** `.claude/settings.json` blocks `git commit`, `git push`, `git merge`, and `git -C` commands for Claude Code. Claude Code proposes commit messages, and Joshua runs the commands.
- **Why:** Joshua reviews and owns every change.
- **Rejected:** Relying only on the CLAUDE.md instruction, with nothing enforcing it.

### Reflections live on Home, not a tab
*Before Sep 26, 2026 (from SPEC.md)*
- **Decision:** A visible button on Home opens the reflection editor. An optional reminder is off by default, toggled in Profile, and only sends on days with no reflection.
- **Why:** Reflections stay easy to find, and users don't get notification fatigue.
- **Rejected:** A dedicated Reflections tab. A daily reminder that's on by default.

### Small eval set for the Coach
*Before Sep 26, 2026 (from SPEC.md)*
- **Decision:** 20 to 30 questions with known answers, run against a fake user history. Each run checks whether the right entries were retrieved and whether answers stay faithful to the data. Results go in the README.
- **Why:** It's quality control for the Coach, not an extra feature.
- **Rejected:** Shipping the Coach without evals.

### Cut the tool-using agent Coach and the cloud vs on-device benchmark
*Before Sep 26, 2026 (from SPEC.md)*
- **Decision:** Both are listed as non-goals.
- **Why:** They're AI features for show, not for users.
- **Rejected:** Keeping them in scope to strengthen the resume.

### Two phases: local app first, backend and Coach second
*Before Sep 26, 2026 (from SPEC.md)*
- **Decision:** Phase 1 is a local SwiftData app. Phase 2 adds Supabase, Sign in with Apple, sync, and the RAG Coach.
- **Why:** An app ships sooner, and the auth and privacy work waits until it's needed.
- **Rejected:** Building everything before the first release. Still open: whether to submit to the App Store after Phase 1 or wait for Phase 2.

### Keys server-side, RLS per user, deletion reaches embeddings
*Before Sep 26, 2026 (from SPEC.md)*
- **Decision:**
  - API keys live only in Supabase Edge Functions.
  - Row Level Security isolates each user's data.
  - Deleting an entry also deletes its embedding.
- **Why:** This is personal health data.
- **Rejected:** Keys in the app binary. Calling the LLM directly from the app.

### Hybrid retrieval: vectors plus SQL aggregates
*Before Sep 26, 2026 (from SPEC.md)*
- **Decision:** Vector similarity finds relevant entries, and SQL aggregates supply stats like completion rates and averages.
- **Why:** Vectors are good at finding relevant entries, and SQL gives accurate numbers.
- **Rejected:** Vector-only retrieval.

### Render numbers to prose before embedding
*Before Sep 26, 2026 (from SPEC.md)*
- **Decision:** Numeric entries such as check-ins and habit logs are turned into natural-language sentences before they're embedded.
- **Why:** Raw numbers embed poorly.
- **Rejected:** Embedding raw numeric fields.

### Cloud first, on-device later, behind a RAGProvider protocol
*Before Sep 26, 2026 (from SPEC.md)*
- **Decision:** The Coach calls a `RAGProvider` protocol. The cloud version ships first, and an on-device version can come later.
- **Why:** Cloud is simpler to ship, and the protocol means adding on-device later won't require a rewrite.
- **Rejected:** Wiring the Coach directly to the cloud with no abstraction. Building on-device first.

### Custom RAG instead of a framework
*Before Sep 26, 2026 (from SPEC.md)*
- **Decision:** Build the RAG pipeline from scratch. Joshua leads the design and Claude Code pairs on it.
- **Why:** Building it is the interview differentiator.
- **Rejected:** Third-party RAG services.
