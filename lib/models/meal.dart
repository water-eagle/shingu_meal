class Bistro {
  final int seq;
  final String name;
  final String location;
  final String tel;
  final String operTime;

  const Bistro({
    required this.seq,
    required this.name,
    this.location = '',
    this.tel = '',
    this.operTime = '',
  });

  factory Bistro.fromJson(Map<String, dynamic> j) => Bistro(
    seq: j['BISTRO_SEQ'] ?? 0,
    name: j['BISTRO_NM'] ?? '',
    location: j['LOCATION'] ?? '',
    tel: j['TEL_NO'] ?? '',
    operTime: j['OPER_TIME'] ?? '',
  );
}

class DayMeal {
  final String stdDt; // "20260306"
  final String stdYm; // "2026.03"
  final String stdDd; // "06"
  final String stdDy; // "금요일"
  final List<MenuBlock> menus;

  const DayMeal({
    required this.stdDt,
    required this.stdYm,
    required this.stdDd,
    required this.stdDy,
    required this.menus,
  });

  bool get isToday {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return stdDt == '$y$m$d';
  }

  factory DayMeal.fromJson(Map<String, dynamic> j) {
    final menus = <MenuBlock>[];
    for (var i = 1; i <= 3; i++) {
      final nm = j['CARTE${i}_NM'];
      final cont = j['CARTE${i}_CONT'] ?? '';
      if (nm != null && nm.toString().isNotEmpty) {
        menus.add(MenuBlock(label: nm.toString(), content: cont.toString()));
      }
    }
    return DayMeal(
      stdDt: j['STD_DT']?.toString() ?? '',
      stdYm: j['STD_YM']?.toString() ?? '',
      stdDd: j['STD_DD']?.toString() ?? '',
      stdDy: j['STD_DY']?.toString() ?? '',
      menus: menus,
    );
  }
}

class MenuBlock {
  final String label;
  final String content;

  const MenuBlock({required this.label, required this.content});

  /// 빈 줄 기준으로 섹션 분리, 각 섹션은 [title, item, item, ...] 형태
  List<MenuSection> get sections {
    final parts = content.split(RegExp(r'\n\n+'));
    return parts
        .map((p) {
          final lines = p
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList();
          if (lines.isEmpty) return null;
          final hasTitle =
              lines.first.startsWith('**') && lines.first.endsWith('**');
          return MenuSection(
            title: hasTitle ? lines.first.replaceAll('**', '') : null,
            items: hasTitle ? lines.sublist(1) : lines,
          );
        })
        .whereType<MenuSection>()
        .toList();
  }
}

class MenuSection {
  final String? title;
  final List<String> items;
  const MenuSection({this.title, required this.items});
}
