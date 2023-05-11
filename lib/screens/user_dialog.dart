import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:klient/config_provider.dart';
import 'package:klient/screens/about.dart';
import 'package:klient/screens/debug.dart';
import 'package:klient/screens/settings.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/default_transition.dart';
import 'package:klient/widgets/user_avatar.dart';
import 'package:scolengo_api/scolengo_api.dart';

class UserDialog extends StatefulWidget {
  final void Function()? onUpdate;
  const UserDialog({this.onUpdate, Key? key}) : super(key: key);

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FutureBuilder<SkolengoResponse<User>>(
                    future: ConfigProvider.client!
                        .getUserInfo(ConfigProvider.client!.credentials!.idToken.claims.subject),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return DefaultTransition(
                          child: Text(
                            '${snapshot.data!.data.firstName} ${snapshot.data!.data.lastName}',
                            style: TextStyle(fontSize: MediaQuery.of(context).textScaleFactor * 30),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return const DefaultTransition(child: Text('Erreur'));
                      } else {
                        return const LinearProgressIndicator();
                      }
                    }),
              ),
              /* TODO rewrite this 
              if (Client.students.length > 1)
                DefaultCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...Client.students
                          .map((student) => UserWidget(student, () {
                                Client.currentlySelected = student;
                                setState(() {});
                                Navigator.of(context).pop();
                                if (widget.onUpdate != null) {
                                  widget.onUpdate!();
                                }
                              }))
                          .toList(),
                    ],
                  ),
                ), */
              DefaultCard(
                child: Column(
                  children: [
                    Option(
                      icon: Icons.settings_outlined,
                      text: 'Paramètres',
                      onTap: () {
                        Navigator.of(context)
                          ..pop()
                          ..push(MaterialPageRoute(builder: (_) => const SettingsPage()))
                              .then((value) {
                            if (widget.onUpdate != null) widget.onUpdate!();
                          });
                      },
                    ),
                    Divider(height: 1, color: Theme.of(context).colorScheme.primary.withAlpha(80)),
                    Option(
                      icon: Icons.info_outlined,
                      text: 'À propos',
                      onTap: () {
                        Navigator.of(context)
                          ..pop()
                          ..push(MaterialPageRoute(builder: (_) => const AboutPage()));
                      },
                    ),
                    Divider(height: 1, color: Theme.of(context).colorScheme.primary.withAlpha(80)),
                    const Option(
                      icon: Icons.logout_outlined,
                      text: 'Se déconnecter',
                      // onTap: () => Client.disconnect(context),
                    ),
                    if (kDebugMode)
                      Divider(
                          height: 1, color: Theme.of(context).colorScheme.primary.withAlpha(80)),
                    if (kDebugMode)
                      Option(
                        text: 'Debug',
                        icon: Icons.bug_report_outlined,
                        onTap: () {
                          Navigator.of(context)
                            ..pop()
                            ..push(MaterialPageRoute(builder: (_) => const DebugScreen()));
                        },
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class UserWidget extends StatelessWidget {
  final User user;
  final void Function() onTap;

  const UserWidget(
    this.user,
    this.onTap, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Row(children: [
              SizedBox(
                  height: MediaQuery.of(context).textScaleFactor * 55,
                  child: UserAvatar(user.firstName[0] + user.lastName[0])),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${user.firstName} ${user.lastName}'),
              ),
            ]),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: /*user.id == Client.currentlySelected!.uid ? 1 : 0*/ 1,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: Theme.of(context).highlightColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Option extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function()? onTap;

  const Option({
    required this.icon,
    required this.text,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(icon),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(text),
            )
          ],
        ),
      ),
    );
  }
}
