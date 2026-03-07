import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/meal.dart';

// SSL 인증서 오류 우회용 커스텀 클라이언트
class _BadCertClient extends http.BaseClient {
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // 웹/데스크탑에서는 HttpClient 접근 불가 → 일반 요청 사용
    return _inner.send(request);
  }
}

// HttpClient 기반 (모바일/데스크탑 네이티브 전용)
http.Client _makeClient() {
  try {
    final ctx = SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificatesBytes([]);
    // ignore: unused_local_variable
  } catch (_) {}

  final client = HttpClient()..badCertificateCallback = (_, __, ___) => true;

  return _IOClient(client);
}

// dart:io HttpClient를 http.Client로 래핑
class _IOClient extends http.BaseClient {
  final HttpClient _client;
  _IOClient(this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final ioReq = await _client.openUrl(request.method, request.url);
    request.headers.forEach(ioReq.headers.set);
    ioReq.followRedirects = request.followRedirects;
    await ioReq.addStream(request.finalize());
    final resp = await ioReq.close();
    final headers = <String, String>{};
    resp.headers.forEach((k, vs) => headers[k] = vs.join(','));
    return http.StreamedResponse(
      resp.cast(),
      resp.statusCode,
      headers: headers,
    );
  }
}

class MealService {
  static const _base = 'https://www.shingu.ac.kr';
  static const _infoPath = '/ajaxf/FR_BST_SVC/BistroInfo.do';
  static const _cartePath = '/ajaxf/FR_BST_SVC/BistroCarteInfo.do';

  static const bistros = [
    Bistro(seq: 5, name: '학생식당(미래창의관)'),
    Bistro(seq: 6, name: '교직원식당'),
    Bistro(seq: 7, name: '학생식당(서관)'),
  ];

  late final http.Client _client;

  MealService() {
    try {
      _client = _makeClient(); // 네이티브
    } catch (_) {
      _client = http.Client(); // 웹 폴백
    }
  }

  static Map<String, String> _weekRange() {
    final now = DateTime.now();
    final day = now.weekday; // 1=월 ... 7=일
    final mon = now.subtract(Duration(days: day - 1));
    final fri = mon.add(const Duration(days: 4));
    String fmt(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return {'START_DAY': fmt(mon), 'END_DAY': fmt(fri)};
  }

  Map<String, String> _params(int bistroSeq) {
    final w = _weekRange();
    return {
      'pageNo': '1',
      'MENU_ID': '1630',
      'GBN': '',
      'SITE_NO': '',
      'BOARD_SEQ': '',
      'BISTRO_SEQ': '$bistroSeq',
      'START_DAY': w['START_DAY']!,
      'END_DAY': w['END_DAY']!,
      'PREV_START_DAY': '',
      'PREV_END_DAY': '',
      'NEXT_START_DAY': '',
      'NEXT_END_DAY': '',
    };
  }

  static final _headers = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
    'Referer': 'https://www.shingu.ac.kr/cms/FR_CON/index.do?MENU_ID=1630',
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'X-Requested-With': 'XMLHttpRequest',
  };

  Future<Bistro> fetchBistroInfo(int seq) async {
    final uri = Uri.parse(
      _base + _infoPath,
    ).replace(queryParameters: _params(seq));
    final res = await _client.get(uri, headers: _headers);
    final body = jsonDecode(res.body);
    final data = body is Map ? (body['data'] ?? body) : body;
    return Bistro.fromJson(data is List ? data[0] : data);
  }

  Future<List<DayMeal>> fetchMeals(int bistroSeq) async {
    final uri = Uri.parse(
      _base + _cartePath,
    ).replace(queryParameters: _params(bistroSeq));
    final res = await _client.get(uri, headers: _headers);
    final body = jsonDecode(res.body);
    final list = body is Map ? (body['data'] ?? body) : body;
    if (list is! List) return [];
    return list.map((e) => DayMeal.fromJson(e)).toList();
  }

  void dispose() => _client.close();
}
