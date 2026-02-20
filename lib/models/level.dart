class LevelProgress {
  final int levelId;
  int highScore;
  bool isUnlocked;
  int stars;

  LevelProgress({
    required this.levelId,
    this.highScore = 0,
    this.isUnlocked = false,
    this.stars = 0,
  });

  // Convert to Map for JSON storage (if needed later or for shared_preferences as JSON string)
  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'highScore': highScore,
      'isUnlocked': isUnlocked,
      'stars': stars,
    };
  }

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      levelId: json['levelId'],
      highScore: json['highScore'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
      stars: json['stars'] ?? 0,
    );
  }
}
