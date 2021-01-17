import 'package:flutter/material.dart';
import 'package:jigowatt/accountScaffold.dart';
import 'package:jigowatt/main.dart';
import 'package:rapido/rapido.dart';

class AccountListScaffold extends StatefulWidget {
  final DocumentList accountDocs;
  final Function onActiveAccountChanged;

  const AccountListScaffold(
      {Key key,
      @required this.accountDocs,
      @required this.onActiveAccountChanged})
      : super(key: key);

  @override
  _AccountListScaffoldState createState() => _AccountListScaffoldState();
}

class _AccountListScaffoldState extends State<AccountListScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Accounts"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
            return AccountScaffold(
              onOK: (Document newDoc) {
                widget.accountDocs.forEach((Document doc){
                  doc["active?"] = false;
                });

                widget.accountDocs.add(newDoc);
                
                setState(() {});
              },
            );
          }));
        },
        child: Icon(Icons.add),
      ),
      body: ListView(
        children: widget.accountDocs.map((Document doc) {
          return Dismissible(
            key: ObjectKey(doc.id),
            background: ListTile(
              tileColor: Colors.red,
              leading: Icon(Icons.delete_forever),
            ),
            onDismissed: ((DismissDirection direction) {
              widget.accountDocs.remove(doc);
            }),
            child: SwitchListTile(
                title: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (BuildContext context) {
                          return AccountScaffold(
                            accountDocument: doc,
                            onOK: (Document editedDoc) {
                              editedDoc.save();
                              setState(() {});
                            },
                          );
                        }),
                      );
                    },
                    child: Text(doc["name"])),
                value: doc["active?"],
                onChanged: (bool value) {
                  if (doc["active?"] && value) return;
                  if (value) {
                    widget.accountDocs.forEach((Document d) {
                      d["active?"] = false;
                    });
                    doc["active?"] = true;
                    widget.onActiveAccountChanged(doc);
                    if (this.mounted) {
                      setState(() {});
                    }
                  }
                }),
          );
        }).toList(),
      ),
    );
  }
}
