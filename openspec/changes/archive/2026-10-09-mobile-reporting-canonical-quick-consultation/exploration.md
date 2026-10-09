## Exploration: mobile-reporting-canonical-quick-consultation

### Current State
The archived Mobile limited-scope reporting slice already defines dashboard-only reporting and verifies it with full `flutter test` and `flutter analyze` evidence. Current Mobile code uses `ReportesApi.dashboard()` to fetch `/reporting/metric-catalog` and `/reporting/dashboard?period_id=current&state=open`, then renders `ReportingDashboard.cards` in `ReportesAdminScreen` without closed-report or export entry points.

The current parser exposes only `catalogVersion`, `periodState`, and metric cards. It maps recognized canonical metric keys to Mobile labels and takes card values directly from the dashboard `metrics` payload. Existing tests already prove that the screen displays API-provided totals, including a non-derived case where `operational_income_total` is `76000`, `operational_expense_total` is `0`, and `operational_net_total` is `75000`.

The remaining useful slice should therefore be reduced. It should not re-open Desktop full-center reports, exports, filters, or closed-period retrieval. If pursued, the change should tighten the durable spec/test contract around quick consultation: canonical metric order/labels, payload-owned values, and the continued absence of Desktop-style flows.

### Affected Areas
- `openspec/specs/mobile-reporting-dashboard-limited-scope/spec.md` — Already captures dashboard-only scope, parser boundaries, and deferred closed/export flows; it lacks an explicit requirement naming canonical quick-consultation metrics and payload-owned totals.
- `openspec/changes/archive/2026-10-02-centro-inteligencia-reportes-auditoria-mobile-limited-scope/verify-report.md` — Proves the prior slice passed `flutter test`, focused reporting tests, and `flutter analyze`.
- `lib/features/admin/reportes/data/reportes_api.dart` — Current parser recognizes canonical metric keys and uses dashboard payload values; likely only needs changes if the API catalog now provides canonical display labels that Mobile must consume instead of the local label map.
- `lib/features/admin/reportes/presentation/reportes_admin_screen.dart` — Current quick-consultation UI renders metric cards and deferral copy only; should remain unchanged unless copy or display labels are explicitly revised.
- `test/features/admin/reportes/reporting_dashboard_test.dart` — Already tests canonical endpoint usage, catalog/dashboard version state, display labels, and API-provided values.
- `test/features/admin/reportes/reportes_mensualidades_test.dart` — Already tests payload-owned totals, absence of closed/export actions, ignored out-of-scope metadata, and closed-state deferral.
- `pubspec.yaml` and `openspec/config.yaml` — Confirm Flutter/Dart versions and available verification commands: `flutter test` and `flutter analyze`.

### Approaches
1. **Reduced spec/test clarification** — Add a small delta spec and, only if needed, focused assertions that pin canonical quick-consultation metric keys, labels, ordering, and payload-owned values.
   - Pros: Matches current implementation evidence, protects quick-consultation scope, and avoids duplicate implementation work.
   - Cons: May produce little or no production-code diff if current behavior is accepted.
   - Effort: Low

2. **Implementation refresh** — Modify parser/UI code to consume catalog-provided display labels if the API contract now includes them, while keeping dashboard values payload-owned and scope dashboard-only.
   - Pros: Better if Desktop/API canonical labels are now explicitly delivered by `metric-catalog` and Mobile must stop owning label text.
   - Cons: Requires current API contract evidence not present in this repository; risks unnecessary churn if the existing local labels are the intended Mobile presentation.
   - Effort: Medium

### Recommendation
Proceed to proposal with a reduced scope. Treat the prior limited-scope implementation as mostly complete and frame this change as a contract-hardening slice: explicitly specify canonical quick-consultation metrics, confirm values come from API dashboard payloads without Mobile recalculation, and keep Mobile away from Desktop full-center/export flows.

Before design/apply, the proposal or spec should decide one narrow point: whether canonical labels are the current Mobile label map for canonical metric keys, or whether Mobile must consume display labels from the API metric catalog. Without external API evidence, do not assume a parser rewrite is required.

### Risks
- The phrase "canonical metric labels" is ambiguous in this repository: current code uses canonical metric keys with Mobile-owned labels, while the inspected API fixture does not provide a display-label field.
- `ReportesApi.movimientos()` still exists for older movement reports, but `ReportesAdminScreen` no longer uses it for the dashboard; future work must avoid mistaking that legacy method for the quick-consultation path.
- Adding Desktop-like export or closed-report affordances would violate the archived Mobile limited-scope spec and should remain out of scope.

### Ready for Proposal
Yes — the orchestrator should tell the user this should be a reduced Mobile quick-consultation contract-hardening change, not a broad reporting implementation. The next phase should be `sdd-propose`, scoped to clarifying canonical labels/values and preserving dashboard-only behavior.
