import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OfflineLibsHelper {
  /// 获取离线包资源目录
  static Future<String> getOfflineDirPath() async {
    final dir = await getApplicationSupportDirectory(); // Android/iOS 通用
    final offlineDir = Directory('${dir.path}/offline_h5');
    if (!offlineDir.existsSync()) {
      offlineDir.createSync(recursive: true);
    }
    return offlineDir.path;
  }

  /// 获取某个离线包的目录（按版本）
  static Future<String> getPackageDir(
      String packageName, String version) async {
    final root = await getOfflineDirPath();
    final pkgDir = Directory('$root/$packageName/$version');
    if (!pkgDir.existsSync()) {
      pkgDir.createSync(recursive: true);
    }
    return pkgDir.path;
  }

  /// 获取某个离线包的当前版本（读 version.json）
  static Future<String> getCurrentVersion(String packageName) async {
    final root = await getOfflineDirPath();
    final versionFile = File('$root/$packageName/version.json');
    if (!versionFile.existsSync()) return '0.0.0';

    final jsonStr = await versionFile.readAsString();
    final json = jsonDecode(jsonStr);
    return json['version'];
  }

  /// 更新某个离线包（解压并更新 version.json）
  static Future<void> updatePackageFromZip(
    String packageName,
    String version,
    String zipPath,
  ) async {
    final pkgDir = await getPackageDir(packageName, version);

    // 解压
    final bytes = File(zipPath).readAsBytesSync();

    // 清空旧版本
    if (Directory(pkgDir).existsSync()) {
      Directory(pkgDir).deleteSync(recursive: true);
    }
    Directory(pkgDir).createSync(recursive: true);

    bool hasVersionFile = false;

    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filePath = '$pkgDir/${file.name}';
      if (file.isFile) {
        File(filePath).createSync(recursive: true);
        File(filePath).writeAsBytesSync(file.content as List<int>);

        // 检查是否有 version.json
        if (file.name == 'version.json') {
          hasVersionFile = true;
        }
      } else {
        Directory(filePath).createSync(recursive: true);
      }
    }

    // 如果 zip 里没有 version.json，就生成一个
    if (!hasVersionFile) {
      final versionFile =
          File('${(await getOfflineDirPath())}/$packageName/version.json');
      await versionFile.writeAsString(jsonEncode({
        'packageName': packageName,
        'version': version,
        'lastUpdate': DateTime.now().toIso8601String(),
      }));
    } else {
      // 如果 zip 里自带 version.json，把它拷贝到包根目录方便读取
      final versionFileInPkg = File('$pkgDir/version.json');
      if (versionFileInPkg.existsSync()) {
        final versionFile =
            File('${(await getOfflineDirPath())}/$packageName/version.json');
        await versionFile.writeAsString(await versionFileInPkg.readAsString());
      }
    }

    print("离线包 [$packageName] 已更新到版本 $version");
  }

  // static Future<void> copyZipFromAssets() async {
  //   final offlineDir = await OfflineLibsHelper.getOfflineDirPath();
  //   final zipPath = '$offlineDir/offline.zip';
  //
  //   // 如果文件已存在，可以选择跳过
  //   if (!File(zipPath).existsSync()) {
  //     print("文件不存在，开始拷贝...");
  //     final byteData = await rootBundle.load('assets/libs/dist.zip');
  //     await File(zipPath).writeAsBytes(
  //       byteData.buffer
  //           .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
  //     );
  //     print("已将 offline.zip 从 assets 拷贝到: $zipPath");
  //   } else {
  //     print("文件已存在，跳过拷贝");
  //   }
  // }
}
