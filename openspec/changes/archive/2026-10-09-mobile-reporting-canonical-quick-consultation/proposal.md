# Proposal: Mobile Reporting Canonical Quick Consultation

## Intent

Harden the Mobile quick-consultation reporting contract without reopening the broader reporting center. The slice pins the canonical dashboard cards Mobile must show, proves values come from the API dashboard payload, and preserves the existing dashboard-only boundary.

## Scope

### In Scope
- Pin recognized canonical metric keys, order, and current Mobile-owned labels:
  `operational_income_total` -> `Ingresos operacionales`,
  `operational_expense_total` -> `Gastos operacionales`,
  `operational_net_total` -> `Neto operacional`,
  `mensualidad_sales_total` -> `Mensualidades comerciales`,
  `vehicle_movement_count` -> `Movimientos de vehículos`.
- Specify that Mobile displays dashboard `metrics` values as provided by `ReportesApi.dashboard()` without local recalculation.
- Keep quick consultation limited to dashboard cards, version/state context, and deferred-scope copy.
- Add or adjust focused specs/tests only where existing coverage does not already prove the contract.

### Out of Scope
- API, Desktop, Installer, database, or metric-catalog contract changes.
- Full reporting center, closed-report management, filters, sorting, pagination, exports, event sourcing, accounting, or auditor roles.
- Building quick consultation on legacy `ReportesApi.movimientos()`.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `mobile-reporting-dashboard-limited-scope`: add explicit canonical quick-consultation metric keys/order/labels and payload-owned dashboard value requirements.

## Approach

Use the reduced clarification path from exploration. Treat current production behavior as compliant unless spec-phase evidence finds a missing assertion. Preserve `ReportesApi.dashboard()` as the only reporting API path for this screen; harden requirements and focused tests around the canonical card contract and absence of Desktop-style flows.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `openspec/specs/mobile-reporting-dashboard-limited-scope/spec.md` | Modified | Add canonical metric/order/label and payload-owned value requirements via delta spec. |
| `test/features/admin/reportes/reporting_dashboard_test.dart` | Modified | Pin canonical card order, labels, endpoint path, and API-provided values if needed. |
| `test/features/admin/reportes/reportes_mensualidades_test.dart` | Modified | Preserve non-derived totals and absence of closed/export flows if needed. |
| `lib/features/admin/reportes/data/reportes_api.dart` | Modified if needed | Keep parser using recognized catalog metric keys and dashboard metric values. |
| `lib/features/admin/reportes/presentation/reportes_admin_screen.dart` | Modified if needed | Keep rendering dashboard cards only. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Overbuilding beyond quick consultation | Medium | Specs and tasks must explicitly reject closed reports, filters, exports, and legacy movimientos. |
| Duplicating already-covered behavior | Medium | Prefer spec/test hardening; avoid production-code changes unless tests expose a gap. |
| Label ownership ambiguity | Low | This proposal uses confirmed Mobile-owned labels for recognized canonical keys. |

## Rollback Plan

Revert the change delta spec and any focused test/code adjustments. Existing archived dashboard-only behavior remains intact because no API/Desktop/database changes are introduced.

## Dependencies

- Existing Mobile dashboard endpoint path through `ReportesApi.dashboard()`.
- Current Mobile-owned labels for recognized canonical metric keys.

## Success Criteria

- [ ] Delta spec pins canonical keys, order, labels, and payload-owned values.
- [ ] Focused tests prove dashboard payload values are displayed without Mobile recalculation.
- [ ] Tests/specs preserve dashboard-only scope and absence of closed-report, filter, and export flows.
