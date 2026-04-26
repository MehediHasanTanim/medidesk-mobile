---
name: test
description: Testing stage workflow for MediDesk-Mobile. Covers unit, integration, and manual QA across iOS and Android. Fourth stage in the feature pipeline. Gate 3 must pass before this stage begins.
---

# Stage 4: Test

**Agent:** none — this stage is primarily human-driven and tool-driven  
**Prerequisite:** Review stage complete, Gate 3 passed  
**Output:** Test report with PASS/FAIL/SKIP per case

---

## Test Layers

### Layer 1 — Static (automated, runs first)

```bash
npx tsc --noEmit                      # type safety
npx eslint src/ --max-warnings 0      # lint
npx jest --coverage --passWithNoTests # unit tests
```

All three must exit 0 before proceeding to Layer 2.

---

### Layer 2 — Unit Tests

For every new hook, utility, or non-trivial pure function introduced in this feature:

- [ ] Happy path test exists
- [ ] Error/null input test exists
- [ ] Edge case test exists (empty array, max length, boundary value)

Test file location: `__tests__/[feature-name]/` mirroring the source structure.

Run:
```bash
npx jest --testPathPattern="[feature-name]" --verbose
```

All tests must PASS. No skipped tests on new code without a written reason.

---

### Layer 3 — Integration Tests (if API-connected)

For features that call real or mocked API endpoints:

- [ ] Success response renders correctly
- [ ] 4xx error displays user-friendly message (not raw error object)
- [ ] 5xx / network timeout shows retry option or graceful fallback
- [ ] Loading state appears while request is in flight
- [ ] Empty response (200 with empty array) renders empty state, not blank screen

Use MSW or the project's existing mock server for API mocking.

---

### Layer 4 — Manual QA on Simulators

Run on both platforms before Gate 4 passes. No exceptions.

#### iOS Simulator
```bash
npx react-native run-ios
```

#### Android Emulator
```bash
npx react-native run-android
```

#### Golden Path (required PASS on both platforms)

Walk through the primary user journey for this feature end-to-end:

- [ ] Feature is reachable from the correct entry point in the app
- [ ] All data loads correctly (no blank/undefined text)
- [ ] Primary action completes successfully
- [ ] Success feedback is shown to the user
- [ ] Navigation back works correctly (no broken stack)

#### Edge Cases (required PASS on both platforms)

- [ ] Offline: feature shows appropriate error, does not crash
- [ ] Slow network (throttle to 3G in simulator): loading state visible, no timeout crash
- [ ] Empty state: feature with no data shows empty message, not blank screen
- [ ] Long content: text truncates or wraps correctly, no overflow clipping interactive elements
- [ ] Keyboard: inputs scroll above keyboard, no covered submit button

#### Platform-Specific Checks

| Check | iOS | Android |
|-------|-----|---------|
| Safe area respected (notch, home indicator) | [ ] | [ ] |
| Back navigation (gesture vs hardware button) | [ ] | [ ] |
| Font scaling (Accessibility > Larger Text) | [ ] | [ ] |
| Dark mode if supported | [ ] | [ ] |

---

### Layer 5 — Accessibility Audit

Run on device/simulator with accessibility features enabled:

- [ ] VoiceOver (iOS) / TalkBack (Android): all interactive elements are reachable and announce correctly
- [ ] All buttons have `accessibilityLabel` (not just icon-only buttons)
- [ ] Form inputs have `accessibilityLabel` matching their visible label
- [ ] Error messages are announced, not just shown visually
- [ ] Focus order is logical (top-to-bottom, left-to-right)

---

### Layer 6 — Regression Check

Run the app's existing smoke test suite to confirm nothing regressed:

```bash
npx jest --testPathPattern="smoke" --verbose
```

Manually verify the three most-used flows in the app still work:
- [ ] [Flow 1 — e.g., Login and dashboard load]
- [ ] [Flow 2 — e.g., Appointment booking]
- [ ] [Flow 3 — e.g., Patient record view]

Update this list as the app's core flows evolve.

---

## Test Report Format

```
## Test Report — [feature name]

### Static
TypeScript: PASS
ESLint: PASS
Jest unit: PASS ([n] tests, [n]% coverage on new files)

### Integration
[list each API scenario with PASS/FAIL]

### Manual QA
iOS golden path: PASS
Android golden path: PASS
[list edge cases with PASS/FAIL/SKIP + reason for any SKIP]

### Accessibility
VoiceOver: PASS
TalkBack: PASS

### Regression
Smoke suite: PASS
Manual flows: PASS

Overall: [PASS | FAIL]
Ready for: [Ship stage | Build stage (failures require fix)]
```

Save to `.claude/scratch/test-[feature-name].md`.
