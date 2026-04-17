import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:flutter/material.dart';

class HomeSearchBox extends StatelessWidget {
  final BuildContext? context;
  const HomeSearchBox({super.key, this.context});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          decoration: BoxDecoration(shape: BoxShape.circle),
          padding: EdgeInsets.all(0),
          child: Center(child: Image.asset('assets/app_logo_circle.png')),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color(0xfff3f3f3),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(
                    255,
                    226,
                    226,
                    226,
                  ).withValues(alpha: .12),
                  blurRadius: 15,
                  spreadRadius: 0.4,
                  offset: Offset(0.0, 5.0),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: 10),
                  Text(
                    AppConfig.search_bar_text,
                    style: TextStyle(fontSize: 13.0, color: Color(0xff7B7980)),
                  ),
                  Spacer(),
                  Image.asset(
                    'assets/search.png',
                    height: 16,
                    color: Color(0xff7B7980),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
