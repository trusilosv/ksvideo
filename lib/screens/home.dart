import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ksvideo/screens/Chat.dart';
import 'package:ksvideo/screens/user_info_screen.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as chat;

class Home extends StatefulWidget {
  final User user;
  const Home({super.key, required this.user});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin<Home> {
  late User _user;
  static const List<Destination> allDestinations = <Destination>[
    Destination(0, 'Teal', Icons.home, Colors.teal),
    Destination(1, 'Call', Icons.call, Colors.cyan),
    Destination(2, 'Chat', Icons.message, Colors.orange),
    Destination(3, 'User', Icons.person, Colors.blue, false),
  ];

  late final List<GlobalKey<NavigatorState>> navigatorKeys;
  late final List<GlobalKey> destinationKeys;
  late final List<AnimationController> destinationFaders;
  late final List<Widget> destinationViews;
  int selectedIndex = 0;
    final client = chat.StreamChatClient(
    "1337775",
    logLevel: chat.Level.INFO,
  );


  AnimationController buildFaderController() {
    return AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addStatusListener((AnimationStatus status) {
        if (status.isDismissed) {
          setState(() {}); // Rebuild unselected destinations offstage.
        }
      });
  }

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    navigatorKeys = List<GlobalKey<NavigatorState>>.generate(
      allDestinations.length,
      (int index) => GlobalKey(),
    ).toList();

    destinationFaders = List<AnimationController>.generate(
      allDestinations.length,
      (int index) => buildFaderController(),
    ).toList();
    destinationFaders[selectedIndex].value = 1.0;

    final CurveTween tween = CurveTween(curve: Curves.fastOutSlowIn);
    destinationViews = allDestinations.map<Widget>(
      (Destination destination) {
        return FadeTransition(
          opacity: destinationFaders[destination.index].drive(tween),
          child: DestinationView(
            user: _user,
            destination: destination,
            navigatorKey: navigatorKeys[destination.index],
            client: client,
          ),
        );
      },
    ).toList();
  }

  @override
  void dispose() {
    for (final AnimationController controller in destinationFaders) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler(
      onPop: () {
        final NavigatorState navigator =
            navigatorKeys[selectedIndex].currentState!;
        navigator.pop();
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Stack(
            fit: StackFit.expand,
            children: allDestinations.map(
              (Destination destination) {
                final int index = destination.index;
                final Widget view = destinationViews[index];
                if (index == selectedIndex) {
                  destinationFaders[index].forward();
                  return Offstage(offstage: false, child: view);
                } else {
                  destinationFaders[index].reverse();
                  if (destinationFaders[index].isAnimating) {
                    return IgnorePointer(child: view);
                  }
                  return Offstage(child: view);
                }
              },
            ).toList(),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              selectedIndex = index;
            });
          },
          destinations: allDestinations.map<NavigationDestination>(
            (Destination destination) {
              return NavigationDestination(
                icon: Icon(destination.icon, color: destination.color),
                label: destination.title,
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

class Destination {
  const Destination(this.index, this.title, this.icon, this.color,
      [this.hasInternalNavigation = false, this.body]);
  final int index;
  final String title;
  final IconData icon;
  final MaterialColor color;
  final bool hasInternalNavigation;
  final Widget? body;
}

class RootPage extends StatelessWidget {
  const RootPage({super.key, required this.user, required this.destination, required this.client});

  final Destination destination;
  final User user;
  final chat.StreamChatClient client;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(destination.title),
          backgroundColor: destination.color,
          foregroundColor: Colors.white,
        ),
        backgroundColor: destination.color[50],
        body: destination.title == "User"
            ? UserInfoScreen(user: user)
            : destination.title == "Chat"
                ? Chat(client: client)
                : null);
  }
}

class DestinationView extends StatefulWidget {
  const DestinationView(
      {super.key,
      required this.destination,
      required this.navigatorKey,
      required this.user,
      required this.client
      });
    final chat.StreamChatClient client;
  final Destination destination;
  final Key navigatorKey;
  final User user;
  @override
  State<DestinationView> createState() => _DestinationViewState();
}

class _DestinationViewState extends State<DestinationView> {
  @override
  Widget build(BuildContext context) {
    return widget.destination.hasInternalNavigation
        ? Navigator(
            key: widget.navigatorKey,
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (BuildContext context) {
                  return RootPage(
                      destination: widget.destination, user: widget.user, client: widget.client,);
                },
              );
            },
          )
        : RootPage(destination: widget.destination, user: widget.user,client: widget.client,);
  }
}
