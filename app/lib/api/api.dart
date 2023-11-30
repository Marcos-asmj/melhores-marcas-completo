import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

const String feedUrl = 'http://10.0.2.2:5001/feed/';
const String feedsUrl = 'http://10.0.2.2:5001/feeds/';

getFeed(int id) async {
  final response = await http.get(Uri.parse(feedUrl + id.toString()));
  var data = json.decode(response.body);

  return data;
}

getFeeds(int pagina, int tamanhoPagina) async {
  final response = await http.get(Uri.parse('$feedsUrl$pagina/$tamanhoPagina'));
  var data = json.decode(response.body);

  return data;
}
