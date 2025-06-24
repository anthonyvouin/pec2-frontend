import 'package:flutter/material.dart';

class DisabledMessageInput extends StatelessWidget {
  const DisabledMessageInput({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[200],
      child: Center(
        child: Text(
          'L\'utilisateur ne souhaite plus recevoir de messages privés',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
