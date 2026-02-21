class Monster {
  final String name;
  int maxHp;
  int currentHp;
  int level;
  final String assetPath; // Placeholder for image logic

  Monster({
    required this.name,
    required this.maxHp,
    required this.currentHp,
    required this.level,
    this.assetPath = '',
  });

  bool get isDead => currentHp <= 0;
}
