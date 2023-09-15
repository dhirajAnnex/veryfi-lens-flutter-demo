import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
//import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

createHmac(String secreteKey, String jsonPayloadObj) {
  List<int> key = utf8.encode(secreteKey);
  List<int> jsonPayload = utf8.encode(jsonPayloadObj);
  var enjsonPayload = utf8.encode(base64Encode(jsonPayload));
  var hmacSha256 = new Hmac(sha256, key);
  var digest = hmacSha256.convert(enjsonPayload);
  var enhmc = base64.encode(digest.bytes);
  return enhmc;
}

postRequestAPI() async {
  print('POST request call');
  final base_url = dotenv.env['BASE_URL'];
  final key = dotenv.env['SECRECT'];
  final sitename = dotenv.env['SITE_NAME'];
  final siteid = dotenv.env['SITE_ID'];
  var url =
      'https://socialannexuat.blob.core.windows.net/ocr/128250540_2023-09-13_1694600478_Product_not_found.jpeg';

  final Map<String, dynamic> data = {
    'email': 'test.uat.10001062@gmail.com',
    'url': base64.encode(utf8.encode(url)),
  };
  final String jsonpayload3 = jsonEncode(data);
  //print(jsonpayload3);
  var thmac2 = createHmac(key!, jsonpayload3);
  final expiration = (DateTime.now().microsecondsSinceEpoch) + 3600000;
  final jwt = JWT(
      {"sub": sitename, "exp": expiration, "site_id": siteid, "hmac": thmac2});
  final jwtheader = <String, String>{'alg': 'HS256', 'typ': 'JWT'};
  JWT(jwtheader);
  final token = jwt.sign(SecretKey(key));
  var url1 = '$base_url/receiptuploadtest';
  print(" token " + token);
  // var  payload4 = base64.encode(utf8.encode(jsonEncode(payload3)));
  // print("encoded payload " + payload4);
  final response1 = await http.post(
    Uri.parse(url1),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-AnnexCloud-Site': '$siteid',
    },
    body: jsonpayload3, // Encode the payload as JSON
  );
  print(response1.body.toString());
}

getRequestAPI() async {
  print('GET request call');
  final base_url = dotenv.env['BASE_URL'];
  final key = dotenv.env['SECRECT'];
  final sitename = dotenv.env['SITE_NAME'];
  final siteid = dotenv.env['SITE_ID'];

  var payload1 = '"test.uat.10001062@gmail.com"';
  var thmac = createHmac(key!, payload1);

  final expiration = (DateTime.now().microsecondsSinceEpoch) + 3600000;
  // print("expiration time => $expiration");

  final jwt = JWT(
      {"sub": sitename, "exp": expiration, "site_id": siteid, "hmac": thmac});

  final jwtheader = <String, String>{'alg': 'HS256', 'typ': 'JWT'};
  JWT(jwtheader);
  final token = jwt.sign(SecretKey(key!));

  var url = '$base_url/points/test.uat.10001062@gmail.com';

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-AnnexCloud-Site': '$siteid'
    },
    //body: jsonEncode(payload2.toString()), // Encode the payload as JSON
  );
  if (response.statusCode == 200) {
    print(response.body.toString());
  } else {
    print('Login Failed !');
  }
}

putRequestAPI() async {
  final key = dotenv.env['SECRECT'];
  final sitename = dotenv.env['SITE_NAME'];
  final siteid = dotenv.env['SITE_ID'];
  final base_url1 = dotenv.env['BASE_URL'];

  final expiration1 = (DateTime.now().microsecondsSinceEpoch) + 3600000;
  final Map<String, dynamic> payload2 = {
    'id': 'test.uat.10001062@gmail.com',
    'email': 'test.uat.10001062@gmail.com',
    'firstName': 'Jubaed',
    'lastName': 'Prince',
    'optInStatus': 'YES',
    'phone': '111111111'
  };

  var thmac1 = createHmac(key!, jsonEncode(payload2));

  final jwt1 = JWT(
      {"sub": sitename, "exp": expiration1, "site_id": siteid, "hmac": thmac1});

  final jwtheader1 = <String, String>{'alg': 'HS256', 'typ': 'JWT'};
  JWT(jwtheader1);
  final token1 = jwt1.sign(SecretKey(key));

  var url1 = '$base_url1/users/test.uat.10001062@gmail.com';

  final response1 = await http.put(
    Uri.parse(url1),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token1',
      'X-AnnexCloud-Site': '$siteid',
    },
    body: jsonEncode(payload2), // Encode the payload as JSON
  );
  print(response1.body.toString());
}

generatoken(String siteid, String sitename, String key) async {
  postRequestAPI();
  //getRequestAPI();
  //putRequestAPI();
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

    final sname = dotenv.env['SITE_NAME'];
    final sid = dotenv.env['SITE_ID'];
    final secret = dotenv.env['SECRECT'];

    //generatoken(siteid, sitename, skey);
    generatoken(sid!, sname!, secret!);

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
