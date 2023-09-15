/// [dart-packages]
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Store image to AWS bucket

//import 'package:amplify_flutter/amplify.dart';
//import 'package:amplify_storage_s3/amplify_storage_s3.dart';
//import 'package:azblob/azblob.dart';
import 'package:aws_common/vm.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3_dart/amplify_storage_s3_dart.dart';
import 'package:aws_common/aws_common.dart';

/// [flutter-packages]
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [third-party-packages]
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// [veryfi-packages]
import 'package:veryfi/lens.dart';

import 'amplifyconfiguration.dart';
import 'callingapi.dart';
//import 'test.dart';

void main() async {
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var widgetsList = <Widget>[];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    Map<String, dynamic> credentials = {
      'clientId':
          dotenv.env['VERYFI_CLIENT_ID'] ?? 'XXXX', //Replace with your clientId
      'userName':
          dotenv.env['VERYFI_USERNAME'] ?? 'XXXX', //Replace with your username
      'apiKey':
          dotenv.env['VERYFI_API_KEY'] ?? 'XXXX', //Replace with your apiKey
      'url': dotenv.env['VERYFI_URL'] ?? 'XXXX' //Replace with your url
    };

    Map<String, dynamic> settings = {
      'blurDetectionIsOn': true,
      'showDocumentTypes': true
    };

    try {
      Veryfi.initLens(credentials, settings);
    } on PlatformException catch (e) {
      setState(() {
        var errorText = 'There was an error trying to initialize Lens:\n\n';
        errorText += '${e.code}\n\n';
        widgetsList.add(Text(errorText));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true),
      //home: CallingApi(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Veryfi Lens Wrapper'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: ElevatedButton(
                      onPressed: startListeningEvents,
                      child: Text("Start Listening Events"),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Column(
                    children: widgetsList,
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: onShowCameraPressed,
          child: Icon(Icons.camera_alt),
        ),
      ),
    );
  }

  void startListeningEvents() {
    Veryfi.setDelegate(handleVeryfiEvent);
  }

  void onShowCameraPressed() async {
    await Veryfi.showCamera();
  }

  void handleVeryfiEvent(LensEvent eventType, Map<String, dynamic> response) {
    setState(() {
      var veryfiResult = '${eventType.toString()}\n\n';

      widgetsList.add(Text(
        veryfiResult,
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      veryfiResult = '${response.toString()}\n\n';
      widgetsList.add(Text(veryfiResult));
    });

    if (eventType.index == 3) {
      if (response["data"] != null &&
          response["data"].toString().contains(".jpg")) {
        var imagePath = response["data"].toString();
        // send image to AWS
        uploadImage(imagePath);
        if (imagePath.contains("thumbnail")) {
          widgetsList.add(Text(
            "Thumbnail",
            style: TextStyle(fontWeight: FontWeight.normal),
          ));
          widgetsList.add(
            Center(
              child: SizedBox(
                height: 100,
                width: 100,
                child: Image.file(
                  File(imagePath),
                ),
              ),
            ),
          );
        } else {
          widgetsList.add(Text(
            "Original",
            style: TextStyle(fontWeight: FontWeight.normal),
          ));
          widgetsList.add(
            Image.file(
              File(imagePath),
            ),
          );
        }
      }
    }

    widgetsList.add(SizedBox(
      height: 30,
    ));

    widgetsList.add(Divider(
      thickness: 1,
    ));
  }


  Future<void> configureAmplify() async {
    try {
      await Amplify.configure(amplifyconfig);
      print('Amplify successfully configured');
    } catch (e) {
      print('Error configuring Amplify: $e');
    }
  }

  Future<void> uploadImage(path) async {
    print('upload image to AWS ----------');
    File file = File(path);
    print("upload image to AWS -> " + file.path);
    final awsFile = AWSFilePlatform.fromFile(file);

    final result = await Amplify.Storage.uploadFile(
      localFile: awsFile,
      key: 'images/${DateTime.now()}.jpg', // Set a unique key for the image
    ).result;

    if (result == true) {
      print('Image uploaded successfully');
      // You can get the public URL of the uploaded image from result.url
      Set<String> imageUrl = {result.uploadedItem.key};
      // Do something with the imageUrl, like saving it in a database.
    } else {
      print('Image upload failed');
    }
  }

  Future<void> sendImageToApi(String imagePath) async {
    // Define the API endpoint URL
    print('sendImageToApi called ' + imagePath);
    final base_url = dotenv.env['BASE_URL'];
    final key = dotenv.env['SECRECT'];
    final sitename = dotenv.env['SITE_NAME'];
    final siteid = dotenv.env['SITE_ID'];

    final String data = jsonEncode(imagePath);

    var thmac = createHmac(key!, data);
    final expiration = (DateTime.now().microsecondsSinceEpoch) + 3600000;
    final jwt = JWT(
        {"sub": sitename, "exp": expiration, "site_id": siteid, "hmac": thmac});
    final jwtheader = <String, String>{'alg': 'HS256', 'typ': 'JWT'};
    JWT(jwtheader);
    final token = jwt.sign(SecretKey(key));
    var apiUrl = '$base_url/receiptuploadtest';
    print('sendImageToApi ' + apiUrl);

    /*var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(http.MultipartFile.fromBytes('picture', File(imagePath!).readAsBytesSync(),filename: imagePath!));
    var res = await request.send();
    if(res.statusCode == 200){
        print('api called successfully');
    }
    else{
      print('api failed successfully');
    }*/

    try {
      // Read the image file
      List<int> imageBytes = await File(imagePath).readAsBytes();
      print('inside try catch');
      // Encode the image data to base64
      String base64Image = base64Encode(imageBytes);

      // Create a JSON payload with the base64-encoded image
      Map<String, dynamic> requestBody = {
        'image': base64Image,
      };
      print('inside try catch 1 ' + base64Image);
      // Send a POST request with the image data
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-AnnexCloud-Site': '$siteid',
        },
        body: jsonEncode(requestBody),
      );

      // Check the response status code
      if (response.statusCode == 200) {
        // Successful response, you can handle the response data here
        print('Image uploaded successfully');
      } else {
        // Handle the error
        print('Image upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors or exceptions
      print('Error: $e');
    }
  }
}
