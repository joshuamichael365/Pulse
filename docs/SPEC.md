# Pulse Project Spec

Sep 26, 2026 · @Joshua Michael

## Overview

Pulse is an iOS habit tracker and wellness journal with a personal AI Coach that answers questions about your own patterns. It combines habit logs, twice daily check-ins, and free text reflections into one personal corpus, then uses a custom RAG pipeline to surface insights like how sleep relates to habit completion or mood.

The app has four tabs. Home shows the dashboard, Check In handles the twice daily check-ins, Coach is the AI chat, and Profile holds settings and privacy controls.

Repo is [github.com/joshuamichael365/Pulse](https://github.com/joshuamichael365/Pulse).

## Goals

The priority is a polished app published on the App Store that also shows real AI engineering skill.

1. Ship a clean, working app to the App Store that holds up in front of Apple recruiters.
2. Build appeal for AI engineering and AI focused SWE roles through a RAG system John leads, understands deeply, and can prove works.
3. Keep scope tight. Every feature has to make the product better, not just the resume.

### Non goals

- Learning Swift in depth. That happens through App Dev Club, so Claude Code handles most Swift implementation.
- AI features added for show, such as a tool using agent Coach or a formal cloud versus on device benchmark.
- Food logging, widgets, and Live Activities before the core app ships.

## Scope and phases

Pulse ships in two phases so a working app reaches the store before the backend and AI work lands. Whether to submit after Phase 1 or wait for Phase 2 is still open.

| Phase | What's included | Who builds it |
| --- | --- | --- |
| Phase 1, local app | Habits, twice daily check ins, reflections, Home dashboard, Profile, onboarding, all stored locally in SwiftData | Claude Code |
| Phase 2, backend and Coach | Supabase backend, Sign in with Apple, sync, cloud RAG Coach, small eval set, consent flow, account deletion | Claude Code for app and backend plumbing, John and Claude Code together on the RAG pipeline |
| Phase 2 optional | HealthKit biometrics feeding check ins | Claude Code |
| Later | On device RAG path, Passio food logging, widgets, Live Activities, Xcode Cloud | Undecided |

### Open question

- [ ] Submit to the App Store after Phase 1, or hold until the Coach ships in Phase 2?

## Design direction

Pulse should feel like a first party Apple app built on the iOS 26 Liquid Glass design language.

- Dark mode first, with light mode handled automatically through UIColor traitCollection.
- Lavender accent color #A78BFA.
- Card based layouts using .regularMaterial and .ultraThinMaterial.
- Atmospheric MeshGradient background on the Coach tab, inspired by Apple's Journal app.
- All colors, spacing, radii, and strings come from the design tokens in Constants.swift (PulseColors, PulseSpacing, PulseRadius, PulseStrings). No hardcoded values in views.
- Check In must be low friction. A full check in should take seconds, or the twice daily habit won't stick.

### Reflections

Reflections live on Home, not in their own tab.

- A visible button on Home opens the reflection editor.
- An optional reminder notification is off by default and toggled in Profile.
- The reminder only sends on days the person hasn't written a reflection yet.
- Tapping the reminder opens the reflection editor directly.

## Tech stack

| Layer | Tools | Phase |
| --- | --- | --- |
| App | Swift, SwiftUI, SwiftData, @Observable | 1 |
| Auth | Sign in with Apple via Supabase Auth | 2 |
| Backend | Supabase (PostgreSQL with pgvector), Supabase Edge Functions in TypeScript | 2 |
| Embeddings | OpenAI text-embedding-3-small | 2 |
| LLM | Called only from Edge Functions, never from the app binary | 2 |
| Health data | HealthKit | 2, optional |
| Later | Apple Foundation Models, Passio AI, WidgetKit, ActivityKit, Xcode Cloud | Later |

## Current build state

The foundation exists but no feature is complete. Next up is the Dashboard and Check In UI.

- Folder structure is feature based. Features/Habits, CheckIn, Coach, Dashboard, plus Services/Supabase, RAG, HealthKit, Notifications, Nutrition, and Models, Utilities, Resources.
- Four SwiftData models exist. Habit (with HabitCategory, HabitType, HabitFrequency enums), HabitLog, CheckIn (user fields plus biometric and nutrition fields), and Reflection (with an isEmbedded flag for RAG ingestion).
- Four @Observable ViewModels exist. HabitViewModel, CheckInViewModel, ReflectionViewModel, and CoachViewModel, which returns a simulated response for now.
- All four tab views exist as shells with Liquid Glass materials and the Coach MeshGradient.
- Constants.swift holds design tokens, and a Color(hex:) extension is in place.
- Git uses main for stable milestones and dev for active work, promoted through PRs. SSH uses the github-personal alias.

## AI architecture

The Coach runs on a custom RAG pipeline John builds in collaboration with Claude Code, behind a RAGProvider protocol so an on device path can be added later without a rewrite.

&#91;embedded content: Pulse RAG pipeline · ingestion and retrieval\]

Every entry is turned into prose and embedded on save. Every Coach question pulls matching entries plus SQL stats before the LLM answers.

### Design rules

- Numbers embed poorly, so numeric entries are rendered into natural language sentences before embedding.
- Retrieval is hybrid. Vector similarity finds relevant entries and SQL aggregates supply stats like completion rates and averages.
- API keys live only in Supabase Edge Functions, never in the app binary.
- Row Level Security isolates each user's data at the database level.
- Deleting an entry also deletes its embedding.
- Reflection.isEmbedded tracks which entries still need ingestion.
- Later option. Creating habits by chatting with the Coach captures motivation that structured forms miss.

## Evaluation

A small eval set keeps the Coach honest. It is quality control, not an extra feature.

- A fake user history covering a few weeks of habits, check ins, and reflections.
- 20 to 30 test questions with known correct answers, like which habit slipped most on low sleep days.
- Measure whether the right entries were retrieved in the top results, and whether answers stay faithful to the data instead of inventing things.
- Rerun the set whenever retrieval, prompts, or prose rendering change.
- Record results in the repo README. Before and after numbers from real changes are the strongest interview evidence.

## Privacy and App Store requirements

Sending health and journal data to a third party AI service draws close review, so plan for it from the start.

- [ ] Enroll in the Apple Developer Program early ($99 a year). If under 18, a parent or guardian must enroll.
- [ ] Write a privacy policy covering what data leaves the device and who processes it.
- [ ] Ask for explicit consent before any data is sent to the backend or OpenAI.
- [ ] Offer in app account deletion once accounts exist in Phase 2.
- [ ] Follow Apple's HealthKit rules on sharing data with third parties before adding HealthKit.
- [ ] Fill out the App Store privacy nutrition labels accurately.

## Division of work and workflow

Claude Code builds the app and backend plumbing. The RAG pipeline is a collaboration where John leads the design decisions and Claude Code pairs with him on the build. John reviews everything.

| Area | Owner |
| --- | --- |
| SwiftUI screens, onboarding, settings, polish | Claude Code |
| Supabase setup, auth, sync, account deletion | Claude Code |
| HealthKit wiring | Claude Code |
| RAGProvider protocol, prose rendering, ingestion, Edge Functions, hybrid retrieval | John leads, Claude Code pairs |
| Eval set and results | John leads, Claude Code pairs |

### Rules for working with Claude Code

- Keep a CLAUDE.md in the repo with project context and conventions.
- Start each feature in plan mode and approve the approach before code is written.
- One feature per branch off dev, merged into dev through a PR. Promote dev to main at milestones. John makes every commit and push himself. Claude Code never commits or pushes on its own.
- Before merging, John explains the diff in his own words. If he can't, it doesn't merge.
- For RAG work (Services/RAG and the RAG Edge Functions), Claude Code collaborates rather than building alone. It proposes options with tradeoffs, explains concepts as they come up, pairs with John on the code, and writes tests. John makes the final design calls and should be able to explain every line.
- Use design tokens from Constants.swift and keep the feature based folder structure.

## Interview talking points

- Why RAG was built from scratch instead of through a framework, and what that taught about chunking, recency versus relevance, and metadata filtering.
- Why numeric data is rendered to prose before embedding, backed by eval results.
- Why retrieval combines vectors with SQL stats, and what each catches that the other misses.
- How keys, RLS, consent, and deletion keep personal health data safe.
- How the RAGProvider protocol enables a future on device path, and why Apple Silicon makes on device inference realistic.
- How work was split with Claude Code, where it failed, and how those failures were caught.
