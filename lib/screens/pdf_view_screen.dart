import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PDFViewerScreen extends StatelessWidget {
  final String pdfUrl;
  final String fileName;

  const PDFViewerScreen(
      {super.key, required this.pdfUrl, required this.fileName});

  Future<void> _launchURL() async {
    if (await canLaunch(pdfUrl)) {
      await launch(pdfUrl);
    } else {
      throw 'Não foi possível abrir o URL: $pdfUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visualizar PDF')),
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
              child: const Text('Baixar PDF'),
            ),
          ),
        ],
      ),
    );
  }
}
