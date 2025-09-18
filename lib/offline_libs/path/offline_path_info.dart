class OfflinePathInfo {
  final String packageId;
  final String version;
  final String rootPath; // 离线包根目录
  final String mainPagePath; // 主页面完整路径
  final DateTime updateTime; // 更新时间

  OfflinePathInfo({
    required this.packageId,
    required this.version,
    required this.rootPath,
    required this.mainPagePath,
    DateTime? updateTime,
  }) : updateTime = updateTime ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'packageId': packageId,
      'version': version,
      'rootPath': rootPath,
      'mainPagePath': mainPagePath,
      'updateTime': updateTime.toIso8601String(),
    };
  }

  static OfflinePathInfo fromJson(Map<String, dynamic> json) {
    return OfflinePathInfo(
      packageId: json['packageId'],
      version: json['version'],
      rootPath: json['rootPath'],
      mainPagePath: json['mainPagePath'],
      updateTime: DateTime.parse(json['updateTime']),
    );
  }
}