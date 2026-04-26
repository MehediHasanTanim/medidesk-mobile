# ADR-003: Riverpod 2 with Code Generation for State Management

**Status:** Accepted  
**Date:** 2025-01-01

---

## Context

The app needs state management that:
1. Handles async data (streams from Drift, futures from the API) without boilerplate
2. Supports dependency injection of singletons (`AppDatabase`, `DioClient`, storage services)
3. Plays well with the `build_runner` code-generation pipeline already required for Drift and Freezed
4. Keeps providers testable in isolation

Options considered: **Riverpod 2 + riverpod_generator**, BLoC/Cubit, Provider, GetX.

---

## Decision

Use **Riverpod 2** (`flutter_riverpod: ^2.5.1`) with **`riverpod_generator`** (`@riverpod` annotations). All providers are annotation-driven; no hand-written `Provider(...)` constructors.

---

## Consequences

**Easier:**
- `@riverpod` annotations generate type-safe provider classes; no manual `ProviderContainer` wiring
- `ref.watch(streamProvider)` handles `AsyncValue` loading/error/data states with a single pattern
- Infrastructure singletons are injected via `ProviderScope` overrides in `main.dart` — easy to swap in tests
- All code generation runs in a single `build_runner` pass with Drift and Freezed

**Harder / ruled out:**
- All provider classes must extend `_$ClassName` (generated base) — the pattern is unfamiliar if you haven't used Riverpod's code-gen variant before
- `build_runner` must be re-run whenever a `@riverpod` annotated class changes its signature; forgetting produces confusing "Unknown identifier" compile errors
- Hand-writing `Provider(...)` style providers is explicitly discouraged — mixing styles makes the codebase inconsistent

**Naming convention:**  
Provider files follow `*_providers.dart`; generated output is `*_providers.g.dart`. Both are in `shared/providers/` for infrastructure and co-located with the feature for feature-scoped providers.
