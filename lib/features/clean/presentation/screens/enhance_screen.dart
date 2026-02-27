import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';


class EnhanceScreen extends StatefulWidget {
  final AssetEntity asset;
  const EnhanceScreen({super.key, required this.asset});

  @override
  State<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends State<EnhanceScreen> {
  double _brightness = 0.0;
  double _contrast = 1.0;
  bool _showOriginal = false;
  Uint8List? _imageData;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await widget.asset.thumbnailDataWithSize(const ThumbnailSize(1200, 1800));
    if (mounted) {
      setState(() => _imageData = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.5),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel', style: TextStyle(color: CupertinoColors.white)),
          onPressed: () => Navigator.pop(context),
        ),
        middle: const Text('Enhance', style: TextStyle(color: CupertinoColors.white)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Done', style: TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: _imageData == null
                  ? const CupertinoActivityIndicator()
                  : GestureDetector(
                      onTapDown: (_) => setState(() => _showOriginal = true),
                      onTapUp: (_) => setState(() => _showOriginal = false),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildFilteredImage(_brightness, _contrast),
                          if (_showOriginal)
                            _buildFilteredImage(0.0, 1.0),
                          if (_showOriginal)
                            Positioned(
                              top: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0x8A000000),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('ORIGINAL', style: TextStyle(color: CupertinoColors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          const Positioned(
                            bottom: 20,
                            child: Text('Press and hold to see original', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildFilteredImage(double brightness, double contrast) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        contrast, 0, 0, 0, brightness * 255,
        0, contrast, 0, 0, brightness * 255,
        0, 0, contrast, 0, brightness * 255,
        0, 0, 0, 1, 0,
      ]),
      child: Image.memory(_imageData!, fit: BoxFit.contain),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SliderRow(
            icon: CupertinoIcons.sun_max_fill,
            label: 'Brightness',
            value: _brightness,
            min: -0.5,
            max: 0.5,
            onChanged: (val) => setState(() => _brightness = val),
          ),
          const SizedBox(height: 24),
          _SliderRow(
            icon: CupertinoIcons.circle_lefthalf_fill,
            label: 'Contrast',
            value: _contrast,
            min: 0.5,
            max: 1.5,
            onChanged: (val) => setState(() => _contrast = val),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: CupertinoColors.systemGrey, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: CupertinoColors.white, fontSize: 14)),
            const Spacer(),
            Text(value.toStringAsFixed(2), style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
          ],
        ),
        CupertinoSlider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
