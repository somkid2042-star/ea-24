import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PurchasedDigitalProductCard extends StatefulWidget
    with WidgetsBindingObserver {
  final int? id;
  final String? image;
  final String? name;

  PurchasedDigitalProductCard({super.key, this.id, this.image, this.name});

  @override
  State<PurchasedDigitalProductCard> createState() =>
      _PurchasedDigitalProductCardState();
}

class _PurchasedDigitalProductCardState
    extends State<PurchasedDigitalProductCard> {
  final ReceivePort _port = ReceivePort();

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(
      'downloader_send_port',
    );
    send?.send([id, status, progress]);
  }

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );
    _port.listen((dynamic data) {
      if (data[2] >= 100) {
        ToastComponent.showDialog("File has downloaded successfully.");
      }
      setState(() {});
    });
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1,
          child: SizedBox(
            width: double.infinity,
            child: ClipRRect(
              clipBehavior: Clip.hardEdge,
              borderRadius: BorderRadius.circular(10),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/placeholder.png',
                image: widget.image ?? 'assets/placeholder.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(0, 12, 0, 0),
          child: Text(
            widget.name ?? 'No name',
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              color: Color(0xff6B7377),
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        InkWell(
          onTap: requestDownload,
          child: Container(
            height: 24,
            width: 170,
            margin: EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Color(0xffE5411C),
              borderRadius: BorderRadius.circular(3.0),
            ),
            child: Center(
              child: Text(
                'Download',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> requestDownload() async {
    final folder = await createFolder();
    try {
      await FlutterDownloader.enqueue(
        url: '${AppConfig.BASE_URL}/purchased-products/download/${widget.id}',
        saveInPublicStorage: false,
        savedDir: folder,
        showNotification: true,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "System-Key": AppConfig.system_key,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print("Download error: $e");
      }
    }
  }

  Future<String> createFolder() async {
    final dirPath = Platform.isIOS
        ? (await getApplicationDocumentsDirectory()).path
        : "storage/emulated/0/Download/";

    final dir = Directory(dirPath);

    final status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    if (await dir.exists()) {
      return dir.path;
    } else {
      await dir.create(recursive: true);
      return dir.path;
    }
  }
}
