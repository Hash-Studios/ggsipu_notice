import 'package:flutter/cupertino.dart';
import 'package:web_scraper/web_scraper.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'App',
      theme: CupertinoThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: CupertinoColors.systemIndigo,
          barBackgroundColor: CupertinoColors.systemIndigo),
      home: MyHomePage(title: 'App'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String elements = "";
  bool isData = false;
  final webScraper = WebScraper('http://www.ipu.ac.in');

  void getNotices() async {
    if (await webScraper.loadWebPage('/notices.php')) {
      List<Map<String, dynamic>> data =
          webScraper.getElement('td > a', ['href']);
      for (int i = 0; i < data.length; i++) {
        elements = data[i]['title'];
      }
      setState(() {
        isData = true;
      });
      print(elements);
    }
  }

  @override
  void initState() {
    super.initState();
    getNotices();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      child: Center(
        child: Container(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverFillRemaining(
                child: Container(
                  child: Text(elements),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
