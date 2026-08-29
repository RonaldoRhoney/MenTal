import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Tela de recorte de foto (29/08/2026, pedido de Rhoney: "poder
/// recortar a foto antes de salvar"). Usa `crop_your_image` (recorte
/// 100% em Flutter, sem Activity nativa Android) em vez de
/// `image_cropper` — achado real em dispositivo: image_cropper (que usa
/// a lib nativa uCrop) crashava com "IllegalStateException: Reply
/// already submitted" por um conflito conhecido de onActivityResult
/// entre plugins (github.com/Yalantis/uCrop/issues/581), não algo
/// corrigível no nosso código.
class PhotoCropScreen extends StatefulWidget {
  const PhotoCropScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final _controller = CropController();
  bool _cropping = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.photoCropToolbarTitle),
        actions: [
          IconButton(
            icon: _cropping
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _cropping ? null : () => setState(() => _controller.crop()),
          ),
        ],
      ),
      backgroundColor: AppColors.bg,
      body: Crop(
        controller: _controller,
        image: widget.imageBytes,
        aspectRatio: 1,
        withCircleUi: true,
        baseColor: AppColors.bg,
        maskColor: Colors.black.withValues(alpha: 0.6),
        onCropped: (result) {
          switch (result) {
            case CropSuccess(:final croppedImage):
              Navigator.of(context).pop(croppedImage);
            case CropFailure():
              if (mounted) setState(() => _cropping = false);
          }
        },
      ),
    );
  }
}
