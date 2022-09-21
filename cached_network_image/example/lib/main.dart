import 'package:baseflow_plugin_template/baseflow_plugin_template.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:example/cancelable_cache_manage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  CachedNetworkImage.logLevel = CacheManagerLogLevel.debug;

  runApp(BaseflowPluginExample(
    pluginName: 'CachedNetworkImage',
    githubURL: 'https://github.com/Baseflow/flutter_cache_manager',
    pubDevURL: 'https://pub.dev/packages/flutter_cache_manager',
    pages: [
      BasicContent.createPage(),
      ListContent.createPage(),
      GridContent.createPage(),
    ],
  ));
}

/// Demonstrates a [StatelessWidget] containing [CachedNetworkImage]
class BasicContent extends StatefulWidget {
  const BasicContent({Key? key}) : super(key: key);

  static ExamplePage createPage() {
    return ExamplePage(Icons.image, (context) => const BasicContent());
  }

  @override
  State<BasicContent> createState() => _BasicContentState();
}

class _BasicContentState extends State<BasicContent> {
  var devicePixelRatio = 1.0;
  Size imageSize = Size.square(300);
  Size imageSizePx = Size.square(300);
  var imageUrl =
      "http://10.30.61.112:8080/annie-spratt-askpr0s66Rg-unsplash.jpg";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    imageSizePx = imageSize * devicePixelRatio;
    print("imageSizePx:$imageSizePx");
  }

  @override
  Widget build(BuildContext context) {
    var timeMs = DateTime.now().millisecondsSinceEpoch;
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CachedNetworkImage(
              width: imageSize.width,
              height: imageSize.height,
              fit: BoxFit.cover,
              progressIndicatorBuilder: (context, url, progress) => Center(
                child: CircularProgressIndicator(
                  value: progress.progress,
                ),
              ),
              imageUrl: "http://10.30.61.112:8080/monastery-7443192.jpg",
              cacheManager: CancelableCacheManage.instance(),
              maxWidthDiskCache: imageSizePx.width.toInt(),
              maxHeightDiskCache: imageSizePx.height.toInt(),
              // memCacheHeight: imageSizePx.width.toInt(),
              // memCacheWidth: imageSizePx.height.toInt(),
            ),
            CachedNetworkImage(
              width: imageSize.width,
              height: imageSize.height,
              fit: BoxFit.cover,
              progressIndicatorBuilder: (context, url, progress) => Center(
                child: CircularProgressIndicator(
                  value: progress.progress,
                ),
              ),
              imageUrl: "http://10.30.61.112:8080/monastery-7443192.jpg",
              cacheManager: CancelableCacheManage.instance(),
            ),
            // CachedNetworkImage(
            //   width: imageSize.width,
            //   height: imageSize.height,
            //   progressIndicatorBuilder: (context, url, progress) => Center(
            //     child: CircularProgressIndicator(
            //       value: progress.progress,
            //     ),
            //   ),
            //   imageUrl: "http://10.30.61.112:8080/monastery-7443192_1.5mb.jpg",
            //   cacheManager: CancelableCacheManage.instance(),
            // ),
            // CachedNetworkImage(
            //   width: imageSize.width,
            //   height: imageSize.height,
            //   progressIndicatorBuilder: (context, url, progress) => Center(
            //     child: CircularProgressIndicator(
            //       value: progress.progress,
            //     ),
            //   ),
            //   imageUrl: "http://10.30.61.112:8080/monastery-7443192_webp.webp",
            //   cacheManager: CancelableCacheManage.instance(),
            // ),
            // CachedNetworkImage(
            //   width: imageSize.width,
            //   height: imageSize.height,
            //   progressIndicatorBuilder: (context, url, progress) => Center(
            //     child: CircularProgressIndicator(
            //       value: progress.progress,
            //     ),
            //   ),
            //   imageUrl:
            //       "http://10.30.61.112:8080/monastery-7443192_webp_1.2mb.webp",
            //   cacheManager: CancelableCacheManage.instance(),
            // ),
            OutlinedButton(
                onPressed: () {
                  setState(() {});
                },
                child: Text(
                  "refresh",
                  style: TextStyle(color: Colors.white, fontSize: 30),
                )),
          ],
        ),
      ),
    );
  }

  Widget _sizedContainer(Widget child) {
    return SizedBox(
      width: 300.0,
      height: 150.0,
      child: Center(child: child),
    );
  }
}

/// Demonstrates a [ListView] containing [CachedNetworkImage]
class ListContent extends StatelessWidget {
  const ListContent({Key? key}) : super(key: key);

  static ExamplePage createPage() {
    return ExamplePage(Icons.list, (context) => const ListContent());
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) => Card(
        child: Column(
          children: <Widget>[
            CachedNetworkImage(
              imageUrl:
                  'https://source.unsplash.com/1300x1300/?book,library&i=$index',
              placeholder: (BuildContext context, String url) => Container(
                width: 320,
                height: 240,
                color: Colors.purple,
              ),
              cacheManager: CancelableCacheManage.instance(),
            ),
          ],
        ),
      ),
      itemCount: 250,
    );
  }
}

/// Demonstrates a [GridView] containing [CachedNetworkImage]
class GridContent extends StatelessWidget {
  const GridContent({Key? key}) : super(key: key);

  static ExamplePage createPage() {
    return ExamplePage(Icons.grid_on, (context) => const GridContent());
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // itemCount: 250,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (BuildContext context, int index) => CachedNetworkImage(
        imageUrl: 'https://loremflickr.com/1080/1920/music?lock=$index',
        placeholder: _loader,
        errorWidget: _error,
        cacheManager: CancelableCacheManage.instance(),
      ),
    );
  }

  Widget _loader(BuildContext context, String url) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _error(BuildContext context, String url, dynamic error) {
    return const Center(child: Icon(Icons.error));
  }
}
