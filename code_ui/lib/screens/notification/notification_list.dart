import 'package:active_ecommerce_cms_demo_app/custom/device_info.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/notification_repository.dart';
import 'package:flutter/material.dart';

import '../../custom/loading.dart';
import '../../custom/toast_component.dart';
import '../../helpers/shimmer_helper.dart';
import '../../my_theme.dart';
import 'widgets/notification_card.dart';

class NotificationList extends StatefulWidget {
  const NotificationList({super.key});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  List<dynamic> _notificationList = [];
  bool _isFetching = true;
  List<String> notificationIds = [];
  bool isAllSelected = false;

  fetch() async {
    var notificationResponse = await NotificationRepository()
        .getAllNotification();
    _notificationList.addAll(notificationResponse.data as Iterable);
    _isFetching = false;
    setState(() {});
  }

  cleanAll() {
    _isFetching = true;
    notificationIds = [];
    _notificationList = [];
    isAllSelected = false;
    setState(() {});
  }

  resetAll() {
    cleanAll();
    fetch();
  }

  @override
  void initState() {
    fetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyTheme.white,
        iconTheme: IconThemeData(color: MyTheme.dark_grey),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LangText(context).local.notification_ucf,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: MyTheme.dark_font_grey,
              ),
            ),
            PopupMenuButton<int>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 1,
                  child: Text(LangText(context).local.delete_selection),
                ),
              ],
              onSelected: (value) async {
                // print('delete on selection');
                // if empty list then return
                if (notificationIds.isEmpty) {
                  ToastComponent.showDialog(
                    LangText(context).local.nothing_selected,
                  );
                  return;
                }
                // show loading and delete selected notification
                Loading.show(context);
                var notificationResponse = await NotificationRepository()
                    .notificationBulkDelete(notificationIds);
                Loading.close();
                if (notificationResponse.result) {
                  ToastComponent.showDialog(notificationResponse.message);
                }
                // reset all list
                if (notificationResponse.result) {
                  resetAll();
                }
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isFetching == false
            ? buildShowNotificationSection()
            : ShimmerHelper().buildListShimmer(itemCount: 10, itemHeight: 60.0),
      ),
    );
  }

  buildShowNotificationSection() {
    return Container(
      padding: EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _notificationList.isNotEmpty
              ? SizedBox(
                  height: 50,
                  width: DeviceInfo(context).width,
                  child: CheckboxListTile(
                    title: Text(LangText(context).local.select_all),
                    value: isAllSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        isAllSelected = value!;
                        for (var notification in _notificationList) {
                          notification.isChecked = isAllSelected;

                          if (isAllSelected) {
                            notificationIds.add(notification.id);
                          } else {
                            notificationIds = [];
                          }
                        }
                      });
                    },
                  ),
                )
              : SizedBox.shrink(),
          _notificationList.isNotEmpty
              ? Flexible(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _notificationList.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      return NotificationListCard(
                        id: _notificationList[index].id!,
                        type: _notificationList[index].type!,
                        status: _notificationList[index].data!.status,
                        orderId: _notificationList[index].data!.orderId,
                        orderCode: _notificationList[index].data!.orderCode,
                        notificationText:
                            _notificationList[index].notificationText,
                        link: _notificationList[index].data!.link,
                        dateTime: _notificationList[index].date,
                        image: _notificationList[index].image,
                        isChecked: _notificationList[index].isChecked,
                        onSelect: (String id, bool isChecked) {
                          setState(() {
                            _notificationList[index].isChecked = isChecked;
                          });
                          if (isChecked) {
                            notificationIds.add(id);
                          } else {
                            notificationIds.remove(id);
                          }
                        },
                      );
                    },
                  ),
                )
              : Center(
                  child: Text(LangText(context).local.no_notification_ucf),
                ),
        ],
      ),
    );
  }
}
