import 'dart:io';

import "package:dio/dio.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:gql/language.dart" as gql;
import "package:gql_dio_link/gql_dio_link.dart";
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

import 'my_ip.dart';

/// This for showing success operation
const query = """
{
  companies {
    id
    name
  }
}
""";

/// This is for uploading image
const mutation = """
mutation uploadImage(\$input:Upload!){
  uploadImage(input:\$input)
}
""";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _mutationResult = 'No mutation result';
  String _queryResult = 'No query result';

  _upload() async {
    setState(() {
      _mutationResult = "uploading..........";
      _queryResult = "loading..........";
    });

    final dio = Dio(
      BaseOptions(
        connectTimeout: 5000,
      ),
    );

    final Link link = DioLink(
      "http://$MY_IP:9002/graphql",
      client: dio,
    );

    final client = GraphQLClient(
      cache: GraphQLCache(),
      link: link,
    );

    /// This should run successfully
    final queryResult = await client.query(
      QueryOptions(document: gql.parseString(query)),
    );

    print('queryResult result: $queryResult');

    setState(() {
      _queryResult = queryResult.toString();
    });

    final file = await getImageFileFromAssets();

    /// But this will cause error due to encoding
    final mutationResult = await client.mutate(
      MutationOptions(
        document: gql.parseString(mutation),
        variables: {
          "input": await MultipartFile.fromFile(
            file.path,
            filename: "image.png",
            contentType: MediaType("image", "png"),
          )
        },
      ),
    );

    print('mutationResult result: $mutationResult');

    setState(() {
      _mutationResult = mutationResult.toString();
    });
  }

  Future<File> getImageFileFromAssets() async {
    final byteData = await rootBundle.load('images/image.png');

    final file = File('${(await getTemporaryDirectory()).path}/image.png');
    await file.writeAsBytes(
      byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );

    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            SizedBox(
              width: 100,
              height: 100,
              child: FutureBuilder<File>(
                future: getImageFileFromAssets(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.file(snapshot.data!);
                  }

                  return Text('Failed loading image');
                },
              ),
            ),
            Text(
              'Query Result:',
            ),
            Text(
              '$_queryResult',
              style: TextStyle(
                color: Colors.green,
              ),
            ),
            Divider(thickness: 8),
            Text(
              'Upload result:',
            ),
            Text(
              '$_mutationResult',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _upload,
        label: Text('Upload'),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
