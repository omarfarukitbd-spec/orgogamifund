import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

enum PhotoKind { photo, nidFront, nidBack }

/// সদস্য আবেদনের দ্বিতীয় ধাপ — নিজের ছবি ও এনআইডির ছবি
class ApplicationPhotosStep extends StatelessWidget {
  final Uint8List? photoBytes;
  final Uint8List? nidFrontBytes;
  final Uint8List? nidBackBytes;
  final void Function(PhotoKind) onPickPhoto;

  const ApplicationPhotosStep({
    super.key,
    required this.photoBytes,
    required this.nidFrontBytes,
    required this.nidBackBytes,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'এবার ছবি যোগ করুন',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'ছবি JPG বা PNG হতে হবে, ৫ MB-এর বেশি নয়।',
          style: TextStyle(fontSize: 13.5, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        _PhotoPickTile(
          label: 'নিজের ছবি',
          bytes: photoBytes,
          onPick: () => onPickPhoto(PhotoKind.photo),
        ),
        const SizedBox(height: 12),
        _PhotoPickTile(
          label: 'এনআইডির সামনের ছবি',
          bytes: nidFrontBytes,
          onPick: () => onPickPhoto(PhotoKind.nidFront),
        ),
        const SizedBox(height: 12),
        _PhotoPickTile(
          label: 'এনআইডির পেছনের ছবি (ঐচ্ছিক)',
          bytes: nidBackBytes,
          onPick: () => onPickPhoto(PhotoKind.nidBack),
        ),
      ],
    );
  }
}

class _PhotoPickTile extends StatelessWidget {
  final String label;
  final Uint8List? bytes;
  final VoidCallback onPick;

  const _PhotoPickTile({
    required this.label,
    required this.bytes,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          bytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    bytes!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                )
              : const ListIcon(icon: Icons.image_outlined, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bytes != null ? 'ছবি যোগ হয়েছে' : 'এখনো ছবি যোগ হয়নি',
                  style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: onPick,
              child: Text(bytes != null ? 'বদলান' : 'ছবি নিন'),
            ),
          ),
        ],
      ),
    );
  }
}
