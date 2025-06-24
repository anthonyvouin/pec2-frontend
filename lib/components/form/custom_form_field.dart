import 'package:firstflutterapp/components/form/build_input_decoration.dart';
import 'package:firstflutterapp/services/validators_service.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    required this.controller,
    required this.label,
    this.validators = const [],
    this.obscure = false,
    this.showText = false,
    this.maxLine = 1,

    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final bool showText;
  final int maxLine;
  final List<Validator> validators;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _showText;

  @override
  void initState() {
    super.initState();
    _showText = widget.showText;
  }

  void _toggleObscure() {
    setState(() {
      _showText = !_showText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscure && !_showText,
      maxLines: widget.maxLine,
      decoration: buildInputDecoration(
        colorScheme: colorScheme,
        label: widget.label,
      ).copyWith(
        suffixIcon:
            widget.obscure
                ? IconButton(
                  icon: Icon(
                    _showText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: _toggleObscure,
                )
                : null,
      ),
      validator: (String? value) {
        for (final validator in widget.validators) {
          final result = validator.validate(value);
          if (result != null) return result;
        }
        return null;
      },
    );
  }
}
