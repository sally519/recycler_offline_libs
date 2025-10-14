class OfflineServerInfo {
  final String packageId; // 关联的离线包ID
  final String serverUrl; // 服务器访问地址（http://127.0.0.1:8080）
  final String rootPath; // 托管的离线包根目录
  final int port; // 服务器端口
  bool isRunning; // 是否运行中

  OfflineServerInfo({
    required this.packageId,
    required this.serverUrl,
    required this.rootPath,
    required this.port,
    this.isRunning = false,
  });
}
