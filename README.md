# Flutter 离线包版本管理插件

一个用于 Flutter 应用管理离线包资源的插件，支持离线包的下载、版本控制、解压更新及本地 Web 服务器托管等功能，适用于需要本地缓存 H5 资源、静态资源包并通过 HTTP 协议访问的场景。

## 功能特点

- 自动管理离线包的本地存储目录
- 支持版本号比较，智能判断是否需要更新
- 从 ZIP 包自动解压并更新离线资源
- 统一的离线包信息模型和管理接口
- 支持批量更新所有离线包
- 离线包下载解压完成后，自动记录包 ID、版本、根目录及主页面路径，路径映射信息存储在本地文件中，应用重启后无需重新登记
- 集成本地 Web 服务器，支持通过 HTTP 协议访问离线资源
- 自动映射离线包路径与服务器路由，简化资源访问流程
- 支持自定义服务器端口及启动/停止控制

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

### OfflinePathManager

离线包路径管理类，负责离线包路径的注册和查询。

主要方法：
- `registerPath(
  packageId: packageId,
  version: version,
  rootPath: rootPath,
  mainPageRelativePath: mainPageRelativePath,
  )`：在离线包下载解压完成的逻辑中（在OfflineLibsHelper的解压回调里），调用registerPath()登记路径
- `getRootPath(packageId)`: 获取解压后的离线包根目录路径
- ❌ `getMainPagePath(packageId)`: 获取离线包主页面完整路径（目前由于离线包解压路径还没有约定，暂时不支持使用）
- ❌ `getMainPageUrl(packageId)`: 获取离线包主页面 URL （目前由于离线包解压路径还没有约定，暂时不支持使用）

### LocalWebServerManager

本地 Web 服务器管理类，负责服务器的启动、停止及资源映射。

主要方法：
- `startServer({int port = 8080})`：启动本地 Web 服务器，默认端口 8080
- `stopServer()`：停止本地 Web 服务器
- `getLocalUrl(String packageId, {String relativePath = ''})`：获取离线包资源的本地 HTTP 访问地址
- `isServerRunning()`：判断服务器是否正在运行

## 使用步骤

### 1. 实现数据模型

根据服务端接json实体类实现离线包数据模型包，参考示例 `RspOfflineLibInfo`

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
  // 初始化离线包路径管理(可以不使用，但路径需自己写死)
  await OfflinePathManager().init();
}

// 初始化本地 Web 服务器
final OfflineServerManager serverManager = OfflineServerManager();

// 启动服务器
void startLocalServer() async {
  serverManager.startServer('20250923');
}

// 应用退出时停止服务器
void stopLocalServer() async {
  await webServer.stopServer();
  print('本地 Web 服务器已停止');
}

//打开离线包
void openLibs(libId) {
  Get.to(() =>
      WebviewH5Screen(
        url:
        '${serverManager
            .getServerStatus(libId)
            ?.serverUrl}/index.html',
        isFullScreen: true,
      ));
}
```

## 存储结构

离线包在设备中的存储结构如下：

```plaintext
应用支持目录/offline_h5/
  ├── path_mapping.json      # 路径映射信息文件
  ├── [packageId]/           # 离线包唯一标识目录
  │   ├── version.json       # 版本信息文件
  │   └── [version]/         # 版本号目录
  │       └── ...            # 离线包内容文件
  └── [packageId]_v1.0.0.zip # 临时下载的ZIP文件（会自动删除）
```