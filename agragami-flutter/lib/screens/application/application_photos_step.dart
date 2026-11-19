import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/cloudinary_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

enum PhotoKind { photo, nidFront, nidBack }

/// সদস্য আবেদনের দ্বিতীয় ধাপ — নিজের ছবি ও এনআইডির ছবি
class ApplicationPhotosStep extends StatelessWidget {
  final Uint8List? photoBytes;
  final Uint8List? nidFrontBytes;
  final Uint8List? nidBackBytes;
  final void Function(PhotoKind) onPickPhoto;
  // Phase 5: বাছা ছবি সরানোর পথ — ছবি ব্যর্থ হলে
  // ছবি ছাড়াই আবেদন জমা দেওয়া যায়।
  final void Function(PhotoKind) onRemovePhoto;

  const ApplicationPhotosStep({
    super.key,
    required this.photoBytes,
    required this.nidFrontBytes,
    required this.nidBackBytes,
    required this.onPickPhoto,
    required this.onRemovePhoto,
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
          'ছবি JPG বা PNG হতে হবে, ৫ MB-এর বেশি নয়। ছবি দেওয়া ঐচ্ছিক — ছবি ছাড়াই আবেদন করা যাবে।',
          style: TextStyle(fontSize: 13.5, color: AppColors.muted),
        ),
        if (!CloudinaryConfig.isConfigured) ...[
          const SizedBox(height: 8),
          const Text(
            'ছবি আপলোড এখনো চালু হয়নি — এখন ছবি দিলে তা জমা হবে না, তবে আবেদন জমা হবে।',
            style: TextStyle(fontSize: 13.5, color: AppColors.amber),
          ),
        ],
        const SizedBox(height: 16),
        _PhotoPickTile(
          label: 'নিজের ছবি (ঐচ্ছিক)',
          bytes: photoBytes,
          onPick: () => onPickPhoto(PhotoKind.photo),
          onRemove: () => onRemovePhoto(PhotoKind.photo),
        ),
        const SizedBox(height: 12),
        _PhotoPickTile(
          label: 'এনআইডির সামনের ছবি (ঐচ্ছিক)',
          bytes: nidFrontBytes,
          onPick: () => onPickPhoto(PhotoKind.nidFront),
          onRemove: () => onRemovePhoto(PhotoKind.nidFront),
        ),
        const SizedBox(height: 12),
        _PhotoPickTile(
          label: 'এনআইডির পেছনের ছবি (ঐচ্ছিক)',
          bytes: nidBackBytes,
          onPick: () => onPickPhoto(PhotoKind.nidBack),
          onRemove: () => onRemovePhoto(PhotoKind.nidBack),
        ),
      ],
    );
  }
}

class _PhotoPickTile extends StatelessWidget {
  final String label;
  final Uint8List? bytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _PhotoPickTile({
    required this.label,
    required this.bytes,
    required this.onPick,
    required this.onRemove,
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
          if (bytes != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: TextButton(
                onPressed: onRemove,
                child: const Text('সরান'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
