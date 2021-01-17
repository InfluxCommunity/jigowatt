import 'package:flutter/material.dart';
import 'package:rapido/rapido.dart';

class AccountScaffold extends StatefulWidget {
  final Document accountDocument;
  final Function onOK;

  const AccountScaffold({Key key, this.accountDocument, @required this.onOK})
      : super(key: key);
  @override
  _AccountScaffoldState createState() => _AccountScaffoldState();
}

class _AccountScaffoldState extends State<AccountScaffold> {
  Document _doc;
  TextEditingController nameController;
  TextEditingController orgController;
  TextEditingController urlController;
  TextEditingController tokenController;

  @override
  void initState() {
    if (widget.accountDocument != null) {
      _doc = widget.accountDocument;
    } else {
      _doc = Document(initialValues: {
        "active?": true,
        "name": "",
        "org": "",
        "url": "",
        "token secret": ""
      });
    }
    nameController = TextEditingController(text: _doc["name"]);
    orgController = TextEditingController(text: _doc["org"]);
    urlController = TextEditingController(text: _doc["url"]);
    tokenController = TextEditingController(text: _doc["token secret"]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountDocument == null
            ? "Add New Account"
            : "Edit ${widget.accountDocument["name"]}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Friendly Name"),
            ),
            TextField(
              controller: orgController,
              decoration: InputDecoration(labelText: "Org ID"),
            ),
            TextField(
              controller: urlController,
              decoration: InputDecoration(labelText: "Url"),
            ),
            TextField(
              obscureText: true,
              controller: tokenController,
              decoration: InputDecoration(labelText: "Token"),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: RaisedButton(onPressed: (){
                _doc["name"] = nameController.text;
                _doc["org"] = orgController.text;
                _doc["url"] = urlController.text;
                _doc["token secret"] = tokenController.text;
                widget.onOK(_doc);
                Navigator.pop(context);
              }, child: Text("Accept"),),
            ),
          ],
        ),
      ),
    );
  }
}
