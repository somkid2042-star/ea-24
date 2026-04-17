import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/chat_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';

class MessengerList extends StatefulWidget {
  const MessengerList({super.key});

  @override
  State<MessengerList> createState() => _MessengerListState();
}

class _MessengerListState extends State<MessengerList> {
  final ScrollController _xcrollController = ScrollController();

  final List<dynamic> _list = [];
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
    var conversatonResponse = await ChatRepository().getConversationResponse(
      page: _page,
    );
    _list.addAll(conversatonResponse.conversationItemList);
    _isInitial = false;
    _totalData = conversatonResponse.meta.total;
    _showLoadingContainer = false;
    setState(() {});
  }

  reset() {
    _list.clear();
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
                        padding: const EdgeInsets.all(16.0),
                        child: buildMessengerList(),
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
        AppLocalizations.of(context)!.messages_ucf,
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

  buildMessengerList() {
    if (_isInitial && _list.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildListShimmer(
          itemCount: 10,
          itemHeight: 100.0,
        ),
      );
    } else if (_list.isNotEmpty) {
      return SingleChildScrollView(
        child: ListView.builder(
          itemCount: _list.length,
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.all(0.0),
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(
                top: 4.0,
                bottom: 4.0,
                left: 16.0,
                right: 16.0,
              ),
              child: buildMessengerItemCard(index),
            );
          },
        ),
      );
    } else if (_totalData == 0) {
      return Center(child: Text(LangText(context).local.no_data_is_available));
    } else {
      return Container();
    }
  }

  buildMessengerItemCard(index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Chat(
                conversationId: _list[index].id,
                messengerName: _list[index].shopName,
                messengerTitle: _list[index].title,
                messengerImage: _list[index].shopLogo,
              );
            },
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Color.fromRGBO(112, 112, 112, .3),
                  width: 1,
                ),
                //shape: BoxShape.rectangle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/placeholder.png',
                  image: _list[index].shopLogo,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(
              height: 50,
              width: 230,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _list[index].shopName,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 13,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _list[index].title,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: MyTheme.medium_grey,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: MyTheme.medium_grey,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
