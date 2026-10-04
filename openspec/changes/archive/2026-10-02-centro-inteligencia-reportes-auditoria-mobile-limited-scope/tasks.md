# Tasks: Centro Inteligencia Reportes Auditoria Mobile Limited Scope

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 220-340 authored lines |
| 400-line budget risk | Medium |
| Chained PRs recommended | No |
| Suggested split | Single PR: RED tests -> parser boundary -> UI deferral copy -> verification |
| Delivery strategy | auto-chain |
| Chain strategy | feature-branch-chain if the implementation exceeds the 400-line budget |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: feature-branch-chain
400-line budget risk: Medium

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Deliver dashboard-only reporting scope | PR 1 | `flutter test test/features/admin/reportes/reportes_mensualidades_test.dart` | Widget/API test with mock Dio adapter; manual runtime N/A because no source changes are made in tasks phase | Revert test, parser, and reports screen files |

## Phase 1: RED Tests

- [x] 1.1 Add failing widget/API tests in `test/features/admin/reportes/reportes_mensualidades_test.dart` for admin dashboard metric cards and absence of closed-report filters, results, and export actions.
- [x] 1.2 Add failing closed-state coverage in `test/features/admin/reportes/reportes_mensualidades_test.dart` proving `period.state=closed` still shows deferred closed-report copy without retrieval or rendering flows.
- [x] 1.3 Add failing out-of-scope payload coverage in `test/features/admin/reportes/reportes_mensualidades_test.dart` proving closed/export metadata does not create buttons, links, menus, routes, or UI entry points.

## Phase 2: Parser/API Boundary

- [x] 2.1 Update `lib/features/admin/reportes/data/reportes_api.dart` so `ReportesApi.dashboard()` remains the only reporting dashboard entry point and still calls only `/reporting/metric-catalog` and `/reporting/dashboard`.
- [x] 2.2 Harden `ReportingDashboard.fromApi()` in `lib/features/admin/reportes/data/reportes_api.dart` to consume only catalog version, metric names/signs, period state, dashboard catalog version, and metric values.
- [x] 2.3 Keep `ReportingDashboard` and `ReportingMetricCard` in `lib/features/admin/reportes/data/reportes_api.dart` free of closed-report, export, download, file-format, filter, route, or metadata fields.

## Phase 3: UI Presentation

- [x] 3.1 Update `lib/features/admin/reportes/presentation/reportes_admin_screen.dart` to render dashboard cards plus neutral non-actionable copy that closed reports and exports are deferred to 1.3.x.
- [x] 3.2 Ensure `lib/features/admin/reportes/presentation/reportes_admin_screen.dart` adds no closed-report/export buttons, menus, links, forms, routes, or disabled controls.

## Phase 4: Verification

- [x] 4.1 Run `flutter test test/features/admin/reportes/reportes_mensualidades_test.dart` and record pass/fail output.
- [x] 4.2 Run `flutter test` and record pass/fail output.
- [x] 4.3 Run `flutter analyze` and record pass/fail output.
- [x] 4.4 If low disk or timeout still blocks verification, record the blocker explicitly; preflight found Windows temp free space at about 0.12 GB.
