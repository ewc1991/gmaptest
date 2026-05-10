import 'package:flutter/material.dart';

class SearchControls extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final ValueChanged<double> onRadiusChanged;
  final double radiusMiles;
  final bool isLoading;

  const SearchControls({
    super.key,
    required this.onSearch,
    required this.onRadiusChanged,
    required this.radiusMiles,
    required this.isLoading,
  });

  @override
  State<SearchControls> createState() => _SearchControlsState();
}

class _SearchControlsState extends State<SearchControls> {
  final _controller = TextEditingController();

  static const _radii = [0.5, 1.0, 2.0, 5.0, 10.0];

  String _radiusLabel(double r) => r < 1 ? '${r}mi' : '${r.toStringAsFixed(0)}mi';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              onChanged: widget.onSearch,
              onSubmitted: widget.onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Restaurants, cafes, bars…',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: widget.isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(Icons.search, color: Colors.grey[500], size: 22),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[500], size: 20),
                        onPressed: () {
                          _controller.clear();
                          widget.onSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: widget.radiusMiles,
              icon: const Icon(Icons.expand_more, size: 18),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              items: _radii
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(_radiusLabel(r)),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) widget.onRadiusChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
