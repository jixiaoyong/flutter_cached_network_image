import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:example/resize_task.dart';
import 'package:file/file.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'cancelable_file_service.dart';

/**
 * @author : jixiaoyong
 * @description ： TODO
 * @email : jixiaoyong1995@gmail.com
 * @date : 9/21/2022
 */
class CancelableCacheManage extends CacheManager with ImageCacheManager {
  static const key = 'libCancelableCacheManage';

  static final CancelableCacheManage _cacheManage = CancelableCacheManage._();

  factory CancelableCacheManage.instance() => _cacheManage;

  static final CancelableHttpFileService _fileService =
      CancelableHttpFileService();

  CancelableCacheManage._() : super(Config(key, fileService: _fileService));

  /// Returns a resized image file to fit within maxHeight and maxWidth. It
  /// tries to keep the aspect ratio. It stores the resized image by adding
  /// the size to the key or url. For example when resizing
  /// https://via.placeholder.com/150 to max width 100 and height 75 it will
  /// store it with cacheKey resized_w100_h75_https://via.placeholder.com/150.
  ///
  /// When the resized file is not found in the cache the original is fetched
  /// from the cache or online and stored in the cache. Then it is resized
  /// and returned to the caller.
  Stream<FileResponse> getImageFile(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
    int? maxHeight,
    int? maxWidth,
  }) async* {
    if (maxHeight == null && maxWidth == null) {
      yield* getFileStream(url,
          key: key, headers: headers, withProgress: withProgress);
      return;
    }
    key ??= url;
    var resizedKey = 'resized';
    if (maxWidth != null) resizedKey += '_w$maxWidth';
    if (maxHeight != null) resizedKey += '_h$maxHeight';
    resizedKey += '_$key';

    var fromCache = await getFileFromCache(resizedKey);
    if (fromCache != null) {
      yield fromCache;
      if (fromCache.validTill.isAfter(DateTime.now())) {
        return;
      }
      withProgress = false;
    }
    var runningResize = _runningResizes[resizedKey];
    if (runningResize == null) {
      runningResize = _fetchedResizedFile(
        url,
        key,
        resizedKey,
        headers,
        withProgress,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ).asBroadcastStream();
      _runningResizes[resizedKey] = runningResize;
    }
    yield* runningResize;
    _runningResizes.remove(resizedKey);
  }

  final Map<String, Stream<FileResponse>> _runningResizes = {};
  final Queue<ResizeTask> _resizeQueue = Queue();

  Future<FileInfo> _resizeImageFile(
    FileInfo originalFile,
    String key,
    int? maxWidth,
    int? maxHeight,
  ) async {
    var originalFileName = originalFile.file.path;
    var fileExtension = originalFileName.split('.').last;
    if (!supportedFileNames.contains(fileExtension) ||
        (maxWidth == null && maxHeight == null)) {
      return originalFile;
    }

    var resizeTask = ResizeTask(originalFile.originalUrl, originalFileName,
        Size(maxWidth?.toDouble() ?? 0, maxHeight?.toDouble() ?? 0));
    _resizeQueue.add(resizeTask);
    _checkResizeQueue();

    // var image = await _decodeImage(originalFile.file);
    //
    // var shouldResize = maxWidth != null
    //     ? image.width > maxWidth
    //     : false || maxHeight != null
    //         ? image.height > maxHeight
    //         : false;
    // if (!shouldResize) return originalFile;
    // if (maxWidth != null && maxHeight != null) {
    //   var resizeFactorWidth = image.width / maxWidth;
    //   var resizeFactorHeight = image.height / maxHeight;
    //   // var resizeFactor = max(resizeFactorHeight, resizeFactorWidth);
    //   var resizeFactor = min(resizeFactorHeight, resizeFactorWidth);
    //
    //   maxWidth = (image.width / resizeFactor).round();
    //   maxHeight = (image.height / resizeFactor).round();
    // }
    //
    // var resizedFile = await _composeImage(originalFile.file.path,
    //     width: maxWidth, height: maxHeight);
    // //TODO  notice: remove origin file after compose
    // originalFile.file.delete();
    //
    // var maxAge = originalFile.validTill.difference(DateTime.now());
    //
    // var file = await putFile(
    //   originalFile.originalUrl,
    //   resizedFile,
    //   key: key,
    //   maxAge: maxAge,
    //   fileExtension: fileExtension,
    // );

    return originalFile;
    // return FileInfo(
    //   file,
    //   originalFile.source,
    //   originalFile.validTill,
    //   originalFile.originalUrl,
    // );
  }

  Stream<FileResponse> _fetchedResizedFile(
    String url,
    String originalKey,
    String resizedKey,
    Map<String, String>? headers,
    bool withProgress, {
    int? maxWidth,
    int? maxHeight,
  }) async* {
    await for (var response in getFileStream(
      url,
      key: originalKey,
      headers: headers,
      withProgress: withProgress,
    )) {
      if (response is DownloadProgress) {
        yield response;
      }
      if (response is FileInfo) {
        yield await _resizeImageFile(
          response,
          resizedKey,
          maxWidth,
          maxHeight,
        );
      }
    }
  }

  tryCancelHttpRequest(String url,
      {Map<String, String>? headers, String? requestKey}) {
    _fileService.abortRequest(url, headers: headers, requestKey: requestKey);
  }

  _composeImage(String filePath, {int? width, int? height}) {
    cacheLogger.log("compress image:${filePath} to w$width,h$height",
        CacheManagerLogLevel.verbose);
    return FlutterImageCompress.compressWithFile(filePath,
        minWidth: width ?? 1920,
        minHeight: height ?? 1080,
        format: CompressFormat.jpeg);
  }

  Future<void> _checkResizeQueue() async {
    if (_resizeQueue.isEmpty) {
      return;
    }
    // background
    await Future.delayed(Duration(milliseconds: 200));
    var task = _resizeQueue.removeFirst();
    await _composeImageFile(task);
  }

  _composeImageFile(ResizeTask task) async {
    cacheLogger.log("compress image:${task.originPath} to ${task.widgetSize}",
        CacheManagerLogLevel.verbose);
    var size = task.widgetSize;

    var file = await FlutterImageCompress.compressAndGetFile(
      task.originPath,
      task.outputPath,
      minHeight: size.height.toInt(),
      minWidth: size.width.toInt(),
    );
    if (file != null) {
      var fileLength = await file.length();
      await updateCacheFilePath(
        task.url,
        task.outputName,
        fileLength,
        key: task.key,
      );
      try {
        var originPath = io.File(task.originPath);
        originPath.delete();
      } on Exception catch (e) {
        // ignore exception
      }
      file = null;
    }
  }
}

Future<ui.Image> _decodeImage(File file,
    {int? width, int? height, bool allowUpscaling = false}) {
  var shouldResize = width != null || height != null;
  var fileImage = FileImage(file);
  final image = shouldResize
      ? ResizeImage(fileImage,
          width: width, height: height, allowUpscaling: allowUpscaling)
      : fileImage as ImageProvider;
  final completer = Completer<ui.Image>();
  image
      .resolve(const ImageConfiguration())
      .addListener(ImageStreamListener((info, _) {
    completer.complete(info.image);
    image.evict();
  }));
  return completer.future;
}
