import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_alsawy/core/helpers/image_compress_function.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';

class ImagePickerHelper {
  static Future<void> pickImage(
    BuildContext context,
    Function(File?) onImagePicked, {
    required ImageSource source,
  }) async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final originalFile = File(pickedFile.path);
      try {
        final compressor = ImageCompressHelper();
        final compressed = await compressor.compressFile(originalFile);
        onImagePicked(compressed);
      } catch (e) {
        // if compression fails, return original file
        onImagePicked(originalFile);
      }
    }
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  static void showImagePicker(
      BuildContext context, Function(File?) onImagePicked) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'chooseProfileImage'.tr(),
                style: TextStyles.darkBold20,
              ),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: AppColors.primaryColor),
                title: Text(
                  'takePhoto'.tr(),
                  style: TextStyles.darkBold16,
                ),
                onTap: () => pickImage(context, onImagePicked,
                    source: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppColors.primaryColor),
                title: Text(
                  'chooseFromGallery'.tr(),
                  style: TextStyles.darkBold16,
                ),
                onTap: () => pickImage(context, onImagePicked,
                    source: ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }
}
