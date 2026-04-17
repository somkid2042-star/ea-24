import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_countdown_timer/index.dart';
import '../my_theme.dart';
import '../presenter/home_presenter.dart';

class AIZImage {
  static Widget basicImage(String url, {BoxFit fit = BoxFit.cover}) {
    return CachedNetworkImage(
      fit: fit,
      imageUrl: url,
      progressIndicatorBuilder: (context, string, progress) {
        return Image.asset(
          "assets/placeholder_rectangle.png",
          fit: BoxFit.cover,
        );
      },
      errorWidget: (context, url, error) =>
          Image.asset("assets/placeholder_rectangle.png", fit: BoxFit.cover),
    );
  }

  static Widget radiusImage(
      String? url,
      double radius, {
        BoxFit fit = BoxFit.cover,
        bool isShadow = true,
      }) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(url ?? ""),
          fit: fit,
          onError: (obj, e) {},
        ),
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white,
        boxShadow: isShadow
            ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 20,
            spreadRadius: 0.0,
            offset: Offset(0.0, 10.0),
          ),
        ]
            : [],
      ),
    );
  }

  static Widget flashdeal(
      String? url,
      double radius,
      HomePresenter homeData,
      BuildContext context, {
        BoxFit fit = BoxFit.cover,
        bool isShadow = true,
      }) {
    var featuredDeal = homeData.getFeaturedFlashDeal();
    int? endTime;
    if (featuredDeal != null && featuredDeal.date != null) {
      DateTime end = DateTime.fromMillisecondsSinceEpoch(
        featuredDeal.date! * 1000,
      );
      DateTime now = DateTime.now();
      int diff = end.difference(now).inMilliseconds;
      endTime = diff + now.millisecondsSinceEpoch;
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(url ?? ""),
              fit: fit,
              onError: (obj, e) {},
            ),
            borderRadius: BorderRadius.circular(radius),
            color: Colors.white,
            boxShadow: isShadow
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 20,
                spreadRadius: 0.0,
                offset: Offset(0.0, 10.0),
              ),
            ]
                : [],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 15,
          child: Center(child: buildMiniTimer(context, endTime ?? 0)),
        ),
      ],
    );
  }
}

Widget buildMiniTimer(BuildContext context, int endTime) {
  return CountdownTimer(
    endTime: endTime,
    widgetBuilder: (_, CurrentRemainingTime? time) {
      if (time == null) {
        return Text(
          "Ended",
          style: TextStyle(
            color: MyTheme.accent_color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        );
      }
      return Container(
        height: 20,
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timerBox(time.days ?? 0),
              _timerColon(),
              _timerBox(time.hours ?? 0),
              _timerColon(),
              _timerBox(time.min ?? 0),
              _timerColon(),
              _timerBox(time.sec ?? 0),
            ],
          ),
        ),
      );
    },
  );
}

Widget _timerBox(int value) {
  return Text(
    timeText(value.toString(), defaultLength: 2),
    style: const TextStyle(
      color: Colors.black,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget _timerColon() {
  return const Padding(
    padding: EdgeInsets.symmetric(horizontal: 2),
    child: Text(":", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  );
}

String timeText(String txt, {defaultLength = 3}) {
  var blankZeros = defaultLength == 3 ? "000" : "00";
  var leadingZeros = "";
  if (defaultLength == 3 && txt.length == 1) {
    leadingZeros = "00";
  } else if (defaultLength == 3 && txt.length == 2) {
    leadingZeros = "0";
  } else if (defaultLength == 2 && txt.length == 1) {
    leadingZeros = "0";
  }

  var newtxt = (txt == "" || txt == "null") ? blankZeros : txt;

  if (defaultLength > txt.length) {
    newtxt = leadingZeros + newtxt;
  }

  return newtxt;
}