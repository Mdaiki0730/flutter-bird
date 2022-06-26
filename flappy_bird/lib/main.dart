import 'dart:math';

import 'package:flappy_bird/game.dart';
import 'package:flappy_bird/services/persistence/persistence_service.dart';
import 'package:flappy_bird/services/web3_provider.dart';
import 'package:flappy_bird/views/bird.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixel_border/pixel_border.dart';
import 'package:provider/provider.dart';

import 'views/background.dart';
import 'views/flappy_text.dart';
import 'views/web3_popup.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Web3Provider>(
      create: (BuildContext context) {
        return Web3Provider()..init();
      },
      child: MaterialApp(
        title: 'Flappy Bird',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const FlutterBird(title: 'Flappy Bird'),
      ),
    );
  }
}

class FlutterBird extends StatefulWidget {
  const FlutterBird({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<FlutterBird> createState() => _FlutterBirdState();
}

class _FlutterBirdState extends State<FlutterBird> with AutomaticKeepAliveClientMixin {

  bool playing = false;

  int? lastScore;
  int? highScore;

  late Size worldDimensions;
  late double birdSize;

  late final PageController birdSelectorController = PageController(viewportFraction: 0.25);
  late final GlobalKey birdSelectorKey = GlobalKey();
  List<Bird> birds = [
    const Bird(),
    const Bird(imagePath: "images/hipster_bird.png", name: "Bird #34",),
    const Bird(imagePath: "images/img.png", name: "Bird #867",),
    const Bird(imagePath: "images/img_1.png", name: "Bird #4598",),
    const Bird(imagePath: "images/img_2.png", name: "Bird #1245",),
  ];
  late int selectedBird = 0;

  @override
  void initState() {
    super.initState();
    // birdSelectorController = PageController(viewportFraction: 0.25, keepPage: true, initialPage: 0);
    PersistenceService.instance.getHighScore().then((value) => setState(() {
      if (value != null) highScore = value;
    }));
  }

  _startGame() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => FlutterBirdGame(
          bird: birds[selectedBird],
          birdSize: birdSize,
          worldDimensions: worldDimensions,
          onGameOver: (score) {
            lastScore = score;
            if (score > (highScore ?? 0)) {
              PersistenceService.instance.saveHighScore(score);
              highScore = score;
            }
            setState(() {

            });
          }),
    ));
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);

    Size screenDimensions = MediaQuery.of(context).size;
    double maxWidth = screenDimensions.height * 3 / 4 / 1.3;
    worldDimensions = Size(min(maxWidth, screenDimensions.width), screenDimensions.height * 3 / 4);
    birdSize = worldDimensions.height / 8;

    return Scaffold(
      body: Consumer<Web3Provider>(
        builder: (context, web3Provider, child) {


          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: maxWidth
              ),
              child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Background(),
                    _buildBirdSelector(),
                    _buildMenu(web3Provider),
                  ]
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildMenu(Web3Provider web3Provider) => Column(
    children: [
      Expanded(flex: 3,
        child: Column(
        children: [
          const Spacer(flex: 1,),
          _buildTitle(),
          if (lastScore != 0)
            const SizedBox(height: 24,),
          if (lastScore != 0)
            FlappyText(
              text: "$lastScore",
            ),
          const Spacer(flex: 4,),
          _buildPlayButton(),
          const SizedBox(height: 24,),
          if (highScore != null)
            FlappyText(
              fontSize: 32,
              strokeWidth: 2.8,
              text: "High Score $highScore",
            ),
          const Spacer(flex: 1,),
        ],
      )),
      Expanded(flex: 1,
        child: _buildWeb3View(web3Provider),
      )
    ],
  );

  Widget _buildTitle() => const FlappyText(
    fontSize: 72,
    text: "FlutterBird",
  );

  Widget _buildPlayButton() => GestureDetector(
    onTap: _startGame,
    child: Container(
      decoration: ShapeDecoration(
        shape: PixelBorder.solid(
          borderRadius: BorderRadius.circular(9.0),
          color: Colors.white,
          pixelSize: 3,
        ),
        color: Colors.white,
          shadows: const [
            BoxShadow(
                offset: Offset(3, 3)
            )
          ]
      ),
      height: 60.0,
      width: 100.0,
      child: const Center(
        child: Icon(
          Icons.play_arrow_rounded,
          size: 50,
          color: Colors.green,
        ),
      ),
    ),
  );

  Widget _buildBirdSelector() => Column(
    children: [
      Expanded(
        flex: 3,
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              height: birdSize,
              child: PageView(
                controller: birdSelectorController,
                onPageChanged: (page) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    selectedBird = page;
                  });
                },
                children: birds.map((bird) => Center(child: Container(color: Colors.white, height: birdSize, width: birdSize, child: bird,))).toList(),
              ),
            ),
            const SizedBox(height: 16,),
            Text(
              birds[selectedBird].name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
          ],
        ),
      ),
      const Spacer()
    ],
  );



  _buildWeb3View(Web3Provider web3Provider) {

    return SafeArea(
      child: GestureDetector(
        onTap: _showWeb3PopUp,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 20,
              left: 32,
              child: Row(
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        )
                      ]
                    ),
                    child: Center(
                      child: kIsWeb ? Image.network("images/walletconnect.png") : Image.asset("images/walletconnect.png"),
                    ),
                  ),
                  const SizedBox(width: 12,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        web3Provider.isAuthenticated ? "Wallet Connected" : "No Wallet\nConnected",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      if (web3Provider.isAuthenticated)
                        Text(
                          web3Provider.currentAddressShort ?? "",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _showWeb3PopUp() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return const Web3Popup();
      },
      transitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },

    ));
  }

  @override
  bool get wantKeepAlive => true;
}
