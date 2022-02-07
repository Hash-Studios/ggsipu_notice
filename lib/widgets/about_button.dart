import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ip_notices/services/locator.dart';
import 'package:ip_notices/services/theme_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutButton extends StatelessWidget {
  const AboutButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _themeService = locator<ThemeService>();
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
          // NeumorphicTheme.isUsingDark(context)
          // ? CupertinoIcons.info
          // :
          CupertinoIcons.info,
        ),
        color: _themeService.onBackground(context),
        iconSize: 20,
      ),
    );
  }
}

class AboutDialog extends StatelessWidget {
  const AboutDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _themeService = locator<ThemeService>();
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
              color: _themeService.onBackground(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              child: ListTile(
                leading: Container(
                    padding: const EdgeInsets.only(right: 12.0),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          width: 1.0,
                          color: _themeService
                              .onBackground(context)
                              .withOpacity(0.24),
                        ),
                      ),
                    ),
                    child: const CircleAvatar(
                      backgroundImage: AssetImage("assets/images/dev.png"),
                    )),
                title: Text(
                  "Abhay Maurya",
                  style: TextStyle(
                      color:
                          _themeService.onBackground(context).withOpacity(0.9),
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "ECE, USICT",
                  style: TextStyle(
                      color:
                          _themeService.onBackground(context).withOpacity(0.9)),
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
            String link = "https://www.github.com/LiquidatorCoder";
            _launchURL(link);
          },
        ),
        CupertinoDialogAction(
          child: const Text("LinkedIn"),
          onPressed: () {
            Navigator.of(context).pop();
            String link = "https://www.linkedin.com/in/liquidatorcoder/";
            _launchURL(link);
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

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
