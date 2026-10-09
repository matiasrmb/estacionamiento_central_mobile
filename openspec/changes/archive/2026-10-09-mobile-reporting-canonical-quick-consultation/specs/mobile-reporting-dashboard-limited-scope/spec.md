# Delta for Mobile Reporting Dashboard Limited Scope

## ADDED Requirements

### Requirement: Canonical quick-consultation metric cards

Mobile MUST recognize only these quick-consultation dashboard metric keys, in this order, with these Mobile-owned labels:

| Order | Metric key | Label |
|---:|---|---|
| 1 | `operational_income_total` | `Ingresos operacionales` |
| 2 | `operational_expense_total` | `Gastos operacionales` |
| 3 | `operational_net_total` | `Neto operacional` |
| 4 | `mensualidad_sales_total` | `Mensualidades comerciales` |
| 5 | `vehicle_movement_count` | `Movimientos de vehículos` |

Mobile MUST display each card value from the dashboard API payload as received and MUST NOT locally recalculate these values from movements, mensualidades, expenses, income rows, or other records.

#### Scenario: Canonical cards render in fixed order

- GIVEN `ReportesApi.dashboard()` returns metrics for all canonical keys
- WHEN an admin opens quick consultation
- THEN Mobile SHALL render exactly those recognized cards in canonical order
- AND each card SHALL use the label mapped to its metric key.

#### Scenario: Dashboard payload owns displayed values

- GIVEN dashboard metric values differ from values derivable from local or fixture records
- WHEN Mobile renders quick-consultation metric cards
- THEN each displayed value MUST equal the matching dashboard payload value
- AND Mobile MUST NOT replace it with a locally recalculated value.

### Requirement: Dashboard-only quick consultation API boundary

Quick consultation MUST remain a dashboard-only reporting surface backed by `ReportesApi.dashboard()`. Mobile MUST NOT use `ReportesApi.movimientos()` or any closed-report, filter, sorting, pagination, export, Desktop full-center, API, Desktop, or Installer path to satisfy this feature.

#### Scenario: Dashboard endpoint is the only reporting path

- GIVEN an admin opens quick consultation
- WHEN Mobile loads reporting data
- THEN it SHALL request dashboard data through `ReportesApi.dashboard()`
- AND it MUST NOT request legacy movimientos reporting data.

#### Scenario: Out-of-scope reporting flows stay absent

- GIVEN quick consultation is rendered for any dashboard period state
- WHEN the admin views the reports screen
- THEN Mobile MUST NOT expose closed reports, filters, sorting, pagination, exports, or Desktop full-center flows
- AND no API, Desktop, or Installer behavior SHALL be required by this change.
