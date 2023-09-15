import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

//import 'package:cryptography/cryptography.dart';

generatoken(String siteid, String sitename, String key) {
  //print('generate function call');
  final jwt = JWT(
      // Payload
      {
        "sub": sitename,
        "exp": 1976681470,
        "site_id": siteid,
        "hmac": "fgGRkxcD+3awrsSDCUfJdo5O8hSDirQHW/Z5uIJI6Xs="
      });

  //key = base64Encode(key);
  key = base64Encode(utf8.encode(key));
// Sign it (default with HS256 algorithm)

  final newEntries = <String, String>{'alg': 'HS256', 'typ': 'JWT'};
  jwt.header?.addEntries(newEntries as Iterable<MapEntry<String, dynamic>>);

  final token = jwt.sign(SecretKey(key));
  print(token);

  // final hashkey = <String, String>({ 'alg': 'HS256', 'typ': 'JWT'});
  // JWTAlgorithm.HS256.toString();
}

class CallingApi extends StatefulWidget {
  const CallingApi();
  @override
  State<CallingApi> createState() => _CallingApiState();
}

class _CallingApiState extends State<CallingApi> {
  final url = "https://jsonplaceholder.typicode.com/todos";
  var data;
  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    var uri = await http.get(Uri.http('jsonplaceholder.typicode.com', 'todos'));
    var sitename = "DhirajDev";
    var siteid = "128250540";
    var skey = "AfNZwT4iKUv6AZxly9EGvmk69qmd9C0u";
    generatoken(siteid, sitename, skey);
    if (uri.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      data = jsonDecode(uri.body);
      // print(data);
      setState(() {});
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView.builder(itemBuilder: (BuildContext context, int index) {
      return Card(
        child: ListTile(title: Text(data[index]["title"])),
      );
    }));
  }
}
