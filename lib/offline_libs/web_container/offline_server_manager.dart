import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:recycler_offline_libs/offline_libs/path/offline_path_manager.dart';
import 'package:recycler_offline_libs/offline_libs/web_container/offline_server_info.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

class OfflineServerManager {
  // 单例模式
  static final OfflineServerManager _instance =
      OfflineServerManager._internal();

  factory OfflineServerManager() => _instance;

  OfflineServerManager._internal();

  // 运行中的服务器（key：packageId，value：服务器信息+实例）
  final Map<String, Map<String, dynamic>> _runningServers = {};

  // 路径管理器（关联原有路径管理）
  final OfflinePathManager _pathManager = OfflinePathManager();

  /// 1. 启动服务器（根据packageId自动获取离线包路径）
  Future<OfflineServerInfo?> startServer(String packageId) async {
    try {
      // 步骤1：检查该包是否已启动服务器
      if (_runningServers.containsKey(packageId)) {
        final info = _runningServers[packageId]!['info'] as OfflineServerInfo;
        return info.isRunning ? info : null;
      }

      // 步骤2：从路径管理器获取离线包根路径（处理file://前缀）
      final rootUrl = _pathManager.getRootPath(packageId);
      if (rootUrl == null) {
        debugPrint("启动服务器失败：未找到packageId=$packageId的离线包路径");
        return null;
      }
      final rootPath = rootUrl.replaceAll(RegExp(r'^file://'), ''); // 移除协议前缀

      // 步骤3：验证目录是否存在
      final dir = Directory(rootPath);
      if (!await dir.exists()) {
        debugPrint("启动服务器失败：离线包目录不存在，path=$rootPath");
        return null;
      }

      // 步骤4：查找可用端口（8080~8085）
      final port = await _findAvailablePort();
      if (port == -1) {
        debugPrint("启动服务器失败：无可用端口");
        return null;
      }

      // 步骤5：创建静态资源处理器（托管离线包）
      final handler = const Pipeline()
          .addMiddleware(logRequests()) // 打印请求日志（调试用，发布可删除）
          .addHandler(createStaticHandler(
            rootPath,
            defaultDocument: 'index.html', // 默认首页
            listDirectories: false, // 禁止目录列表
          ));

      // 步骤6：启动服务器（绑定本地回环地址）
      final server = await shelf_io.serve(
        handler,
        InternetAddress.loopbackIPv4, // 127.0.0.1，仅本地访问
        port,
      );
      final serverUrl = "http://${server.address.host}:${server.port}";

      // 步骤7：记录运行状态
      final serverInfo = OfflineServerInfo(
        packageId: packageId,
        serverUrl: serverUrl,
        rootPath: rootPath,
        port: port,
        isRunning: true,
      );
      _runningServers[packageId] = {
        'info': serverInfo,
        'server': server, // 保存服务器实例，用于后续关闭
      };

      debugPrint("服务器启动成功：packageId=$packageId，url=$serverUrl");
      return serverInfo;
    } catch (e) {
      debugPrint("启动服务器异常：$e");
      return null;
    }
  }

  /// 2. 关闭指定packageId的服务器
  Future<void> stopServer(String packageId) async {
    try {
      if (!_runningServers.containsKey(packageId)) return;

      // 获取服务器实例并关闭
      final serverData = _runningServers[packageId]!;
      final server = serverData['server'] as HttpServer;
      await server.close(force: true); // 强制关闭
      _runningServers.remove(packageId);

      debugPrint("服务器关闭成功：packageId=$packageId");
    } catch (e) {
      debugPrint("关闭服务器异常：$e");
    }
  }

  /// 3. 关闭所有运行中的服务器（如应用退出时调用）
  Future<void> stopAllServers() async {
    final packageIds = _runningServers.keys.toList();
    for (final packageId in packageIds) {
      await stopServer(packageId);
    }
  }

  /// 4. 查询指定packageId的服务器状态
  OfflineServerInfo? getServerStatus(String packageId) {
    if (!_runningServers.containsKey(packageId)) return null;
    return _runningServers[packageId]!['info'] as OfflineServerInfo;
  }

  /// 辅助：查找可用端口（8080~8085）
  Future<int> _findAvailablePort() async {
    const portRange = [8080, 8081, 8082, 8083, 8084, 8085, 8086, 8087, 8088];
    for (final port in portRange) {
      try {
        // 尝试绑定端口，成功则说明可用
        final tempServer = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          port,
        );
        await tempServer.close();
        return port;
      } catch (e) {
        continue; // 端口被占用，尝试下一个
      }
    }
    return -1; // 无可用端口
  }
}
