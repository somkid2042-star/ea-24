import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/quiz/cubits/get_contest_leaderboard_cubit.dart';
import 'package:flutterquiz/features/quiz/models/contest_leaderboard.dart';
import 'package:flutterquiz/features/quiz/quiz_remote_data_source.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';
import 'package:flutterquiz/ui/widgets/circular_progress_container.dart';
import 'package:flutterquiz/ui/widgets/custom_appbar.dart';
import 'package:flutterquiz/ui/widgets/error_container.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

class ContestLeaderBoardScreen extends StatefulWidget {
  const ContestLeaderBoardScreen({super.key, this.contestId});

  final String? contestId;

  @override
  State<ContestLeaderBoardScreen> createState() => _ContestLeaderBoardScreen();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (_) => BlocProvider<GetContestLeaderboardCubit>(
        create: (_) => GetContestLeaderboardCubit(QuizRepository()),
        child: ContestLeaderBoardScreen(
          contestId: arguments!['contestId'] as String?,
        ),
      ),
    );
  }
}

class _ContestLeaderBoardScreen extends State<ContestLeaderBoardScreen> {
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);
    getContestLeaderBoard();
  }

  @override
  void dispose() {
    scrollController
      ..removeListener(scrollListener)
      ..dispose();
    super.dispose();
  }

  void scrollListener() {
    if (scrollController.position.maxScrollExtent == scrollController.offset) {
      if (context.read<GetContestLeaderboardCubit>().hasMoreData) {
        context
            .read<GetContestLeaderboardCubit>()
            .getMoreContestLeaderboardData(widget.contestId!);
      }
    }
  }

  void getContestLeaderBoard() {
    context.read<GetContestLeaderboardCubit>().getContestLeaderboard(
      widget.contestId!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QAppBar(
        elevation: 0,
        title: Text(context.tr('contestLeaderBoardLbl')!),
      ),
      body: BlocBuilder<GetContestLeaderboardCubit, GetContestLeaderboardState>(
        bloc: context.read<GetContestLeaderboardCubit>(),
        builder: (context, state) {
          if (state is GetContestLeaderboardInitial ||
              state is GetContestLeaderboardProgress) {
            return const Center(child: CircularProgressContainer());
          }

          if (state is GetContestLeaderboardFailure) {
            return ErrorContainer(
              errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
              onTapRetry: getContestLeaderBoard,
              showErrorImage: true,
            );
          }

          final successState = state as GetContestLeaderboardSuccess;
          final leaderboardList = successState.getContestLeaderboardList;

          return _buildLeaderboardWithSlivers(
            leaderboardList,
            hasMore: successState.hasMore,
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardWithSlivers(
    List<ContestLeaderboard> list, {
    required bool hasMore,
  }) {
    final height = context.height;
    final showMyRank =
        QuizRemoteDataSource.score != '0' &&
        int.parse(QuizRemoteDataSource.rank) > 3;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Collapsible Top 3 Section
              SliverPersistentHeader(
                pinned: true,
                delegate: _TopThreeHeaderDelegate(
                  expandedHeight: height * 0.29,
                  collapsedHeight: height * 0.12,
                  leaderboardList: list,
                ),
              ),

              // Leaderboard List (items after top 3)
              if (list.length > 3)
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.width * 0.02,
                    vertical: 5,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final actualIndex = index + 3;

                        if (hasMore && actualIndex == list.length) {
                          return const Center(
                            child: CircularProgressContainer(),
                          );
                        }

                        if (actualIndex >= list.length) return null;

                        return Column(
                          children: [
                            _buildLeaderboardItem(list[actualIndex]),
                            if (actualIndex < list.length - 1)
                              Divider(
                                color: Colors.grey,
                                indent: context.width * 0.03,
                                endIndent: context.width * 0.03,
                              ),
                          ],
                        );
                      },
                      childCount: hasMore ? list.length - 2 : list.length - 3,
                    ),
                  ),
                ),

              // Add bottom padding for "My Rank" space
              if (showMyRank)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
            ],
          ),
        ),

        // My Rank Section - Pinned at bottom, always visible
        if (showMyRank)
          myRank(
            QuizRemoteDataSource.rank,
            QuizRemoteDataSource.profile,
            QuizRemoteDataSource.score,
          ),
      ],
    );
  }

  Widget _buildLeaderboardItem(ContestLeaderboard item) {
    final textStyle = TextStyle(
      color: Theme.of(context).colorScheme.onTertiary,
      fontSize: 16,
    );
    final width = context.width;
    final height = context.height;

    return Row(
      children: [
        const SizedBox(width: 10),
        Expanded(
          child: Text(item.userRank!, style: textStyle),
        ),
        Expanded(
          flex: 9,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(right: 20),
            title: Text(
              item.name ?? '...',
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
            leading: Container(
              width: width * 0.12,
              height: height * 0.3,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: QImage.circular(
                imageUrl: item.profile ?? '',
                width: double.maxFinite,
                height: double.maxFinite,
              ),
            ),
            trailing: SizedBox(
              width: width * 0.12,
              child: Center(
                child: Text(
                  UiUtils.formatNumber(int.parse(item.score ?? '0')),
                  maxLines: 1,
                  softWrap: false,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget leaderBoard(List<ContestLeaderboard> list, {required bool hasMore}) {
    if (list.length <= 3) return const SizedBox();

    final textStyle = TextStyle(
      color: Theme.of(context).colorScheme.onTertiary,
      fontSize: 16,
    );
    final width = context.width;
    final height = context.height;

    return Expanded(
      child: Container(
        height: height * .45,
        padding: EdgeInsets.only(top: 5, left: width * .02, right: width * .02),
        child: ListView.separated(
          controller: scrollController,
          shrinkWrap: true,
          itemCount: hasMore ? list.length + 1 : list.length,
          separatorBuilder: (_, i) => i > 2
              ? Divider(
                  color: Colors.grey,
                  indent: width * 0.03,
                  endIndent: width * 0.03,
                )
              : const SizedBox(),
          itemBuilder: (context, index) {
            if (hasMore && index == list.length) {
              return const Center(child: CircularProgressContainer());
            }

            return index > 2
                ? Row(
                    children: [
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(list[index].userRank!, style: textStyle),
                      ),
                      Expanded(
                        flex: 9,
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.only(right: 20),
                          title: Text(
                            list[index].name ?? '...',
                            overflow: TextOverflow.ellipsis,
                            style: textStyle,
                          ),
                          leading: Container(
                            width: width * .12,
                            height: height * .3,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: QImage.circular(
                              imageUrl: list[index].profile ?? '',
                              width: double.maxFinite,
                              height: double.maxFinite,
                            ),
                          ),
                          trailing: SizedBox(
                            width: width * .12,
                            child: Center(
                              child: Text(
                                UiUtils.formatNumber(
                                  int.parse(list[index].score ?? '0'),
                                ),
                                maxLines: 1,
                                softWrap: false,
                                style: textStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget topThreeRanks(List<ContestLeaderboard> list) {
    final width = context.width;
    final height = context.height;

    return Container(
      padding: const EdgeInsets.only(top: 10),
      width: context.width,
      height: height * 0.29,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final onTertiary = Theme.of(context).colorScheme.onTertiary;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              /// Rank Two
              if (list.length > 1)
                Column(
                  children: [
                    SizedBox(height: height * .07),
                    SizedBox(
                      height: width * .224,
                      width: width * .21,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: width * .21,
                              width: width * .21,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: onTertiary.withValues(alpha: .3),
                                ),
                              ),
                              child: QImage.circular(
                                imageUrl: list[1].profile!,
                                width: double.maxFinite,
                                height: double.maxFinite,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: rankCircle('2'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: width * .2,
                      child: Center(
                        child: Text(
                          list[1].name ?? '...',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeights.regular,
                            color: onTertiary.withValues(alpha: .8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width * .15,
                      child: Center(
                        child: Text(
                          list[1].score ?? '...',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeights.bold,
                            color: onTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(height: height * .1, width: width * .2),

              /// Rank One
              if (list.isNotEmpty)
                Column(
                  children: [
                    SizedBox(
                      height: width * .30,
                      width: width * .28,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: width * .28,
                              width: width * .28,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey),
                              ),
                              child: QImage.circular(
                                imageUrl: list[0].profile!,
                                width: double.maxFinite,
                                height: double.maxFinite,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: rankCircle('1', size: 32),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: width * .2,
                      child: Center(
                        child: Text(
                          list[0].name ?? '...',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeights.regular,
                            color: onTertiary.withValues(alpha: .8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width * .15,
                      child: Center(
                        child: Text(
                          list[0].score ?? '...',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeights.bold,
                            color: onTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(height: height * .1, width: width * .2),

              /// Rank Three
              if (list.length > 2)
                Column(
                  children: [
                    SizedBox(height: height * .07),
                    SizedBox(
                      height: width * .224,
                      width: width * .21,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: width * .21,
                              width: width * .21,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: onTertiary.withValues(alpha: .3),
                                ),
                              ),
                              child: QImage.circular(
                                imageUrl: list[2].profile!,
                                width: double.maxFinite,
                                height: double.maxFinite,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: rankCircle('3'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: width * .2,
                      child: Center(
                        child: Text(
                          list[2].name ?? '...',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeights.regular,
                            color: onTertiary.withValues(alpha: .8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width * .15,
                      child: Center(
                        child: Text(
                          list[2].score ?? '...',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeights.bold,
                            color: onTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(height: height * .1, width: width * .2),
            ],
          );
        },
      ),
    );
  }

  Widget rankCircle(String text, {double size = 25}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      padding: const EdgeInsets.all(2),
      child: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: colorScheme.surface,
        child: Text(text),
      ),
    );
  }

  Widget myRank(String rank, String profile, String score) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(color: colorScheme.onTertiary, fontSize: 16);
    final size = context;

    return Container(
      decoration: BoxDecoration(color: colorScheme.surface),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
        title: Row(
          children: [
            Center(child: Text(rank, style: textStyle)),
            Container(
              margin: const EdgeInsets.only(left: 10),
              height: size.height * .06,
              width: size.width * .13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface),
              ),
              child: QImage.circular(
                imageUrl: profile,
                width: double.maxFinite,
                height: double.maxFinite,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              context.tr(myRankKey)!,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ],
        ),
        trailing: Text(
          score,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: textStyle,
        ),
      ),
    );
  }
}

/// Custom SliverPersistentHeaderDelegate for collapsible top 3 section
class _TopThreeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TopThreeHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.leaderboardList,
  });

  final double expandedHeight;
  final double collapsedHeight;
  final List<ContestLeaderboard> leaderboardList;

  @override
  double get minExtent => collapsedHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  bool shouldRebuild(covariant _TopThreeHeaderDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight ||
        leaderboardList != oldDelegate.leaderboardList;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = shrinkOffset / (maxExtent - minExtent);
    final isCollapsed = progress > 0.5;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: _buildTopThreeContent(context, progress, isCollapsed),
    );
  }

  Widget _buildTopThreeContent(
    BuildContext context,
    double progress,
    bool isCollapsed,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final onTertiary = Theme.of(context).colorScheme.onTertiary;

    // Calculate scaling based on scroll progress
    final scale = 1.0 - (progress * 0.4); // Shrink to 60% when collapsed
    final opacity = 1.0 - (progress * 0.3); // Fade slightly

    if (isCollapsed) {
      // Collapsed state: Show top 3 in a compact horizontal row
      return _buildCollapsedView(context, width, onTertiary);
    }

    // Expanded state: Original layout with scaling
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: _buildExpandedView(context, width, onTertiary),
      ),
    );
  }

  Widget _buildCollapsedView(
    BuildContext context,
    double width,
    Color onTertiary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (leaderboardList.isNotEmpty)
            _buildCompactRankItem(
              context,
              leaderboardList[0],
              '1',
              width * 0.28,
              onTertiary,
            ),
          if (leaderboardList.length > 1)
            _buildCompactRankItem(
              context,
              leaderboardList[1],
              '2',
              width * 0.28,
              onTertiary,
            ),
          if (leaderboardList.length > 2)
            _buildCompactRankItem(
              context,
              leaderboardList[2],
              '3',
              width * 0.28,
              onTertiary,
            ),
        ],
      ),
    );
  }

  Widget _buildCompactRankItem(
    BuildContext context,
    ContestLeaderboard item,
    String rank,
    double width,
    Color onTertiary,
  ) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: onTertiary.withValues(alpha: 0.3)),
                ),
                child: QImage.circular(
                  imageUrl: item.profile!,
                  width: double.maxFinite,
                  height: double.maxFinite,
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      rank,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? '...',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeights.semiBold,
                    color: onTertiary,
                  ),
                ),
                Text(
                  item.score ?? '...',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeights.regular,
                    color: onTertiary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView(
    BuildContext context,
    double width,
    Color onTertiary,
  ) {
    final height = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          /// Rank Two
          if (leaderboardList.length > 1)
            _buildExpandedRankItem(
              context,
              leaderboardList[1],
              '2',
              width,
              height,
              onTertiary,
              topPadding: height * 0.07,
            )
          else
            SizedBox(height: height * 0.1, width: width * 0.2),

          /// Rank One
          if (leaderboardList.isNotEmpty)
            _buildExpandedRankItem(
              context,
              leaderboardList[0],
              '1',
              width,
              height,
              onTertiary,
              isFirst: true,
            )
          else
            SizedBox(height: height * 0.1, width: width * 0.2),

          /// Rank Three
          if (leaderboardList.length > 2)
            _buildExpandedRankItem(
              context,
              leaderboardList[2],
              '3',
              width,
              height,
              onTertiary,
              topPadding: height * 0.07,
            )
          else
            SizedBox(height: height * 0.1, width: width * 0.2),
        ],
      ),
    );
  }

  Widget _buildExpandedRankItem(
    BuildContext context,
    ContestLeaderboard item,
    String rank,
    double width,
    double height,
    Color onTertiary, {
    double topPadding = 0,
    bool isFirst = false,
  }) {
    final avatarSize = isFirst ? width * 0.28 : width * 0.21;
    final badgeSize = isFirst ? 32.0 : 25.0;
    final nameFontSize = isFirst ? 14.0 : 12.0;
    final scoreFontSize = isFirst ? 16.0 : 14.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (topPadding > 0) SizedBox(height: topPadding),
                SizedBox(
                  height: isFirst ? width * 0.30 : width * 0.224,
                  width: avatarSize,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: avatarSize,
                          width: avatarSize,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isFirst
                                  ? Colors.grey
                                  : onTertiary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: QImage.circular(
                            imageUrl: item.profile!,
                            width: double.maxFinite,
                            height: double.maxFinite,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _rankCircle(context, rank, size: badgeSize),
                      ),
                    ],
                  ),
                ),
                if (!isFirst) const SizedBox(height: 9),
                SizedBox(
                  width: width * 0.2,
                  child: Center(
                    child: Text(
                      item.name ?? '...',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: nameFontSize,
                        fontWeight: FontWeights.regular,
                        color: onTertiary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: width * 0.15,
                  child: Center(
                    child: Text(
                      item.score ?? '...',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: scoreFontSize,
                        fontWeight: FontWeights.bold,
                        color: onTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rankCircle(BuildContext context, String text, {double size = 25}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      padding: const EdgeInsets.all(2),
      child: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: colorScheme.surface,
        child: Text(text, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}
