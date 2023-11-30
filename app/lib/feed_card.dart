import 'package:flutter/material.dart';
import 'package:marcas_nao_estatico/detalhes.dart';

class FeedCard extends StatelessWidget {
  final String imgUrl = 'http://10.0.2.2:5004/';
  final List<dynamic> feed;
  const FeedCard({
    Key? key,
    required this.feed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Detalhes(feedId: feed[0]["_id"]),
          ),
        );
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(imgUrl + feed[0]["product"]["blobs"][0]["file"]),
            ListTile(
              leading: CircleAvatar(
                child: ClipOval(
                  child: Image.network(imgUrl + feed[0]["company"]["avatar"]),
                ),
              ),
              title: Text(
                feed[0]["company"]["name"],
                style: const TextStyle(fontSize: 17),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                feed[0]["product"]["name"],
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                height: 100,
                child: Text(
                  feed[0]["product"]["description"],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Text(
                      feed[0]["product"]["price"].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(
                    Icons.favorite_rounded,
                    size: 16,
                  ),
                  Text(
                    feed[0]["likes"].toString(),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
