// lib/offline_libs/manager/offline_path_manager.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recycler_offline_libs/offline_libs/offline_libs_helper.dart';
import 'package:recycler_offline_libs/offline_libs/path/offline_path_info.dart';
import 'package:recycler_offline_libs/offline_libs/web_container/offline_server_manager.dart';

class OfflinePathManager {
  // 单例模式
  static final OfflinePathManager _instance = OfflinePathManager._internal();

  factory OfflinePathManager() => _instance;

  OfflinePathManager._internal();

  // 路径映射缓存
  final Map<String, OfflinePathInfo> _pathMap = {};

  // 存储路径文件
  File? _pathStorageFile;

  // 初始化
  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    final pathFile = File('${dir.path}/offline_h5/path_mapping.json');
    _pathStorageFile = pathFile;
    await _loadFromStorage();
  }

  // 从本地加载路径映射
  Future<void> _loadFromStorage() async {
    if (null != _pathStorageFile && await _pathStorageFile!.exists()) {
      try {
        final jsonStr = await _pathStorageFile!.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _pathMap.clear();
        for (var item in jsonList) {
          final info = OfflinePathInfo.fromJson(item);
          _pathMap[info.packageId] = info;
        }
      } catch (e) {
        if (kDebugMode) {
          print('加载路径映射失败: $e');
        }
      }
    }
  }

  // 保存路径映射到本地
  Future<void> _saveToStorage() async {
    try {
      if (null == _pathStorageFile || !await _pathStorageFile!.exists()) {
        final dir = await getApplicationSupportDirectory();
        final pathFile = File('${dir.path}/offline_h5/path_mapping.json');
        _pathStorageFile = pathFile;
      }
      final jsonList = _pathMap.values.map((e) => e.toJson()).toList();
      await _pathStorageFile?.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        print('保存路径映射失败: $e');
      }
    }
  }

  // 登记离线包路径信息
  Future<void> registerPath({
    required String packageId,
    required String version,
    required String rootPath,
    required String mainPageRelativePath, // 相对于rootPath的路径
  }) async {
    // 构建完整路径
    final mainPagePath = '$rootPath/$mainPageRelativePath';
    // 处理路径中的重复部分（如多个dist）

    _pathMap[packageId] = OfflinePathInfo(
      packageId: packageId,
      version: version,
      rootPath: rootPath,
      mainPagePath: mainPagePath,
    );
    await _saveToStorage();
  }

  // 获取主页面完整路径
  @Deprecated('目前版本推荐使用 getRootPath根据zip离线包的压缩路径自行拼装')
  String? getMainPagePath(String packageId) {
    final info = _pathMap[packageId];
    return 'file://${info?.mainPagePath}';
  }

  // 获取带file协议的完整路径
  @Deprecated('目前版本推荐使用 getRootPath根据zip离线包的压缩路径自行拼装')
  String? getMainPageUrl(String packageId) {
    final path = getMainPagePath(packageId);
    return path != null ? 'file://$path' : null;
  }

  // 获取离线包根目录
  String? getRootPath(String packageId) {
    return 'file://${_pathMap[packageId]?.rootPath}';
  }

  // 获取当前版本
  String? getVersion(String packageId) {
    return _pathMap[packageId]?.version;
  }

  // 在OfflinePathManager中添加
  Future<Map<String, OfflinePathInfo>> getAllPackageInfo() async {
    // 返回不可修改的副本，保护内部数据
    return Map.unmodifiable(_pathMap);
  }

  /// 根据packageId删除离线包
  /// 返回值：true-删除成功，false-删除失败
  Future<bool> deletePackage(String packageId) async {
    try {
      // 1. 停止可能运行的对应服务器
      final serverManager = OfflineServerManager();
      await serverManager.stopServer(packageId);

      // 2. 从内存缓存中移除
      final info = _pathMap.remove(packageId);
      if (info == null) {
        if (kDebugMode) {
          print('未找到packageId=$packageId的离线包信息');
        }
        return false;
      }

      // 3. 删除本地文件目录
      final offlineDir = await OfflineLibsHelper.getOfflineDirPath();
      final packageDir = Directory('$offlineDir/$packageId');
      if (await packageDir.exists()) {
        await packageDir.delete(recursive: true);
        if (kDebugMode) {
          print('成功删除packageId=$packageId的本地目录: ${packageDir.path}');
        }
      }

      // 4. 更新路径映射文件
      await _saveToStorage();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('删除离线包失败(packageId=$packageId): $e');
      }
      return false;
    }
  }
}
