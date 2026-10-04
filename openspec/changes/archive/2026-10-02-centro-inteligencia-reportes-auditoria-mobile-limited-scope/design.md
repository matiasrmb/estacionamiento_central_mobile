# Design: Centro Inteligencia Reportes Auditoria Mobile Limited Scope

## Technical Approach

Constrain the Mobile reporting slice to the existing dashboard path: `ReportesApi.dashboard()` calls `/reporting/metric-catalog` and `/reporting/dashboard`, converts recognized 1.3.0 metrics into cards, and `ReportesAdminScreen` renders only those cards plus visible deferral copy for closed reports and exports. The RED tests in `reportes_mensualidades_test.dart` should pin dashboard rendering, ignored out-of-scope payload fields, absence of export/closed-report actions, and behavior when the dashboard period state is `closed`.

## Architecture Decisions

| Decision | Choice | Alternatives considered | Rationale |
|---|---|---|---|
| Dashboard-only API boundary | Keep one public `dashboard()` method and no closed/export methods. | Add disabled closed/export methods for later reuse. | No unused API surface should imply supported 1.3.0 flows. |
| Parser behavior | Parse only catalog version, metric name/sign, dashboard period state, dashboard catalog version, and metric values; ignore extra fields. | Preserve extra payload metadata on the model. | Prevents accidental UI enablement from backend fields outside this slice. |
| UI behavior | Render dashboard cards and non-actionable 1.3.x deferral copy. | Add disabled buttons or hidden routes. | Disabled controls still advertise flows; the spec requires no entry points. |
| Test focus | Extend the existing widget/API-facing test file with mock Dio adapter responses. | Add broad golden or E2E coverage. | Existing tests already validate the screen through `AppServices` and the HTTP adapter with lower review cost. |

## Data Flow

```text
ReportesAdminScreen
  └─ ReportesApi.dashboard()
       ├─ GET /reporting/metric-catalog
       └─ GET /reporting/dashboard?period_id=current&state=open
            ↓
     ReportingDashboard.fromApi()
            ↓
     metric cards + period state + catalog version
            ↓
     dashboard cards + deferral notice only
```

Closed/export metadata, if returned by the API, stops at the parser boundary and does not become model state, widgets, routes, menus, links, or buttons.

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/features/admin/reportes/data/reportes_api.dart` | Modify | Harden `ReportingDashboard.fromApi()` around supported dashboard fields only; keep endpoint use limited to metric catalog and dashboard. |
| `lib/features/admin/reportes/presentation/reportes_admin_screen.dart` | Modify | Add visible non-actionable 1.3.x deferral copy after dashboard content; do not add closed/export controls. |
| `test/features/admin/reportes/reportes_mensualidades_test.dart` | Modify | Add RED widget/API tests for dashboard-only rendering, ignored out-of-scope fields, closed period state deferral, and no export/closed-report entry points. |

## Interfaces / Contracts

No new public interfaces. The existing `ReportingDashboard` contract remains limited to:

```dart
catalogVersion: String
periodState: String
cards: List<ReportingMetricCard>
```

`ReportingMetricCard` remains metric label, numeric value, and sign only. Do not add closed-report, export, download, file format, filter, or route fields.

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Widget/API-facing | Admin sees metric cards and no closed/export entry points. | `flutter test test/features/admin/reportes/reportes_mensualidades_test.dart` with the existing mock `HttpClientAdapter`. |
| Parser boundary | Extra closed/export payload fields do not create UI-capable model state. | Exercise `ReportesAdminScreen` through adapter payloads containing out-of-scope fields and assert absence of related widgets/actions. |
| Regression | Existing monthly totals and pending close tests still pass. | Run the full focused test file. |
| Static checks | Analyzer catches API/UI mistakes. | `flutter analyze`. |

Intended verification commands:

```bash
flutter test test/features/admin/reportes/reportes_mensualidades_test.dart
flutter test
flutter analyze
```

If local execution still fails due to low disk space or timeout, verification must record the blocker and rerun after cleaning the Windows temp directory.

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary is changed.

## Migration / Rollout

No migration required. This is a Mobile-only parser, widget, and test change; Desktop, API, Installer, and printer agent remain untouched.

## Open Questions

None.
