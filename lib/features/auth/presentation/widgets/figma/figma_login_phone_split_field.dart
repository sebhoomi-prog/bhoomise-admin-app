import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/design_tokens.dart';

/// Side-by-side dial + phone — organic login (`9:673`): filled rounded tiles, no outer chrome.
class FigmaLoginPhoneSplitField extends StatelessWidget {
  const FigmaLoginPhoneSplitField({
    super.key,
    required this.dialCode,
    required this.onDialChanged,
    required this.controller,
    required this.placeholder,
    required this.brand,
    required this.fieldFill,
    required this.usStyleDashes,
  });

  final String dialCode;
  final ValueChanged<String> onDialChanged;
  final TextEditingController controller;
  final String placeholder;
  final Color brand;
  final Color fieldFill;
  /// When true (e.g. +1), format as `000-000-0000`.
  final bool usStyleDashes;

  static final _placeholderColor =
      const Color(0xFF718096).withValues(alpha: 0.55);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: _FilledTile(
            fill: fieldFill,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: dialCode,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: brand,
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: brand,
                ),
                items: const [
                  DropdownMenuItem(value: '+1', child: Text('+1')),
                  DropdownMenuItem(value: '+91', child: Text('+91')),
                ],
                onChanged: (v) {
                  if (v != null) onDialChanged(v);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spaceSm),
        Expanded(
          child: _FilledTile(
            fill: fieldFill,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: usStyleDashes
                  ? <TextInputFormatter>[_UsPhoneDashFormatter()]
                  : <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: const Color(0xFF1A202C),
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: _placeholderColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (v) {
                final raw = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (raw.length != 10) return 'Enter a valid 10-digit number';
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FilledTile extends StatelessWidget {
  const _FilledTile({required this.fill, required this.child});

  final Color fill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: child,
      ),
    );
  }
}

class _UsPhoneDashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 10 ? digits.substring(0, 10) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 3 || i == 6) buf.write('-');
      buf.write(limited[i]);
    }
    final t = buf.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
