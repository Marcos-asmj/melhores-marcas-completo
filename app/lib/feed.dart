import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'autenticador.dart';
import 'feed_card.dart';
import 'api/api.dart';

class Feed extends StatefulWidget {
  const Feed({super.key});

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  List<dynamic> feedList = [];
  int tamanhoPagina = 4;
  int pagina = 1;
  List<dynamic> foundFeeds = [];
  ScrollController _scrollController = ScrollController();
  Stopwatch stopwatch = Stopwatch();
  bool firstTime = true;

  @override
  void initState() {
    stopwatch.start();
    fetchFeedsData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        fetchFeedsData();
      }
    });
    foundFeeds = feedList;

    super.initState();
  }

  Future<void> fetchFeedsData() async {
    final feedsData = await getFeeds(pagina, tamanhoPagina);
    setState(() {
      feedList.addAll(feedsData);
      pagina = pagina + 1;
    });

    if (pagina > 1) {
      stopwatch.stop();
      if (firstTime) {
        String elapsedTime = stopwatch.elapsed.toString();
        print('Tempo: ${stopwatch.elapsedMilliseconds}ms');
        showTime(elapsedTime);
        firstTime = false;
      }
    }
  }

  Future<void> refreshList() async {
    feedList = [];
    pagina = 1;
    stopwatch.reset();
    stopwatch.start();
    firstTime = true;

    fetchFeedsData();

    setState(() {
      foundFeeds = feedList;
    });
  }

  void _runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      results = feedList;
    } else {
      results = feedList
          .where((produto) => produto["product"]["name"]
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      foundFeeds = results;
    });
  }

  void showTime(String elapsedTime) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Tempo para contruir e exibir feeds: ${stopwatch.elapsedMilliseconds}ms'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Feeds'),
        actions: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 10, bottom: 10, left: 90, right: 50),
              child: TextField(
                onChanged: (value) => _runFilter(value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              if (FirebaseAuth.instance.currentUser != null) {
                Autenticador().signOut();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Sessão encerrada"),
                      content:
                          const Text("Sua sessão foi encerrada com sucesso."),
                      actions: [
                        TextButton(
                          child: const Text("OK"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              } else {
                Autenticador().signInWithGoogle();
              }
            },
            icon: const Icon(Icons.account_circle_outlined),
            color: Colors.black,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshList(),
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 1.5 / 3,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5),
          itemCount: foundFeeds.length,
          itemBuilder: (context, index) {
            return FeedCard(feed: [foundFeeds[index]]);
          },
        ),
      ),
    );
  }
}
