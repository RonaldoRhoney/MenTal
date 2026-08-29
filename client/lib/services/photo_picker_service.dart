import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../screens/photo_crop_screen.dart';
import '../theme/app_theme.dart';

/// Fluxo completo de escolher/tirar + recortar uma foto de perfil
/// (29/08/2026, pedido de Rhoney: "o usuário deve ter a opção de também
/// tirar uma foto, além de fazer upload e poder recortar a foto antes
/// de salvar"). Compartilhado entre ProfileScreen e
/// MandatoryOnboardingScreen — as duas telas fazem o UPLOAD de formas
/// levemente diferentes (uma edita um perfil já existente, a outra é
/// parte do onboarding), então este serviço só cobre até devolver o
/// arquivo já recortado, pronto pra upload.
class PhotoPickerService {
  const PhotoPickerService._();

  /// Mostra um bottom sheet pra escolher Câmera ou Galeria, depois abre
  /// a tela de recorte (proporção 1:1, igual ao círculo de exibição).
  /// Devolve null se o usuário cancelar em qualquer etapa.
  static Future<File?> pickAndCrop(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.gold),
              title: Text(l10n.photoSourceCameraOption),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.gold),
              title: Text(l10n.photoSourceGalleryOption),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return null;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !context.mounted) return null;

    final bytes = await picked.readAsBytes();
    if (!context.mounted) return null;

    final croppedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => PhotoCropScreen(imageBytes: bytes)),
    );
    if (croppedBytes == null) return null;

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(croppedBytes);
    return file;
  }
}
