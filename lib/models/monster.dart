class Monster {
  final String name;
  int maxHp;
  int currentHp;
  int level;
  final String assetPath; // Placeholder for image logic
  int turnsCounter; // To track ability cooldown
  final int abilityCooldown; // E.g., 3 turns

  Monster({
    required this.name,
    required this.maxHp,
    required this.currentHp,
    required this.level,
    this.assetPath = '',
    this.turnsCounter = 0,
    this.abilityCooldown = 3,
  });

  bool get isDead => currentHp <= 0;
}
