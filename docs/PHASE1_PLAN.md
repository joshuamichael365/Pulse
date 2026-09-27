# Phase 1 Plan

Approved Sep 26, 2026. Phase 1 is the local app: everything stored in SwiftData, no backend.
Each step is one feature branch off `dev`, merged through a PR. Each branch starts in plan
mode, and Joshua approves the approach before code is written. Unit tests (Swift Testing)
are written alongside each step, not saved for the end.

## Step 1. Define the check-ins (done)

Every field is one tap. There is no free text in a check-in; free text goes in Reflections
on Home.

| Field | Morning | Evening |
| --- | --- | --- |
| Sleep quality, 1 to 5 | yes | |
| Energy, 1 to 5 | yes | yes |
| Mood, single chip | yes | yes |
| Stress, 1 to 5 | | yes |

Model changes, built in step 3:

- Add `sleepQuality: Int?` to `CheckIn`. Manual input until HealthKit sleep data lands in Phase 2.
- Replace the `Mood` enum with 5 cases: `great`, `good`, `okay`, `low`, `rough`.
- Remove `CheckIn.reflection`.

## Step 2. Habits (`feature/habits`)

- Screens to create, edit, and archive habits.
- Log habits from Home.

## Step 3. Check-in flow (`feature/check-in`)

- Apply the step 1 model changes.
- Rebuild `CheckInFlowView` around the step 1 fields. Each question advances automatically on tap.
- Clean up the hardcoded strings and colors in CheckInView.

## Step 4. Home dashboard and reflection editor (`feature/dashboard`)

- Show today's habits, morning and evening check-in status, and a small streak or trend view.
- A visible button on Home opens the reflection editor.

## Step 5. Profile (`feature/profile`)

- Local "delete all data".
- Clean up the hardcoded values in ProfileView.
- Don't build the reflection reminder toggle until Joshua asks for it.

## Step 6. Onboarding with the notification ask (`feature/onboarding`)

1. Welcome.
2. Pick a few starter habits.
3. Choose morning and evening check-in times.
4. A reminders explainer that shows the times just picked, e.g. "We'll nudge you at 8:00 AM
   and 9:00 PM."
   - "Turn on reminders" shows the system permission prompt.
   - "Not now" skips the system prompt, so iOS's one-time permission prompt stays
     available for later.
5. A stored flag makes sure onboarding only shows once.

## Step 7. Check-in reminders (`feature/notifications`)

- Add `Services/Notifications`.
- Schedule local morning and evening reminders, and skip a reminder if that check-in is
  already done.
- Tapping a reminder opens the check-in flow.
- Add the reminder settings to Profile: a notifications toggle and the check-in reminder
  times.
  - If notifications were never requested, turning the toggle on shows the system prompt.
  - If permission was denied, the toggle opens iOS Settings instead.

## Step 8. App Store basics (`feature/app-store-polish`)

- **App icon.** Light, dark, and tinted versions. The slots already exist in
  `AppIcon.appiconset`. Joshua designs or approves the artwork.
- **Launch screen.** Keep the generated launch screen, but set its background color to match
  the app so there's no flash on launch.
- **Dynamic Type.** Test every screen at the accessibility text sizes and fix truncation and
  fixed frames. Cards stack vertically when text is large.
- **VoiceOver.**
  - Add labels and hints to every tap target, especially the 1 to 5 rating rows and the
    mood chips.
  - Group each card so VoiceOver reads it in a sensible order.
  - Respect Reduce Motion on the Coach `MeshGradient`.
- **Privacy and contrast.** Add a `PrivacyInfo.xcprivacy` manifest, which Apple requires
  when the app uses `UserDefaults`. Check that the lavender accent has enough contrast.

## Testing

- **Unit tests (Swift Testing), in every step.** ViewModel logic, streaks, check-in
  completion, and reminder scheduling rules.
- **UI tests (XCUIAutomation), exactly two.** Onboarding, and one full check-in.
