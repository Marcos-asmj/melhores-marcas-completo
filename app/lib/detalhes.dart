import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:page_view_dot_indicator/page_view_dot_indicator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'api/api.dart';

class Detalhes extends StatefulWidget {
  final int feedId;
  const Detalhes({
    Key? key,
    required this.feedId,
  });

  @override
  State<StatefulWidget> createState() => _DetalhesState();
}

class _DetalhesState extends State<Detalhes> {
  List<dynamic> results = [];
  List<dynamic> comments = [];
  late int selectedPage;
  late final PageController _pageController;
  var CommentController = TextEditingController();
  String newComment = '';
  var curtido = false;
  final String imgUrl = 'http://10.0.2.2:5004/';

  @override
  void initState() {
    initializeDateFormatting('pt_BR');
    fetchFeedData();
    selectedPage = 0;
    _pageController = PageController(initialPage: selectedPage);

    super.initState();
  }

  Future<void> fetchFeedData() async {
    final feedData = await getFeed(widget.feedId);
    setState(() {
      results = [feedData];
    });
  }

  void addComment(String comment) {
    var newCommentData = {
      "content": comment,
      "user": {
        "name": "Nome do Usuário",
      },
      "datetime": DateTime.now().toString(),
    };

    setState(() {
      comments.add(newCommentData);
    });
  }

  String formatarDataHora(String dataHora) {
    DateTime dateTime = DateTime.parse(dataHora);
    DateFormat formato = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    return formato.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 243, 243),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: results.isNotEmpty
            ? Text(results[0]["company"]["name"],
                style: const TextStyle(color: Colors.black))
            : const SizedBox.shrink(),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: <Widget>[
          CircleAvatar(
            child: results.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      imgUrl + results[0]["company"]["avatar"],
                    ),
                  )
                : Text("Imagem não disponível"),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 10),
          ),
          Visibility(
            visible: FirebaseAuth.instance.currentUser != null,
            child: IconButton(
              onPressed: () {
                if (curtido == false) {
                  setState(() {
                    results[0]["likes"] = results[0]["likes"] + 1;
                    curtido = true;
                  });
                } else {
                  setState(() {
                    results[0]["likes"] = results[0]["likes"] - 1;
                    curtido = false;
                  });
                }
              },
              icon: Icon(
                  (curtido == false) ? Icons.favorite_border : Icons.favorite),
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 275,
              child: PageView.builder(
                itemCount: 3,
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    selectedPage = page;
                  });
                },
                itemBuilder: (context, pagePosition) {
                  if (results.isNotEmpty) {
                    return Image.network(
                      imgUrl + results[0]["product"]["blobs"][0]["file"],
                    );
                  } else {
                    return Text("Dados da imagem não disponíveis");
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PageViewDotIndicator(
                currentItem: selectedPage,
                count: 3,
                unselectedColor: Colors.black26,
                selectedColor: Colors.blue,
                duration: const Duration(milliseconds: 200),
                boxShape: BoxShape.circle,
              ),
            ),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  results.isNotEmpty
                      ? Text(
                          results[0]["product"]["name"],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        )
                      : const SizedBox.shrink(),
                  results.isNotEmpty
                      ? Text(results[0]["product"]["description"])
                      : const SizedBox.shrink(),
                  results.isNotEmpty
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "R\$ ${results[0]["product"]["price"].toString()}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Icon(
                              Icons.favorite_rounded,
                              color: Colors.red,
                              size: 16,
                            ),
                            Text(results[0]["likes"].toString())
                          ],
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            const Text(
              "Comentários",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Visibility(
              visible: FirebaseAuth.instance.currentUser != null,
              child: TextField(
                controller: CommentController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Digite aqui seu comentário...',
                  suffixIcon: GestureDetector(
                    onTap: () {
                      if (newComment.isNotEmpty) {
                        addComment(newComment);
                        setState(() {
                          CommentController.clear();
                          newComment = '';
                        });
                      }
                    },
                    child: const Icon(Icons.send),
                  ),
                ),
                onChanged: (comment) {
                  setState(() {
                    newComment = comment;
                  });
                },
              ),
            ),
            ListView.builder(
              reverse: true,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(comments[index]["_id"].toString()),
                  onDismissed: (direction) {
                    final dismissedComment = comments[index];

                    setState(() {
                      comments.removeAt(index);
                    });

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Deseja apagar esse comentário?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  comments.insert(index, dismissedComment);
                                });
                                Navigator.of(context).pop();
                              },
                              child: const Text('Não'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Sim'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comments[index]["content"]),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              comments[index]["user"]["name"],
                            ),
                            const SizedBox(width: 16),
                            Text(
                              formatarDataHora(comments[index]["datetime"]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
