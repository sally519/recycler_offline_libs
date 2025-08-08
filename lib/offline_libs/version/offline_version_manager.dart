import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:recycler_offline_libs/offline_libs/offline_libs_helper.dart';
import 'package:recycler_offline_libs/offline_libs/version/offline_libs.dart';

abstract class OfflineVersionManager {
  // 获取所有离线包下载信息
  Future<List<OfflineLibs>> fetchAllOfflineLibs();

  // 更新所有离线包
  Future<bool> updateAllOfflineLibs() async {
    List<OfflineLibs> libs = await fetchAllOfflineLibs();
    if (kDebugMode) {
      print("需要更新的离线包数量: ${libs.length}");
    }
    for (OfflineLibs lib in libs) {
      String packageName = lib.getOfflineLibId();
      String version = lib.getOfflineLibsVersion();
      String localVersion =
          await OfflineLibsHelper.getCurrentVersion(packageName);
      if (localVersion == '0.0.0' ||
          localVersion.compareVersionTo(version) == -1) {
        String localPath = await downloadOfflineLibLocalPath(lib);
        // 如果本地版本为0.0.0或小于远程版本
        await OfflineLibsHelper.updatePackageFromZip(
          packageName,
          version,
          localPath,
        );
        // 删除下载的临时文件
        if (await File(localPath).exists()) {
          await File(localPath).delete();
        }
        if (kDebugMode) {
          print("离线包 $packageName 更新成功，版本: $version, 路径: $localPath");
        }
      } else {
        if (kDebugMode) {
          print("离线包 $packageName 已是最新版本,暂不用更新: $localVersion");
        }
      }
    }
    return true;
  }

  // 下载离线包到本地临时路径
  Future<String> downloadOfflineLibLocalPath(OfflineLibs lib) async {
    final dir = await OfflineLibsHelper.getOfflineDirPath();
    String filePath =
        "$dir/${lib.getOfflineLibId()}_${lib.getOfflineLibsVersion()}.zip";

    Dio dio = Dio();
    await dio.download(lib.getOfflineLibsDownloadUrl(), filePath);
    return filePath;
  }
}

extension VersionCompareExtension on String {
  /// 比较当前版本号和另一个版本号
  /// 返回：
  ///  -1：当前版本 < other
  ///   0：当前版本 == other
  ///   1：当前版本 > other
  int compareVersionTo(String other) {
    final aParts = split('.').map(int.parse).toList();
    final bParts = other.split('.').map(int.parse).toList();

    final length =
        [aParts.length, bParts.length].reduce((a, b) => a > b ? a : b);

    while (aParts.length < length) {
      aParts.add(0);
    }
    while (bParts.length < length) {
      bParts.add(0);
    }

    for (int i = 0; i < length; i++) {
      if (aParts[i] > bParts[i]) return 1;
      if (aParts[i] < bParts[i]) return -1;
    }
    return 0;
  }
}
