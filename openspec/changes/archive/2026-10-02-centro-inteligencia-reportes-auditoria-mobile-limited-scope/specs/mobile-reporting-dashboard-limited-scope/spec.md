# Mobile Reporting Dashboard Limited Scope Specification

## Purpose

Define the Mobile 1.3.0 reporting slice as a dashboard-only admin feature. Closed-period reports and exports remain explicitly deferred to 1.3.x and MUST NOT be exposed as usable flows in this slice.

## Requirements

### Requirement: Dashboard-only reporting surface

The Mobile app MUST expose reporting as dashboard metric cards only, using the current operational period dashboard. It MUST NOT provide closed-period report retrieval, filters, or export actions in the 1.3.0 slice.

#### Scenario: Admin sees dashboard metrics only

- GIVEN an authenticated admin and dashboard data for the current open period
- WHEN the admin opens the reports screen
- THEN the screen SHALL render dashboard metric cards
- AND it SHALL NOT render closed-report filters, closed-report results, or export actions.

#### Scenario: Closed reporting is not activated by closed API state

- GIVEN dashboard data whose period state is closed
- WHEN the reports screen renders the response
- THEN the screen MUST still avoid closed-report retrieval or rendering
- AND it SHALL show that closed reports are deferred to 1.3.x.

### Requirement: API parser accepts only 1.3.0 dashboard fields

The Mobile reporting parser MUST consume only the 1.3.0 metric catalog and dashboard response fields needed for dashboard cards: catalog version, metric names/signs, dashboard period state, dashboard catalog version, and dashboard metric values. It MUST ignore closed-report and export fields when present.

#### Scenario: Dashboard fields produce cards

- GIVEN a metric catalog and dashboard payload with supported 1.3.0 dashboard fields
- WHEN the Mobile parser consumes both payloads
- THEN it SHALL produce dashboard card data for recognized metrics.

#### Scenario: Out-of-scope fields do not create flows

- GIVEN a dashboard payload that also includes closed-report or export metadata
- WHEN the Mobile parser consumes the payload
- THEN it MUST NOT expose parsed state that enables closed-report or export UI.

### Requirement: Deferred closed reports and exports copy

The Mobile reports UI MUST explicitly communicate that closed reports and exports are deferred to a later 1.3.x release, without adding navigation, forms, buttons, or API calls for those flows.

#### Scenario: Deferred scope is visible without actions

- GIVEN an authenticated admin on the reports screen
- WHEN dashboard content is displayed
- THEN the UI SHALL include neutral deferred-scope copy for closed reports and exports
- AND it MUST NOT include buttons, menus, or links that start those flows.

#### Scenario: Automated tests pin absence of deferred flows

- GIVEN Mobile widget and API tests for reporting
- WHEN the tests exercise dashboard rendering
- THEN they SHALL assert dashboard metrics are present
- AND they SHALL assert closed-report and export UI entry points are absent.
