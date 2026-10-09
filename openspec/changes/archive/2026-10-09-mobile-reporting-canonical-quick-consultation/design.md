# Design: Mobile Reporting Canonical Quick Consultation

## Technical Approach

Harden the reduced Mobile quick-consultation contract primarily through focused Flutter tests and the OpenSpec delta. The implementation remains anchored on `ReportesApi.dashboard()` and the existing reports screen; production code should change only if a new or adjusted test proves the current behavior does not meet the canonical card contract.

## Architecture Decisions

| Decision | Choice | Alternatives considered | Rationale |
|---|---|---|---|
| API boundary | Keep quick consultation backed by `ReportesApi.dashboard()` only. | Reuse `ReportesApi.movimientos()` or add reporting-center endpoints. | The slice is dashboard-only and must not reopen legacy movement reports, filters, exports, or Desktop-style flows. |
| Canonical labels | Treat current Mobile-owned labels in `ReportingDashboard._metricLabels` as canonical for this slice. | Pull labels from API catalog metadata. | The proposal explicitly assigns label ownership to Mobile for the recognized keys. |
| Value ownership | Display metric values from the dashboard `metrics` payload without local recalculation. | Derive totals from movements, mensualidades, expenses, income rows, or close data. | The API dashboard payload is the source of truth for quick consultation values. |
| Implementation bias | Prefer test/spec hardening over production changes. | Rewrite the reporting model or screen. | Current code already uses dashboard data and lacks broad reporting-center behavior; changes should stay minimal and evidence-driven. |

## Data Flow

    ReportesAdminScreen
        └── ReportesApi.dashboard()
              ├── GET /reporting/metric-catalog
              └── GET /reporting/dashboard?period_id=current&state=open
                    └── ReportingDashboard.fromApi()
                          └── dashboard.metrics values + Mobile labels
                                └── _SummaryCard list

No data should flow through `ReportesApi.movimientos()` for quick consultation.

## File Changes

| File | Action | Description |
|---|---|---|
| `openspec/changes/mobile-reporting-canonical-quick-consultation/design.md` | Create | Technical design for the reduced quick-consultation hardening slice. |
| `test/features/admin/reportes/reporting_dashboard_test.dart` | Modify likely | Add or tighten tests for canonical key order, Mobile-owned labels, dashboard endpoint path, absence of `/reportes/movimientos`, unknown metric exclusion, and dashboard payload-owned values. Use a shuffled catalog or derived-value mismatch fixture to prove the contract. |
| `test/features/admin/reportes/reportes_mensualidades_test.dart` | Modify if needed | Preserve dashboard-only mensualidad totals and absence of closed-report/export/filter flows where existing assertions are insufficient. |
| `lib/features/admin/reportes/data/reportes_api.dart` | Modify only if tests fail | If canonical-order tests fail because cards follow catalog order, build cards by iterating the canonical key list and reading dashboard payload values. Keep `dashboard()` as the entry point. |
| `lib/features/admin/reportes/presentation/reportes_admin_screen.dart` | No change expected | Existing screen renders dashboard cards, version/state context, and deferred-scope copy. Modify only if tests expose non-canonical rendering. |

## Interfaces / Contracts

The quick-consultation contract remains the existing `ReportingDashboard` model:

- Recognized metric keys, in order: `operational_income_total`, `operational_expense_total`, `operational_net_total`, `mensualidad_sales_total`, `vehicle_movement_count`.
- Labels are Mobile-owned: `Ingresos operacionales`, `Gastos operacionales`, `Neto operacional`, `Mensualidades comerciales`, `Movimientos de vehículos`.
- Values come from `dashboard['metrics'][key]`; unknown metrics are ignored.
- `ReportesApi.movimientos()` is not part of quick consultation.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit/API-facing | `ReportesApi.dashboard()` requests only metric catalog and dashboard endpoints, maps canonical labels, ignores unknown metrics, and uses dashboard metric values. | Extend `reporting_dashboard_test.dart` adapter assertions, including no `/reportes/movimientos`. Add shuffled catalog and mismatched fixture values if not already covered. |
| Widget | Admin report screen renders canonical cards, version/state context, and payload-owned values. | Extend existing `ReportesAdminScreen` widget tests with all canonical labels and representative values. |
| Scope regression | Closed reports, filters, sorting, pagination, exports, and Desktop-style flows remain absent. | Keep or tighten `reportes_mensualidades_test.dart` assertions for absent UI controls and dashboard-only request paths. |

Verification commands: `flutter test`; `flutter analyze`; focused tests such as `flutter test test/features/admin/reportes/reporting_dashboard_test.dart test/features/admin/reportes/reportes_mensualidades_test.dart` if supported by the local Flutter tool.

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary is introduced.

## Migration / Rollout

No migration required. This is a Mobile-only test/spec hardening slice with no API, Desktop, Installer, or database rollout.

## Open Questions

- None.
