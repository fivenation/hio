import 'package:flutter/material.dart';
import 'package:hio/core/resources/resource_manager.dart';
import 'package:provider/provider.dart';

class AppDependencies extends StatelessWidget {
  final Widget child;
  
  const AppDependencies({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ResourcesManager>(
          create: (_) => ResourcesManager(),
          lazy: false,
        ),
      ],
      child: child,
    );
  }
}