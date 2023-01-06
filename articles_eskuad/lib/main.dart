import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Articles'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  bool isLoading = false;
  List articles = [];
  var sortBool = false;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
      print(result);
      if (result == ConnectivityResult.none) {
        Fluttertoast.showToast(
            msg: "No hay conexión a internet",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        this.fetchData();
      }
    } catch (e) {
      developer.log('No se pudo revisar la conexión', error: e);
      return;
    }
    if (!mounted) {
      return Future.value(null);
    }
    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  void sortByDate() {
    if (sortBool) {
      setState(() {
        articles.sort((a, b) {
          return b['created_at'].compareTo(a['created_at']);
        });
      });
    } else {
      setState(() {
        articles.sort((a, b) {
          return a['created_at'].compareTo(b['created_at']);
        });
      });
    }
    sortBool = !sortBool;
  }

  Future fetchData() async {
    sortBool = false;
    setState(() {
      isLoading = true;
    });
    var url = "https://hn.algolia.com/api/v1/search_by_date?query=mobile";
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var items = json.decode(response.body)['hits'];
      setState(() {
        articles = items;
        isLoading = false;
      });
    } else {
      articles = [];
      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: Icon(sortBool ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            onPressed: sortByDate,
          ),
        ),
        body: mainBody());
  }

  Widget mainBody() {
    if (articles.contains(null) || articles.length < 0 || isLoading) {
      return Center(
          child: CircularProgressIndicator(
        valueColor: new AlwaysStoppedAnimation<Color>(Colors.blue),
      ));
    }
    return RefreshIndicator(
        onRefresh: initConnectivity,
        child: ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              return Article(
                  createdAt: articles[index]['created_at'] ?? 'No date',
                  storyTitle: articles[index]['story_title'] ?? 'No title',
                  author: articles[index]['author'] ?? 'No author');
            }));
  }
}

class Article extends StatelessWidget {
  String createdAt;
  String storyTitle;
  String author;

  Article({
    super.key,
    required this.createdAt,
    required this.storyTitle,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(storyTitle),
              subtitle: Text("Author : " + author),
              trailing: Text(createdAt),
            ),
          ],
        ),
      ),
    );
  }
}
