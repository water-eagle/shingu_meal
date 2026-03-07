import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _svc.fetchBistroInfo(_selectedSeq),
        _svc.fetchMeals(_selectedSeq),
      ]);
      setState(() {
        _bistro = results[0] as Bistro;
        _meals = results[1] as List<DayMeal>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildError()
                  : _buildBody(cs),
            ),
          ],
        ),
      ),
    );
  }

  // ── 헤더 ──────────────────────────────────────────
  Widget _buildHeader(ColorScheme cs) {
    final now = DateTime.now();
    final days = ['일', '월', '화', '수', '목', '금', '토'];
    final dateStr =
        '${now.year}년 ${now.month}월 ${now.day}일 (${days[now.weekday % 7]})';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '신구대학교',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '🍱 급식 위젯',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                onPressed: _loading ? null : _load,
                color: Colors.grey[400],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 식당 탭
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MealService.bistros.map((b) {
                final active = b.seq == _selectedSeq;
                return Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedSeq = b.seq);
                      _load();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF1A73E8)
                            : const Color(0xFFF2F3F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        b.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── 에러 ──────────────────────────────────────────
  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⚠️', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 8),
        const Text(
          '불러오기 실패',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          _error ?? '',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('다시 시도')),
      ],
    ),
  );

  // ── 본문 ──────────────────────────────────────────
  Widget _buildBody(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_bistro != null) _buildInfoCard(_bistro!),
        const SizedBox(height: 4),
        ..._meals.map(_buildDayCard),
      ],
    );
  }

  // ── 식당 정보 카드 ────────────────────────────────
  Widget _buildInfoCard(Bistro b) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 4),
      ],
    ),
    child: Row(
      children: [
        const Text('🏢', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  if (b.location.isNotEmpty) _metaChip('📍 ${b.location}'),
                  if (b.tel.isNotEmpty) _metaChip('📞 ${b.tel}'),
                  if (b.operTime.isNotEmpty) _metaChip('🕐 ${b.operTime}'),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _metaChip(String text) =>
      Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600]));

  // ── 날짜 카드 ────────────────────────────────────
  Widget _buildDayCard(DayMeal m) {
    final isToday = m.isToday;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: const Color(0xFF1A73E8), width: 2)
            : Border.all(color: Colors.transparent, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF1A73E8)
                        : const Color(0xFFF2F3F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        m.stdDd,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isToday ? Colors.white : Colors.black87,
                          height: 1,
                        ),
                      ),
                      Text(
                        m.stdDy.replaceAll('요일', ''),
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday ? Colors.white70 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  m.stdYm,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '오늘',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 메뉴
          if (m.menus.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(
                '급식 정보 없음',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            )
          else
            Padding(
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
        ],
      ),
    );
  }

  // ── 메뉴 블록 ─────────────────────────────────────
  static const _labelColors = [
    Color(0xFFE6F4EA),
    Color(0xFFE8F0FE),
    Color(0xFFFEF3E2),
  ];
  static const _labelTextColors = [
    Color(0xFF1E7E34),
    Color(0xFF1558D6),
    Color(0xFFC27400),
  ];

  Widget _buildMenuBlock(MenuBlock block, int idx) {
    final bgColor = _labelColors[idx % 3];
    final textColor = _labelTextColors[idx % 3];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 라벨
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              block.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          // 섹션들
          ...block.sections.map(
            (sec) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sec.title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      sec.title!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: sec.items
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
