import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../core/theme/neumorphic_theme.dart';
import 'neu_button.dart';
import 'neu_container.dart';

/// Recessed / Sunken Dropzone for File & Document Picking
class NeuDropzone extends StatelessWidget {
  final String? selectedFileName;
  final String? subtitle;
  final VoidCallback onPickFile;
  final VoidCallback? onClearFile;
  final bool isUploading;

  const NeuDropzone({
    super.key,
    this.selectedFileName,
    this.subtitle,
    required this.onPickFile,
    this.onClearFile,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final hasFile = selectedFileName != null && selectedFileName!.isNotEmpty;

    return NeuContainer(
      depthType: NeuDepth.concave,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      border: Border.all(
        color: neuTheme.darkShadow.withValues(alpha: 0.3),
        width: 1.5,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuContainer(
              shape: BoxShape.circle,
              width: 58,
              height: 58,
              depthType: hasFile ? NeuDepth.convex : NeuDepth.concave,
              depth: 3.0,
              alignment: Alignment.center,
              child: isUploading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(neuTheme.accentColor),
                      ),
                    )
                  : Icon(
                      hasFile ? TablerIcons.file_check : TablerIcons.cloud_upload,
                      size: 28,
                      color: hasFile ? neuTheme.successColor : neuTheme.accentColor,
                    ),
            ),
            const SizedBox(height: 14),
            if (hasFile) ...[
              Text(
                selectedFileName!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: neuTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Document attached',
                style: TextStyle(
                  color: neuTheme.successColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NeuButton(
                    text: 'Change File',
                    icon: TablerIcons.refresh,
                    height: 38,
                    depth: 2.5,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onPressed: onPickFile,
                  ),
                  if (onClearFile != null) ...[
                    const SizedBox(width: 12),
                    NeuIconButton(
                      icon: TablerIcons.trash,
                      size: 38,
                      iconSize: 18,
                      iconColor: neuTheme.dangerColor,
                      tooltip: 'Remove File',
                      onPressed: onClearFile,
                    ),
                  ],
                ],
              ),
            ] else ...[
              Text(
                'Upload Deliverable / PDF',
                style: TextStyle(
                  color: neuTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle ?? 'Tap below to browse documents (PDF, ZIP, DOCX)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: neuTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              NeuButton(
                text: 'Select File',
                icon: TablerIcons.paperclip,
                height: 40,
                isAccent: true,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                onPressed: onPickFile,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
