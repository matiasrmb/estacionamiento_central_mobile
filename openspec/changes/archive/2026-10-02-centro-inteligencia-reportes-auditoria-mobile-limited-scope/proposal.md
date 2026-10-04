# Proposal: Centro Inteligencia Reportes Auditoria Mobile Limited Scope

## Intent

Pin Mobile 1.3.0 reporting to the approved dashboard-only slice. The current screen already consumes `/reporting/metric-catalog` and `/reporting/dashboard`, but the change needs RED tests and explicit UI/API boundaries so closed-period reporting and export flows do not enter this release accidentally.

## Scope

### In Scope
- Add RED Mobile widget/API tests in `test/features/admin/reportes/reportes_mensualidades_test.dart` proving dashboard metric rendering only.
- Pin absence of closed-report and export UI for this limited-scope slice.
- Update `lib/features/admin/reportes/data/reportes_api.dart` to consume only 1.3.0 dashboard fields.
- Update `lib/features/admin/reportes/presentation/reportes_admin_screen.dart` to mark closed reports and exports deferred to 1.3.x.

### Out of Scope
- Closed-period report retrieval, filtering, or rendering.
- CSV/PDF/Excel export UI or API integration.
- Desktop, API, Installer, or printer-agent changes.

## Capabilities

### New Capabilities
- `mobile-reporting-dashboard-limited-scope`: Defines Mobile dashboard-only reporting behavior, including deferred closed/export reporting.

### Modified Capabilities
- None; no existing OpenSpec capability specs are present in this repo.

## Approach

Use TDD at the Mobile widget/API boundary: first add failing tests that prove only dashboard endpoints and metric cards are exposed, then constrain API parsing and presentation copy to 1.3.0 dashboard fields. Preserve current admin-only access and existing dashboard endpoints.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `test/features/admin/reportes/reportes_mensualidades_test.dart` | Modified | Add RED coverage for dashboard-only rendering and no closed/export UI. |
| `lib/features/admin/reportes/data/reportes_api.dart` | Modified | Limit parsing to 1.3.0 dashboard fields. |
| `lib/features/admin/reportes/presentation/reportes_admin_screen.dart` | Modified | Explicitly defer closed reports/exports to 1.3.x. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Existing `closed` state maps to a rendered closed label. | Medium | Add tests that pin limited-scope behavior and defer closed reporting. |
| Export scope creeps into Mobile 1.3.0. | Low | Test that export UI is absent. |
| `flutter test` is locally blocked by low disk space/timeout. | High | Record as environment risk; rerun after temp disk cleanup. |

## Rollback Plan

Revert the Mobile test, API parser, and presentation changes for this change folder only. Existing dashboard rendering and admin guard should remain recoverable from the prior implementation.

## Dependencies

- Mobile Flutter repo only.
- API 1.3.0 dashboard contract for `/reporting/metric-catalog` and `/reporting/dashboard`.

## Success Criteria

- [ ] RED tests exist for dashboard-only rendering and absence of closed/export UI.
- [ ] Mobile consumes only 1.3.0 dashboard fields.
- [ ] Closed reports and exports are explicitly deferred to 1.3.x.
- [ ] Test execution result or environmental blocker is recorded.
