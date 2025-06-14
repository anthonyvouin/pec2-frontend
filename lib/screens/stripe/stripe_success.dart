import 'package:firstflutterapp/components/title/title_onlyflick.dart';
import 'package:firstflutterapp/utils/mobile_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StripeSuccess extends StatelessWidget {
  const StripeSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    final fragment = Uri.base.fragment;
    final uri = Uri.parse(
      fragment.startsWith('/') ? fragment.substring(1) : fragment,
    );
    final creator = uri.queryParameters['creator'];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double formWidth = constraints.maxWidth > 800
                ? constraints.maxWidth / 3
                : double.infinity;

            return Center(
              child: Container(
                width: formWidth,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          TitleOnlyFlick(text: "Paiement réussi"),
                          const SizedBox(height: 20),
                          Text("Tu es abonné à ${creator ?? '...'} !"),
                          const SizedBox(height: 20),
                          Image.asset(
                            'assets/images/chat-content.png',
                            width: 300,
                            height: 300,
                          ),
                          const SizedBox(height: 20),
                          if (!isMobileBrowser(context))
                            ElevatedButton(
                              onPressed: () {
                                context.go("/");
                              },
                              child: const Text("Retourner à l'accueil"),
                            ),
                          if (isMobileBrowser(context))
                            const Text("Vous pouvez retourner sur l'application"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
