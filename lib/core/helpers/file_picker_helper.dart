import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_alsawy/core/extensions/context_extension.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';

class FilePickerHelper {
  static void showFilePicker(
      BuildContext context, Function(File?) onFilePicked) {
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
              Text('chooseFileType'.tr(), style: TextStyles.blackBold20),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.primaryColor,
                ),
                title: Text(
                  'choosePdf'.tr(),
                  style: TextStyles.blackBold14,
                ),
                onTap: () => _pickFile(context, onFilePicked,
                    fileType: 'pdf', dismissSheetWhenPicked: true),
              ),
            ],
          ),
        );
      },
    );
  }

  static pickFile(BuildContext context, Function(File?) onFilePicked,
      {bool allowMultiple = false}) {
    return _pickFile(context, onFilePicked,
        fileType: "pdf",
        allowMultiple: allowMultiple,
        dismissSheetWhenPicked: false);
  }

  static Future<void> _pickFile(
      BuildContext context, Function(File?) onFilePicked,
      {required String fileType,
      bool allowMultiple = false,
      bool dismissSheetWhenPicked = false}) async {
    // Only allow PDF files. Ignore other fileType values and always restrict to ['pdf'].
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) {
      // user canceled
      onFilePicked(null);
      return;
    }

    final picked = result.files.first;
    final path = picked.path;
    if (path == null) {
      onFilePicked(null);
      return;
    }

    if (!path.toLowerCase().endsWith('.pdf')) {
      context.showErrorMessage('onlyPdfAllowed'.tr());
      onFilePicked(null);
      return;
    }

    // If this picker was opened from the bottom sheet, dismiss it now so
    // the UI returns to the screen where upload progress can be shown.
    if (dismissSheetWhenPicked) {
      try {
        Navigator.of(context).pop();
      } catch (_) {
        // ignore if pop fails
      }
    }

    onFilePicked(File(path));
  }
}
