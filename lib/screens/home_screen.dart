import 'dart:async';
import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';

// iOS에서 이모지가 깨지지 않도록 별도 위젯으로 분리
class _Emoji extends StatelessWidget {
  final String emoji;
  final double size;
  const _Emoji(this.emoji, {this.size = 24});

  @override
  Widget build(BuildContext context) => Text(
    emoji,
    style: TextStyle(
      fontSize: size,
      // 폰트 미지정 → OS 기본 이모지 렌더러 사용 (iOS/macOS/Android/Windows 모두 안전)
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = MealService();
  int _selectedSeq = 5;
  Bistro? _bistro;
  List<DayMeal> _meals = [];
  bool _loading = false;
  String? _error;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    // 첫 프레임 렌더 후 로딩 시작 → iOS LuLu 허용 대화상자가 뜬 뒤에도 안전
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; _attempt = 0; });
    try {
      void onRetry(int n) {
        if (mounted) setState(() => _attempt = n);
      }
      final results = await Future.wait([
        _svc.fetchBistroInfo(_selectedSeq, onRetry: onRetry),
        _svc.fetchMeals(_selectedSeq, onRetry: onRetry),
      ]);
      if (!mounted) return;
      setState(() {
        _bistro = results[0] as Bistro;
        _meals  = results[1] as List<DayMeal>;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _error = '요청 시간이 초과됐어요.\n네트워크를 확인하고 다시 시도해 주세요.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _svc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _attempt == 0 ? '불러오는 중...' : '재시도 중... ($_attempt/10)',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ))
                : _error != null
                ? _buildError()
                : _buildBody(),
          ),
        ]),
      ),
    );
  }

  // ── 헤더 ──────────────────────────────────────────
  Widget _buildHeader() {
    final now = DateTime.now();
    const days = ['일','월','화','수','목','금','토'];
    final dateStr =
        '${now.year}년 ${now.month}월 ${now.day}일 (${days[now.weekday % 7]})';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('신구대학교',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              const SizedBox(height: 2),
              Row(children: [
                const _Emoji('🍱', size: 20),
                const SizedBox(width: 6),
                const Text('급식 위젯',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 2),
              Text(dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ],
          )),
          IconButton(
            icon: _loading
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
            color: Colors.grey[400],
          ),
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: MealService.bistros.map((b) {
              final active = b.seq == _selectedSeq;
              return Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    if (_selectedSeq == b.seq) return;
                    setState(() => _selectedSeq = b.seq);
                    _load();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF1A73E8)
                          : const Color(0xFFF2F3F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(b.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : Colors.grey[600],
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // ── 에러 ──────────────────────────────────────────
  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const _Emoji('⚠️', size: 36),
        const SizedBox(height: 12),
        const Text('불러오기 실패',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(_error ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('다시 시도'),
        ),
      ]),
    ),
  );

  // ── 본문 ──────────────────────────────────────────
  Widget _buildBody() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (_bistro != null) _buildInfoCard(_bistro!),
      const SizedBox(height: 4),
      ..._meals.map(_buildDayCard),
    ],
  );

  // ── 식당 정보 카드 ────────────────────────────────
  Widget _buildInfoCard(Bistro b) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 4)
      ],
    ),
    child: Row(children: [
      const _Emoji('🏢', size: 28),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(b.name,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Wrap(spacing: 8, children: [
            if (b.location.isNotEmpty)  _metaText('📍 ${b.location}'),
            if (b.tel.isNotEmpty)       _metaText('📞 ${b.tel}'),
            if (b.operTime.isNotEmpty)  _metaText('🕐 ${b.operTime}'),
          ]),
        ],
      )),
    ]),
  );

  Widget _metaText(String t) =>
      Text(t, style: TextStyle(fontSize: 12, color: Colors.grey[600]));

  // ── 날짜 카드 ────────────────────────────────────
  Widget _buildDayCard(DayMeal m) {
    final isToday = m.isToday;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? const Color(0xFF1A73E8) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 4)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFF1A73E8)
                    : const Color(0xFFF2F3F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(m.stdDd,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isToday ? Colors.white : Colors.black87,
                          height: 1,
                        )),
                    Text(m.stdDy.replaceAll('요일', ''),
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday ? Colors.white70 : Colors.grey,
                        )),
                  ]),
            ),
            const SizedBox(width: 10),
            Text(m.stdYm,
                style:
                TextStyle(fontSize: 12, color: Colors.grey[400])),
            const Spacer(),
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('오늘',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A73E8),
                    )),
              ),
          ]),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        m.menus.isEmpty
            ? const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Text('급식 정보 없음',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        )
            : Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: m.menus
                .asMap()
                .entries
                .map((e) => _buildMenuBlock(e.value, e.key))
                .toList(),
          ),
        ),
      ]),
    );
  }

  // ── 메뉴 블록 ─────────────────────────────────────
  static const _bgColors = [
    Color(0xFFE6F4EA), Color(0xFFE8F0FE), Color(0xFFFEF3E2),
  ];
  static const _fgColors = [
    Color(0xFF1E7E34), Color(0xFF1558D6), Color(0xFFC27400),
  ];

  Widget _buildMenuBlock(MenuBlock block, int idx) {
    final bg = _bgColors[idx % 3];
    final fg = _fgColors[idx % 3];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(6)),
          child: Text(block.label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg)),
        ),
        ...block.sections.map((sec) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sec.title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(sec.title!,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey)),
              ),
            Wrap(
              spacing: 5, runSpacing: 5,
              children: sec.items
                  .map((item) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333))),
              ))
                  .toList(),
            ),
            const SizedBox(height: 6),
          ],
        )),
      ]),
    );
  }
}
