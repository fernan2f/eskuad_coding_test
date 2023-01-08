import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'components/article.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eskuad Articles',
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
  ScrollController scrollController = ScrollController();
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  bool isLoading = false;
  List articles = [];
  var sortBool = false;
  String sortedText = "Descending order";
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
        fetchData();
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
      sortedText = "Descending order";
      setState(() {
        articles.sort((a, b) {
          return b['created_at'].compareTo(a['created_at']);
        });
      });
    } else {
      sortedText = "Ascending order";
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
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(sortedText),
              Center(
                child: IconButton(
                  icon: Icon(
                      sortBool ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                  onPressed: sortByDate,
                ),
              )
            ],
          )
        ],
      ),
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 1000), //show/hide animation
        opacity: 1.0, //set obacity to 1 on visible, or hide
        child: FloatingActionButton(
          onPressed: () {
            scrollController.animateTo(
                //go to top of scroll
                0, //scroll offset to go
                duration:
                    const Duration(milliseconds: 500), //duration of scroll
                curve: Curves.fastOutSlowIn //scroll type
                );
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.arrow_upward),
        ),
      ),
      body: Center(
          child: RefreshIndicator(
              onRefresh: initConnectivity,
              child: SingleChildScrollView(
                  controller: scrollController, child: mainBody2()))),
    );
  }

  Widget mainBody2() {
    if (articles.contains(null) || articles.length <= 0 || isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ));
    }
    return Column(
        children: articles.map((article) {
      return Article(
          createdAt: article['created_at'] ?? 'No date',
          storyTitle: article['story_title'] ?? 'No title',
          author: article['author'] ?? 'No author');
      ;
    }).toList());
  }

  /*

!!!!!!!!!!!!!!!!!!!!!!!NOT USED , DELETE IF YOU WANT !!!!!!!!!!!!!!!!!!!!!!!

Widget mainBody() {
    if (articles.contains(null) || articles.length <= 0 || isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
 */
}
