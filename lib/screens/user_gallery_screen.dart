
import 'package:flutter/material.dart';

class UserGalleryScreen extends StatelessWidget {
  const UserGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gallery")),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: 10,
        itemBuilder: (_, i) => Card(
          child: Center(child: Text("Image $i")),
        ),
      ),
    );
  }
}

