import 'package:dio/dio.dart';

import '../../../../core/api_error.dart';
import '../../../../core/http_client.dart';

class ReportesApi {
  final ApiClient client;

  ReportesApi(this.client);

  Future<ReportingDashboard> dashboard() async {
    try {
      final catalogResponse = await client.dio.get('/reporting/metric-catalog');
      final dashboardResponse = await client.dio.get(
        '/reporting/dashboard',
        queryParameters: {'period_id': 'current', 'state': 'open'},
      );
      return ReportingDashboard.fromApi(
        _map(catalogResponse.data, 'Formato inesperado de catálogo.'),
        _map(dashboardResponse.data, 'Formato inesperado de dashboard.'),
      );
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> movimientos({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String patente = '',
  }) async {
    try {
      final Response res = await client.dio.get(
        '/reportes/movimientos',
        queryParameters: {
          'fecha_inicio': _date(fechaInicio),
          'fecha_fin': _date(fechaFin),
          if (patente.trim().isNotEmpty)
            'patente': patente.trim().toUpperCase(),
        },
      );
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw ApiException('Formato inesperado de reportes.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  String _date(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<String, dynamic> _map(dynamic data, String message) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException(message);
  }
}

class ReportingDashboard {
  static const appVersionLabel = '1.3.0';

  final String catalogVersion;
  final String periodState;
  final List<ReportingMetricCard> cards;

  const ReportingDashboard({
    required this.catalogVersion,
    required this.periodState,
    required this.cards,
  });

  String get appVersion => appVersionLabel;

  factory ReportingDashboard.fromApi(
    Map<String, dynamic> catalog,
    Map<String, dynamic> dashboard,
  ) {
    final metrics = _stringMap(dashboard['metrics']);
    final catalogMetrics = catalog['metrics'] is List
        ? List<Map<String, dynamic>>.from(
            (catalog['metrics'] as List).map(
              (item) => Map<String, dynamic>.from(item as Map),
            ),
          )
        : <Map<String, dynamic>>[];

    final cards = <ReportingMetricCard>[
      for (final metric in catalogMetrics)
        if (_metricLabels.containsKey(metric['name']))
          ReportingMetricCard(
            metric: '${metric['name']}',
            label: _metricLabels['${metric['name']}']!,
            value: _num(metrics[metric['name']]),
            sign: '${metric['sign'] ?? ''}',
          ),
    ];

    return ReportingDashboard(
      catalogVersion:
          '${catalog['version'] ?? dashboard['catalog_version'] ?? '-'}',
      periodState: '${_stringMap(dashboard['period'])['state'] ?? '-'}',
      cards: cards,
    );
  }

  static Map<String, dynamic> _stringMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static num _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse('${value ?? 0}') ?? 0;
  }

  static const _metricLabels = {
    'operational_income_total': 'Ingresos operacionales',
    'operational_expense_total': 'Gastos operacionales',
    'operational_net_total': 'Neto operacional',
    'mensualidad_sales_total': 'Mensualidades comerciales',
    'vehicle_movement_count': 'Movimientos de vehículos',
  };
}

class ReportingMetricCard {
  final String metric;
  final String label;
  final num value;
  final String sign;

  const ReportingMetricCard({
    required this.metric,
    required this.label,
    required this.value,
    required this.sign,
  });
}
