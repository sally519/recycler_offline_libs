import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recycler_offline_libs/offline_libs/path/offline_path_manager.dart';
import 'package:recycler_offline_libs/offline_libs/version/offline_libs.dart';

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
    OfflineLibs lib,
    String zipPath,
  ) async {
    final packageName = lib.getOfflineLibId();
    final version = lib.getOfflineLibsVersion();
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
    await genericVersionFile(hasVersionFile, packageName, version, pkgDir);

    await setOfflineLibsRouterPath(lib, packageName, version, pkgDir);

    print("离线包 [$packageName] 已更新到版本 $version");
  }

  /// 设置离线包的路由路径
  /// 通过 OfflinePathManager 登记路径信息
  /// 这样可以通过包名获取主页面路径
  static Future<void> setOfflineLibsRouterPath(OfflineLibs lib,
      String packageName, String version, String pkgDir) async {
    final mainPageRelativePath = lib.getOfflineLibsMainPage();
    // 登记路径
    await OfflinePathManager().registerPath(
      packageId: packageName,
      version: version,
      rootPath: pkgDir,
      mainPageRelativePath: mainPageRelativePath,
    );
  }

  /// 生成 version.json 文件
  /// 如果 hasVersionFile 为 true，表示 zip 包里已经有 version.json 文件
  /// 则直接拷贝过去；否则生成一个新的 version.json 文件
  static Future<void> genericVersionFile(bool hasVersionFile,
      String packageName, String version, String pkgDir) async {
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
  }
}
