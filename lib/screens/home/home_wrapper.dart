import 'package:flutter/material.dart';
import 'package:bulusalim/screens/home/home_page.dart';

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Home sekmesi için özel, izole bir Navigator oluşturuyoruz.
    return Navigator(
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
          builder: (context) =>
              const HomePage(), // İlk açılışta HomePage gelsin
        );
      },
    );
  }
}
