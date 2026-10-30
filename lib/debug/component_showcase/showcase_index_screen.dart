import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/theme/app_tokens.dart';
import '../showcase_navigation.dart';
import 'showcase_examples.dart';

class ShowcaseIndexScreen extends StatelessWidget {
  const ShowcaseIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: const ShowcaseAppBar(title: 'Component showcase'),
      body: SafeArea(
        child: ListView.separated(
          key: const PageStorageKey<String>('debug-component-index'),
          padding: EdgeInsets.all(tokens.spaceLg),
          itemCount: showcaseComponents.length + 1,
          separatorBuilder: (_, _) => SizedBox(height: tokens.spaceMd),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available components',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: tokens.spaceSm),
                    const Text(
                      'Debug only. Open a component to inspect its states, variants, actions, and fallback behaviour.',
                    ),
                  ],
                ),
              );
            }
            final component = showcaseComponents[index - 1];
            final count = component.examples.length;
            return Card(
              child: ListTile(
                contentPadding: EdgeInsets.all(tokens.spaceLg),
                leading: Icon(component.icon),
                title: Text(component.title),
                subtitle: Text('${component.description}\n$count examples'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(
                  ShowcaseNavigation.detailRoute,
                  pathParameters: {'componentId': component.id},
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
