import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  const ImageViewerScreen(
      {super.key, required this.fileName, required this.imageUrl});

  Future<void> _launchURL() async {
    if (await canLaunch(imageUrl)) {
      await launch(imageUrl);
    } else {
      throw 'Não foi possível abrir o URL: $imageUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visualizar Imagem')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Text(fileName, style: Theme.of(context).textTheme.titleLarge),
          ),
          Center(
            child: ElevatedButton(
              onPressed: _launchURL,
              child: const Text('Baixar Imagem'),
            ),
          ),
        ],
      ),
    );
  }
}
