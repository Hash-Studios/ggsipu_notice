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
      title: const Text("GGSIPU Notices v1.3.1-beta+17"),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text("Developed and Maintained by"),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
            child: Material(
              elevation: 0,
              color: themeService.onBackground(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              child: ListTile(
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
                  "ECE, USICT",
                  style: TextStyle(
                      color: themeService
                          .onBackground(context)
                          .withValues(alpha: 0.9)),
                ),
              ),
            ),
          ),
          const Text(
            "This is an unofficial app.\nPlease give the repository a star if you like this app. 👍",
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
          isDestructiveAction: true,
          child: const Text("Back"),
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
