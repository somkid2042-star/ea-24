import 'package:flutter/material.dart';

import '../data_model/category_response.dart';
import '../my_theme.dart';
import '../screens/category_list_n_product/category_products.dart';

import 'device_info.dart';

class CategoryItemCardWidget extends StatelessWidget {
  final CategoryResponse categoryResponse;
  final int index;

  const CategoryItemCardWidget({
    super.key,
    required this.categoryResponse,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    var itemWidth = ((DeviceInfo(context).width! - 48) / 3);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return CategoryProducts(
                slug: categoryResponse.categories![index].slug ?? "",
              );
            },
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            width: itemWidth,
            height: itemWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/placeholder.png',
                image: categoryResponse.categories![index].coverImage ?? '',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: itemWidth,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              categoryResponse.categories![index].name!,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                color: MyTheme.font_grey,
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final CategoryResponse categoryResponse;

  const CategoryGrid({super.key, required this.categoryResponse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: GridView.builder(
        itemCount: categoryResponse.categories!.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          return CategoryItemCardWidget(
            categoryResponse: categoryResponse,
            index: index,
          );
        },
      ),
    );
  }
}
