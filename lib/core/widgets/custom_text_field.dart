import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final String? initialValue;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final int? maxLines;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.initialValue,
    this.focusNode,
    this.validator,
    this.maxLines = 1,
    this.suffixIcon,
    this.onSuffixTap,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[  
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withAlpha(50), 
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: TextFormField(
            focusNode: _focusNode,
            initialValue: widget.initialValue,
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            autofocus: widget.autofocus,
            validator: widget.validator,
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, size: 18) : null,
              suffixIcon: widget.suffixIcon != null 
                ? IconButton(
                    icon: Icon(widget.suffixIcon, size: 18),
                    onPressed: widget.onSuffixTap,
                  ) 
                : null,
            ),
          ),
        ),
      ],
    );
  }
}
