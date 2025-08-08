# Flutter 离线包版本管理插件

一个用于 Flutter 应用管理离线包资源的插件，支持离线包的下载、版本控制、解压更新等功能，适用于需要本地缓存
H5 资源、静态资源包等场景。

## 功能特点

- 自动管理离线包的本地存储目录
- 支持版本号比较，智能判断是否需要更新
- 从 ZIP 包自动解压并更新离线资源
- 统一的离线包信息模型和管理接口
- 支持批量更新所有离线包

## 核心类说明

### OfflineLibsHelper

离线包存储管理工具类，负责目录创建、版本读取和 ZIP 包解压更新。

主要方法：

- `getOfflineDirPath()`：获取离线包根目录路径
- `getPackageDir()`：获取指定包名和版本的存储目录
- `getCurrentVersion()`：读取本地已安装的离线包版本
- `updatePackageFromZip()`：从 ZIP 文件更新离线包并维护版本信息

### OfflineLibs

离线包信息抽象接口，定义了离线包的基本信息规范，使用时实体离线包类继承次类实现离线包必须的属性。

主要方法：

- `getOfflineLibId()`：获取离线包唯一标识
- `getOfflineLibsVersion()`：获取离线包版本号
- `getOfflineLibsDownloadUrl()`：获取下载地址
- `getOfflineLibsMainPage()`：获取主页面路径

### RspOfflineLibInfo

服务端返回的离线包信息数据模型，包含：

- 分页信息（pageNumber、pageSize 等）
- 离线包列表（records）
- 离线包详细信息（Libs）和文件信息（FileList）

### OfflineVersionManager

离线包版本管理抽象类，提供核心业务逻辑。

主要方法：

- `fetchAllOfflineLibs()`：获取所有离线包信息（需子类实现）
- `updateAllOfflineLibs()`：批量更新所有需要更新的离线包
- `downloadOfflineLibLocalPath()`：下载离线包到本地临时路径

## 使用步骤

### 1. 实现数据模型

根据服务端接口格式，参考示例 `RspOfflineLibInfo` 

### 2. 实现 OfflineVersionManager 子类

```dart
class MyOfflineVersionManager extends OfflineVersionManager {
  @override
  Future<List<OfflineLibs>> fetchAllOfflineLibs() async {
    // 实现从服务端获取离线包列表的逻辑
    final response = await Dio().get('你的离线包列表接口');
    List<OfflineLibs> rsp = RspOfflineLibInfo.fromJson(response.data);
    return rsp;
  }
}
```

### 3. 初始化并使用

```dart
// 创建版本管理器实例
final versionManager = MyOfflineVersionManager();

// 检查并更新所有离线包
void checkAndUpdateOfflineLibs() async {
  bool result = await versionManager.updateAllOfflineLibs();
  if (result) {
    print('离线包更新完成');
  }
}

// 获取指定离线包的本地版本
void getLocalVersion(String packageId) async {
  String version = await OfflineLibsHelper.getCurrentVersion(packageId);
  print('当前版本: $version');
}

```

## 存储结构

离线包在设备中的存储结构如下：

```plaintext
应用支持目录/offline_h5/
  ├── [packageId]/           # 离线包唯一标识目录
  │   ├── version.json       # 版本信息文件
  │   └── [version]/         # 版本号目录
  │       └── ...            # 离线包内容文件
  └── [packageId]_v1.0.0.zip # 临时下载的ZIP文件（会自动删除）
```