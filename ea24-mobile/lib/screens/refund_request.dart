import 'package:ea24_mobile/custom/box_decorations.dart';
import 'package:ea24_mobile/custom/device_info.dart';
import 'package:ea24_mobile/custom/useful_elements.dart';
import 'package:ea24_mobile/helpers/main_helpers.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/helpers/shimmer_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/refund_request_repository.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';

class RefundRequest extends StatefulWidget {
  const RefundRequest({super.key});

  @override
  State<RefundRequest> createState() => _RefundRequestState();
}

class _RefundRequestState extends State<RefundRequest> {
  final ScrollController _xcrollController = ScrollController();
  List<dynamic> _list = [];
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
    var refundRequestResponse = await RefundRequestRepository()
        .getRefundRequestListResponse(page: _page);
    _list.addAll(refundRequestResponse.refundRequests);

    _isInitial = false;
    _totalData = refundRequestResponse.meta.total;
    _showLoadingContainer = false;
    setState(() {});
  }

  reset() {
    _list = [];
    _isInitial = true;
    _totalData = 0;
    _page = 1;
    _showLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    fetchData();
  }

  onPopped(value) async {
    reset();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
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
                        padding: const EdgeInsets.all(18.0),
                        child: buildList(),
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
              ? AppLocalizations.of(context)!.no_more_items_ucf
              : AppLocalizations.of(context)!.loading_more_items_ucf,
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
        AppLocalizations.of(context)!.refund_status_ucf,
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

  buildList() {
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
          separatorBuilder: (context, index) {
            return SizedBox(height: 14);
          },
          itemCount: _list.length,
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.all(0.0),
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return buildItemCard(index);
          },
        ),
      );
    } else if (_totalData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_data_is_available),
      );
    } else {
      return Container(); // should never be happening
    }
  }

  buildItemCard(index) {
    return Container(
      decoration: BoxDecorations.buildBoxDecoration_1(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: DeviceInfo(context).width! / 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _list[index].productName,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: MyTheme.dark_font_grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _list[index].orderCode,
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    // ignore: prefer_interpolation_to_compose_strings
                    "Date: " + _list[index].date,
                    style: TextStyle(color: MyTheme.dark_font_grey),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            Spacer(),
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      convertPrice(_list[index].productPrice),
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _list[index].refundLabel,
                    style: TextStyle(
                      color: _list[index].refundStatus == 1
                          ? Colors.green
                          : Colors.blue,
                      fontWeight: FontWeight.bold,
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
