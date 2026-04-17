import 'package:active_ecommerce_cms_demo_app/custom/device_info.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/providers/blog_provider.dart';
import 'package:active_ecommerce_cms_demo_app/screens/blog_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();

}

class _BlogListScreenState extends State<BlogListScreen> {
  @override
  void initState() {
WidgetsBinding.instance.addPostFrameCallback((_)=>Provider.of<BlogProvider>(context,listen: false).fetchBlogs());
    super.initState();
  }

  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBlogList(context),
      backgroundColor: MyTheme.mainColor,
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0.0,
      backgroundColor: MyTheme.mainColor,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(0.0),
        child: AnimatedContainer(duration: Duration(milliseconds: 500)),
      ),
      title: buildAppBarTitle(context),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget buildAppBarTitle(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: buildAppBarTitleOption(context),
      secondChild: buildAppBarSearchOption(context),
      firstCurve: Curves.fastOutSlowIn,
      secondCurve: Curves.fastOutSlowIn,
      crossFadeState: _showSearchBar
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: Duration(milliseconds: 500),
    );
  }

  Container buildAppBarTitleOption(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 37),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: UsefulElements.backButton(context, color: "black"),
          ),
          Container(
            padding: EdgeInsets.only(left: 10),
            width: DeviceInfo(context).width! / 2,
            child: Text(
              AppLocalizations.of(context)!.all_blogs_ucf,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Spacer(),
          SizedBox(
            width: 20,
            child: GestureDetector(
              onTap: () {
                _showSearchBar = true;
                setState(() {});
              },
              child: Image.asset('assets/search.png'),
            ),
          ),
        ],
      ),
    );
  }

  Container buildAppBarSearchOption(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18),
      width: DeviceInfo(context).width,
      height: 40,
      child: TextField(
        controller: _searchController,
        onTap: () {},
        onChanged: (txt) {},
        onSubmitted: (txt) {},
        autofocus: false,
        decoration: InputDecoration(
          suffixIcon: IconButton(
            onPressed: () {
              _showSearchBar = false;
              setState(() {});
            },
            icon: Icon(Icons.clear, color: MyTheme.grey_153),
          ),
          filled: true,
          fillColor: MyTheme.white.withValues(alpha: 0.6),
          hintText: "Search in Blogs...",
          hintStyle: TextStyle(fontSize: 14.0, color: MyTheme.font_grey),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyTheme.noColor, width: 0.0),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyTheme.noColor, width: 0.0),
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: EdgeInsets.all(8.0),
        ),
      ),
    );
  }

  buildBlogList(context) {
    return Consumer<BlogProvider>(
      builder: (context, blogProvider, child) {
        if (blogProvider.isInitialLoading) {

          return MasonryGridView.count(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            itemCount: 10,
            itemBuilder: (context, index) {
              double height = index % 3 == 0 ? 280 : (index % 3 == 1 ? 320 : 260);
              return ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: ShimmerHelper().buildBasicShimmer(
                  height: height,
                  width: double.infinity,
                ),
              );
            },
          );
        }


        if (blogProvider.blogs.isEmpty) {
          return RefreshIndicator(
            onRefresh: ()async{
              await blogProvider.fetchBlogs();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children:[
                SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                Center(
                child: Text(
                  "No blogs found",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )],
            ),
          );
        }


        return RefreshIndicator(
          onRefresh: ()async{
            await blogProvider.fetchBlogs();
          },
          child: MasonryGridView.count(
            physics:const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            crossAxisCount: 2,
            itemCount: blogProvider.blogs.length,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlogDetailsScreen(
                        blog: blogProvider.blogs[index],
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    image: DecorationImage(
                      image: NetworkImage(blogProvider.blogs[index].banner),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.5),
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 113, 10, 18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                blogProvider.blogs[index].title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                blogProvider.blogs[index].shortDescription,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
