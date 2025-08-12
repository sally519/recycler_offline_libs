
import 'package:recycler_offline_libs/offline_libs/version/offline_libs.dart';

class RspOfflineLibInfo {
  List<Libs>? records;
  String? pageNumber;
  String? pageSize;
  String? totalPage;
  String? totalRow;

  RspOfflineLibInfo(
      {this.records,
      this.pageNumber,
      this.pageSize,
      this.totalPage,
      this.totalRow});

  RspOfflineLibInfo.fromJson(Map<String, dynamic> json) {
    if (json['records'] != null) {
      records = <Libs>[];
      json['records'].forEach((v) {
        records!.add(Libs.fromJson(v));
      });
    }
    pageNumber = json['pageNumber'];
    pageSize = json['pageSize'];
    totalPage = json['totalPage'];
    totalRow = json['totalRow'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (records != null) {
      data['records'] = records!.map((v) => v.toJson()).toList();
    }
    data['pageNumber'] = pageNumber;
    data['pageSize'] = pageSize;
    data['totalPage'] = totalPage;
    data['totalRow'] = totalRow;
    return data;
  }
}

class Libs extends OfflineLibs {
  String? id;
  String? appId;
  String? appName;
  int? versionNo;
  String? versionName;
  String? versionDescription;
  bool? forcedUpdate;
  List<FileList>? fileList;
  String? remark;
  String? packageId;
  int? packageType;

  Libs(
      {this.id,
      this.appId,
      this.appName,
      this.versionNo,
      this.versionName,
      this.versionDescription,
      this.forcedUpdate,
      this.fileList,
      this.remark,
      this.packageId,
      this.packageType});

  Libs.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    appId = json['appId'];
    appName = json['appName'];
    versionNo = json['versionNo'];
    versionName = json['versionName'];
    versionDescription = json['versionDescription'];
    forcedUpdate = json['forcedUpdate'];
    if (json['fileList'] != null) {
      fileList = <FileList>[];
      json['fileList'].forEach((v) {
        fileList!.add(new FileList.fromJson(v));
      });
    }
    remark = json['remark'];
    packageType = json['packageType'];
    packageId = json['packageId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['appId'] = appId;
    data['appName'] = appName;
    data['versionNo'] = versionNo;
    data['versionName'] = versionName;
    data['versionDescription'] = versionDescription;
    data['forcedUpdate'] = forcedUpdate;
    if (fileList != null) {
      data['fileList'] = fileList!.map((v) => v.toJson()).toList();
    }
    data['remark'] = remark;
    data['packageType'] = packageType;
    data['packageId'] = packageId;
    return data;
  }

  @override
  String getOfflineLibId() {
    return packageId ?? '';
  }

  @override
  String getOfflineLibsDownloadUrl() {
    return fileList?[0].url ?? '';
  }

  @override
  String getOfflineLibsMainPage() {
    return fileList?[0].path ?? '';
  }

  @override
  String getOfflineLibsVersion() {
    final match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(versionName ?? '');
    return match?.group(0) ?? '';
  }
}

class FileList {
  String? id;
  String? bucket;
  String? path;
  String? name;
  String? url;
  bool? activated;
  String? extension;
  String? contentType;
  String? size;
  String? sha512;
  String? thumbnail;

  FileList(
      {this.id,
      this.bucket,
      this.path,
      this.name,
      this.url,
      this.activated,
      this.extension,
      this.contentType,
      this.size,
      this.sha512,
      this.thumbnail});

  FileList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bucket = json['bucket'];
    path = json['path'];
    name = json['name'];
    url = json['url'];
    activated = json['activated'];
    extension = json['extension'];
    contentType = json['contentType'];
    size = json['size'];
    sha512 = json['sha512'];
    thumbnail = json['thumbnail'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['bucket'] = bucket;
    data['path'] = path;
    data['name'] = name;
    data['url'] = url;
    data['activated'] = activated;
    data['extension'] = extension;
    data['contentType'] = contentType;
    data['size'] = size;
    data['sha512'] = sha512;
    data['thumbnail'] = thumbnail;
    return data;
  }
}
