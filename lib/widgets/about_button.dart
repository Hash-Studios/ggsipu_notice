import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ip_notices/services/locator.dart';
import 'package:ip_notices/services/theme_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutButton extends StatelessWidget {
  const AboutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = locator<ThemeService>();
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: IconButton(
        padding: const EdgeInsets.only(bottom: 2),
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        onPressed: () {
          showCupertinoDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) => const AboutDialog());
        },
        icon: const Icon(
          CupertinoIcons.info,
        ),
        color: themeService.onBackground(context),
        iconSize: 20,
      ),
    );
  }
}

class AboutDialog extends StatelessWidget {
  const AboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = locator<ThemeService>();
    return CupertinoAlertDialog(
      title: const Text("GGSIPU Notices"),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text("Made by"),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
            child: Material(
              elevation: 0,
              color: themeService.onBackground(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                leading: Container(
                    padding: const EdgeInsets.only(right: 12.0),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          width: 1.0,
                          color: themeService
                              .onBackground(context)
                              .withValues(alpha: 0.24),
                        ),
                      ),
                    ),
                    child: const CircleAvatar(
                      backgroundImage: AssetImage("assets/images/dev.png"),
                    )),
                title: Text(
                  "Abhay Maurya",
                  style: TextStyle(
                      color: themeService
                          .onBackground(context)
                          .withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "ex-USICTian",
                  style: TextStyle(
                      color: themeService
                          .onBackground(context)
                          .withValues(alpha: 0.9)),
                ),
              ),
            ),
          ),
          const Text(
            "Unofficial app. Not affiliated with GGSIPU.",
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            "If you find it useful, star the repo on GitHub.",
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          child: const Text("Github"),
          onPressed: () {
            Navigator.of(context).pop();
            _launchURL("https://www.github.com/LiquidatorCoder");
          },
        ),
        CupertinoDialogAction(
          child: const Text("LinkedIn"),
          onPressed: () {
            Navigator.of(context).pop();
            _launchURL("https://www.linkedin.com/in/liquidatorcoder/");
          },
        ),
        CupertinoDialogAction(
          child: const Text("X (Twitter)"),
          onPressed: () {
            Navigator.of(context).pop();
            _launchURL("https://www.twitter.com/liquidatorAB_/");
          },
        ),
        CupertinoDialogAction(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}
