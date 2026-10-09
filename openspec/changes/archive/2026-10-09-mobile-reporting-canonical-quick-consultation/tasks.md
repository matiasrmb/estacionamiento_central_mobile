# Tasks: Mobile Reporting Canonical Quick Consultation

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 90-160 authored lines |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR: RED contract tests -> minimal GREEN fix if needed -> verification |
| Delivery strategy | auto-chain |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: stacked-to-main
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Pin quick-consultation contract tests | PR 1 | `flutter test test/features/admin/reportes/reporting_dashboard_test.dart test/features/admin/reportes/reportes_mensualidades_test.dart` | Widget/API-facing Flutter tests with mocked `HttpClientAdapter` | Revert reporting test edits only |
| 2 | Apply minimal canonical-order fix only if RED | PR 1 | Same focused command | N/A; production change is test-driven parser behavior only | Revert `lib/features/admin/reportes/data/reportes_api.dart` without UI changes |

## Phase 1: RED Contract Tests

- [x] 1.1 Update `test/features/admin/reportes/reporting_dashboard_test.dart` so a shuffled metric catalog plus an unknown metric fails unless cards render exactly the five canonical keys in fixed order with Mobile-owned labels.
- [x] 1.2 Update `test/features/admin/reportes/reporting_dashboard_test.dart` so dashboard metric values intentionally differ from fixture-derived totals and displayed/model values must equal `dashboard['metrics']`.
- [x] 1.3 Update `test/features/admin/reportes/reporting_dashboard_test.dart` adapter assertions to fail on `/reportes/movimientos` and to require only `/reporting/metric-catalog` then `/reporting/dashboard` for quick consultation.
- [x] 1.4 Tighten `test/features/admin/reportes/reportes_mensualidades_test.dart` only if existing assertions do not cover closed reports, filters, sorting, pagination, exports, and Desktop full-center absence.

## Phase 2: Minimal GREEN Implementation

- [x] 2.1 Modify `lib/features/admin/reportes/data/reportes_api.dart` only if Phase 1 fails because `ReportingDashboard.fromApi()` follows catalog order; iterate the canonical key list and read values from dashboard metrics.
- [x] 2.2 Keep `ReportesApi.dashboard()` as the entry point and do not add, call, or route through `ReportesApi.movimientos()` for quick consultation.
- [x] 2.3 Leave `lib/features/admin/reportes/presentation/reportes_admin_screen.dart` unchanged unless a RED widget test proves dashboard-only rendering violates the spec.

## Phase 3: Verification

- [x] 3.1 Run focused verification: `flutter test test/features/admin/reportes/reporting_dashboard_test.dart test/features/admin/reportes/reportes_mensualidades_test.dart` if supported by the local Flutter tool.
- [x] 3.2 Run full regression: `flutter test`.
- [x] 3.3 Run static analysis: `flutter analyze`.

## Phase 4: Scope Guard

- [x] 4.1 Confirm the final diff contains no API, Desktop, Installer, export, pagination, sorting, filter, closed-report, or legacy movimientos quick-consultation implementation changes.
