import 'package:ea24_mobile/custom/btn.dart';
import 'package:ea24_mobile/custom/device_info.dart';
import 'package:ea24_mobile/custom/lang_text.dart';
import 'package:ea24_mobile/custom/toast_component.dart';
import 'package:ea24_mobile/custom/useful_elements.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/helpers/shimmer_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/clubpoint_repository.dart';
import 'package:ea24_mobile/screens/wallet.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';

class Clubpoint extends StatefulWidget {
  const Clubpoint({super.key});

  @override
  State<Clubpoint> createState() => _ClubpointState();
}

class _ClubpointState extends State<Clubpoint> {
  final ScrollController _xcrollController = ScrollController();

  final List<dynamic> _list = [];
  final List<dynamic> _convertedIds = [];
  bool _isInitial = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;

  @override
  void initState() {
    super.initState();
    fetchData();
    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  fetchData() async {
    var clubpointResponse = await ClubpointRepository()
        .getClubPointListResponse(page: _page);
    setState(() {
      _list.addAll(clubpointResponse.clubpoints ?? []);
      _isInitial = false;
      _totalData = clubpointResponse.meta?.total ?? 0;
      _showLoadingContainer = false;
    });
  }

  reset() {
    setState(() {
      _list.clear();
      _convertedIds.clear();
      _isInitial = true;
      _totalData = 0;
      _page = 1;
      _showLoadingContainer = false;
    });
  }

  Future<void> _onRefresh() async {
    reset();
    fetchData();
  }

  onPressConvert(itemId, SnackBar convertedSnackbar) async {
    if (itemId == null) return;

    var clubpointToWalletResponse = await ClubpointRepository()
        .getClubpointToWalletResponse(itemId);
    if (!mounted) return;
    if (clubpointToWalletResponse.result == false) {
      ToastComponent.showDialog(clubpointToWalletResponse.message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(convertedSnackbar);
      setState(() {
        _convertedIds.add(itemId);
      });
    }
  }

  onPopped(value) async {
    reset();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    SnackBar convertedSnackbar = SnackBar(
      content: Text(
        AppLocalizations.of(context)?.points_converted_to_wallet ??
            "Points converted to wallet",
        style: TextStyle(color: MyTheme.font_grey),
      ),
      backgroundColor: MyTheme.soft_accent_color,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label:
            AppLocalizations.of(context)?.show_wallet_all_capital ??
            "SHOW WALLET",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return Wallet();
              },
            ),
          ).then((value) {
            onPopped(value);
          });
        },
        textColor: MyTheme.accent_color,
        disabledTextColor: Colors.grey,
      ),
    );

    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        body: Stack(
          children: [
            RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: Colors.white,
              onRefresh: _onRefresh,
              displacement: 0,
              child: CustomScrollView(
                controller: _xcrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: buildList(convertedSnackbar),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: buildLoadingContainer(),
            ),
          ],
        ),
      ),
    );
  }

  Container buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          _totalData == _list.length
              ? AppLocalizations.of(context)?.no_more_items_ucf ??
                    "No more items"
              : AppLocalizations.of(context)?.loading_more_items_ucf ??
                    "Loading more items",
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: UsefulElements.backButton(context),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)?.earned_points_ucf ?? "Earned Points",
        style: TextStyle(
          fontSize: 16,
          color: MyTheme.dark_font_grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildList(SnackBar convertedSnackbar) {
    if (_isInitial && _list.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildListShimmer(
          itemCount: 10,
          itemHeight: 100.0,
        ),
      );
    } else if (_list.isNotEmpty) {
      return SingleChildScrollView(
        child: ListView.separated(
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemCount: _list.length,
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.all(0.0),
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return buildItemCard(index, convertedSnackbar);
          },
        ),
      );
    } else if (_totalData == 0) {
      return Center(
        child: Text(
          AppLocalizations.of(context)?.no_data_is_available ??
              "No data available",
        ),
      );
    } else {
      return Container();
    }
  }

  Widget buildItemCard(int index, SnackBar convertedSnackbar) {
    final item = _list[index];
    return Container(
      height: 91,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: DeviceInfo(context).width! / 2.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.orderCode ?? "",
                    style: TextStyle(
                      color: MyTheme.dark_font_grey,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "${AppLocalizations.of(context)?.converted_ucf ?? "Converted"} - ",
                        style: TextStyle(
                          fontSize: 12,
                          color: MyTheme.dark_font_grey,
                        ),
                      ),
                      Text(
                        (item.convertStatus == 1 ||
                                _convertedIds.contains(item.id))
                            ? LangText(context).local.yes_ucf
                            : LangText(context).local.no_ucf,
                        style: TextStyle(
                          fontSize: 12,
                          color: item.convertStatus == 1
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "${AppLocalizations.of(context)?.date_ucf ?? "Date"} : ",
                        style: TextStyle(
                          fontSize: 12,
                          color: MyTheme.dark_font_grey,
                        ),
                      ),
                      Text(
                        item.date ?? "",
                        style: TextStyle(
                          fontSize: 12,
                          color: MyTheme.dark_font_grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: DeviceInfo(context).width! / 2.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.convertibleClubPoint?.toString() ?? "0",
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  item.convertStatus == 1 || _convertedIds.contains(item.id)
                      ? Text(
                          AppLocalizations.of(context)?.done_all_capital ??
                              "DONE",
                          style: TextStyle(
                            color: MyTheme.grey_153,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : (item.convertibleClubPoint ?? 0) <= 0
                      ? Text(
                          AppLocalizations.of(context)?.refunded_ucf ??
                              "Refunded",
                          style: TextStyle(
                            color: MyTheme.grey_153,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : SizedBox(
                          height: 24,
                          width: 80,
                          child: Btn.basic(
                            color: MyTheme.accent_color,
                            child: Text(
                              AppLocalizations.of(context)?.convert_now_ucf ??
                                  "CONVERT NOW",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            onPressed: () {
                              onPressConvert(item.id, convertedSnackbar);
                            },
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
