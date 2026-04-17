import 'package:ea24_mobile/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_config.dart';
import '../../../custom/box_decorations.dart';
import '../../../custom/device_info.dart';
import '../../../custom/lang_text.dart';
import '../../../helpers/shared_value_helper.dart';
import '../../orders/order_details.dart';
import 'image_show.dart';

class NotificationListCard extends StatefulWidget {
  final String? id;
  final String? type;
  final int? orderId;
  final String? orderCode;
  final String? status;
  final String? notificationText;
  final dynamic link;
  final String? dateTime;
  final String? image;
  final bool? isChecked;
  final Function(String, bool) onSelect;
  const NotificationListCard(
      {super.key,
      this.id,
      this.isChecked,
      this.type,
      this.orderId,
      this.orderCode,
      this.status,
      this.notificationText,
      this.link = '',
      this.dateTime,
      required this.onSelect,
      this.image});

  @override
  State<NotificationListCard> createState() => _NotificationListCardState();
}

class _NotificationListCardState extends State<NotificationListCard> {
  _onTap(context) {
    // print('ontap');

    if (widget.type == "App\\Notifications\\CustomNotification") {
      var url = widget.link?.split(AppConfig.DOMAIN_PATH).last ?? "";
      GoRouter.of(context).go(url);
    }

    if (widget.type == "App\\Notifications\\OrderNotification") {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderDetails(
                    id: widget.orderId,
                  )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        decoration: BoxDecorations.buildBoxDecoration_1(),
        margin: EdgeInsets.symmetric(horizontal: 16.0),
        width: DeviceInfo(context).width,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: Row(
            children: [
              SizedBox(
                height: 30,
                width: 30,
                child: Checkbox(
                  activeColor: MyTheme.accent_color,
                  value: widget.isChecked,
                  onChanged: (value) {
                    widget.onSelect(widget.id!, value ?? false);
                  },
                ),
              ),
              ImageShow(
                notificationShowType: notificationShowType.$,
                image: widget.image ?? "",
              ),
              SizedBox(width: 5),
              Expanded(
                // Wrap the Column with Expanded
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (widget.type == "App\\Notifications\\CustomNotification")
                      Text(
                        "${widget.notificationText}",
                        style: TextStyle(
                            color: (widget.link != '' && widget.link != null)
                                ? MyTheme.accent_color
                                : Colors.black,
                            fontSize: 16),
                      ),
                    if (widget.type == "App\\Notifications\\OrderNotification")
                      Flexible(
                        // Use Flexible instead of Expanded
                        child: RichText(
                          text: TextSpan(
                            text: LangText(context).local.your_order,
                            style: DefaultTextStyle.of(context).style,
                            children: <TextSpan>[
                              TextSpan(
                                text: "${widget.orderCode}",
                                style: TextStyle(color: MyTheme.accent_color),
                              ),
                              TextSpan(
                                text:
                                    '${LangText(context).local.has_been}${widget.status}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: 5),
                    Text(
                      '${widget.dateTime}',
                      style: TextStyle(color: MyTheme.medium_grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
