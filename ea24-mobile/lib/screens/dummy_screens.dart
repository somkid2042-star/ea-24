import 'package:flutter/material.dart';
import '../utils/app_style.dart';
import '../utils/color_utils.dart';

class DietScreen extends StatelessWidget {
  const DietScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildDummyScreen(context, 'Diet');
  }
}

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildDummyScreen(context, 'Shop');
  }
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildDummyScreen(context, 'Community');
  }
}

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildDummyScreen(context, 'Schedule');
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildDummyScreen(context, 'Profile');
  }
}

Widget _buildDummyScreen(BuildContext context, String title) {
  return Scaffold(
    backgroundColor: ColorUtils.getBackGround(context),
    appBar: AppBar(
      backgroundColor: ColorUtils.getBackGround(context),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        title,
        style: Styles.textStyle.copyWith(
          fontSize: 24.0,
          color: ColorUtils.getPrimaryText(context),
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    ),
    body: Center(
      child: Text(
        '$title Screen (Coming Soon)',
        style: Styles.textStyle.copyWith(color: ColorUtils.getSecondText(context)),
      ),
    ),
  );
}
