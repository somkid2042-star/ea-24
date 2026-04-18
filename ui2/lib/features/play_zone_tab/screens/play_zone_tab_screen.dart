import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/auth/cubits/auth_cubit.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/ui/screens/home/widgets/quiz_grid_card.dart';
import 'package:flutterquiz/ui/screens/quiz/category_screen.dart';
import 'package:flutterquiz/ui/widgets/all.dart';

final class PlayZoneTabScreen extends StatefulWidget {
  const PlayZoneTabScreen({super.key});

  @override
  State<PlayZoneTabScreen> createState() => PlayZoneTabScreenState();
}

final class PlayZoneTabScreenState extends State<PlayZoneTabScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final _scrollController = ScrollController();

  final _playZones = <Zone>[];
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _scaleAnimations = [];
  final List<Animation<double>> _opacityAnimations = [];

  @override
  void initState() {
    super.initState();
    _initializePlayZones();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    const animDuration = Duration(milliseconds: 350);
    const staggerDelay = 60;

    for (var i = 0; i < _playZones.length; i++) {
      final controller = AnimationController(
        duration: animDuration,
        vsync: this,
      );
      final curve = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      );

      _controllers.add(controller);
      _scaleAnimations.add(Tween<double>(begin: .7, end: 1).animate(curve));
      _opacityAnimations.add(Tween<double>(begin: 0, end: 1).animate(curve));

      Future.delayed(
        Duration(milliseconds: staggerDelay * i),
        controller.forward,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void onTapTab() {
    if (_scrollController.hasClients && _scrollController.offset != 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _initializePlayZones() {
    final config = context.read<SystemConfigCubit>();

    _playZones.addAll([
      if (config.isDailyQuizEnabled)
        (
          type: QuizTypes.dailyQuiz,
          title: 'dailyQuiz',
          img: Assets.dailyQuizIcon,
          desc: 'desDailyQuiz',
        ),
      if (config.isFunNLearnEnabled)
        (
          type: QuizTypes.funAndLearn,
          title: 'funAndLearn',
          img: Assets.funNLearnIcon,
          desc: 'desFunAndLearn',
        ),
      if (config.isGuessTheWordEnabled)
        (
          type: QuizTypes.guessTheWord,
          title: 'guessTheWord',
          img: Assets.guessTheWordIcon,
          desc: 'desGuessTheWord',
        ),
      if (config.isAudioQuizEnabled)
        (
          type: QuizTypes.audioQuestions,
          title: 'audioQuestions',
          img: Assets.audioQuizIcon,
          desc: 'desAudioQuestions',
        ),
      if (config.isMathQuizEnabled)
        (
          type: QuizTypes.mathMania,
          title: 'mathMania',
          img: Assets.mathsQuizIcon,
          desc: 'desMathMania',
        ),
      if (config.isTrueFalseQuizEnabled)
        (
          type: QuizTypes.trueAndFalse,
          title: 'truefalse',
          img: Assets.trueFalseQuizIcon,
          desc: 'desTrueFalse',
        ),
      if (config.isMultiMatchQuizEnabled)
        (
          type: QuizTypes.multiMatch,
          title: 'multiMatch',
          img: Assets.multiMatchIcon,
          desc: 'desMultiMatch',
        ),
    ]);
  }

  void _onTapQuiz(QuizTypes type) {
    // Check if the user is a guest, Show login required dialog for guest users
    if (context.read<AuthCubit>().isGuest) {
      showLoginRequiredDialog(context);
      return;
    }

    if (type case QuizTypes.dailyQuiz || QuizTypes.trueAndFalse) {
      // Daily Quiz and True/False Quiz navigate directly to quiz screen
      Navigator.of(
        globalCtx,
      ).pushNamed(Routes.quiz, arguments: {'quizType': type});
    } else {
      /// Other quiz types (FunAndLearn, GuessTheWord, AudioQuestions, etc)
      /// navigate to category selection screen first.
      globalCtx.pushNamed(
        Routes.category,
        arguments: CategoryScreenArgs(quizType: type),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: QAppBar(
        title: Text(context.tr('playZone')!),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            _playZones.length,
            (index) {
              final zone = _playZones[index];
              return FadeTransition(
                opacity: _opacityAnimations[index],
                child: ScaleTransition(
                  scale: _scaleAnimations[index],
                  child: QuizGridCard(
                    onTap: () => _onTapQuiz(zone.type),
                    title: context.tr(zone.title)!,
                    desc: context.tr(zone.desc)!,
                    img: zone.img,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
