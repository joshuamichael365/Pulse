# Decision Log

A running record of Pulse's design and architecture decisions, newest first. Each entry
says what was decided, why, and which alternatives were rejected. Claude Code proposes new
entries, and Joshua approves them before they're added.

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
