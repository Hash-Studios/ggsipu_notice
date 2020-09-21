import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class NoticeTile extends StatelessWidget {
  const NoticeTile({
    Key key,
    @required this.lists,
    @required this.index,
    @required this.func,
  }) : super(key: key);

  final List lists;
  final int index;
  final Function func;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: NeumorphicTheme.accentColor(context),
      elevation: 0,
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Neumorphic(
        style: NeumorphicStyle(shape: NeumorphicShape.flat, depth: 4),
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
        child: ListTile(
            onTap: () {
              func();
            },
            contentPadding: EdgeInsets.fromLTRB(20, 10, 5, 10),
            leading: Container(
              padding: EdgeInsets.only(right: 12.0),
              decoration: new BoxDecoration(
                  border: new Border(
                      right: new BorderSide(
                          width: 1.0,
                          color: NeumorphicTheme.accentColor(context)))),
              child: Icon(Icons.picture_as_pdf,
                  color: Colors.red[400], size: 30.0),
            ),
            title: Text(
              lists[index]["title"],
              style: TextStyle(
                  color: NeumorphicTheme.defaultTextColor(context),
                  fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: <Widget>[
                Icon(
                  Icons.calendar_today,
                  color: Colors.yellow[400],
                  size: 12,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(" ${lists[index]["date"]}",
                      style: TextStyle(
                          color: NeumorphicTheme.defaultTextColor(context))),
                )
              ],
            ),
            trailing: NeumorphicButton(
              style: NeumorphicStyle(shape: NeumorphicShape.flat, depth: 2),
              boxShape: NeumorphicBoxShape.circle(),
              child: Icon(Icons.keyboard_arrow_right,
                  color: NeumorphicTheme.defaultTextColor(context), size: 30.0),
              onClick: () {
                func();
              },
            )),
      ),
    );
  }
}
