import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../consts.dart';
import '../data/photo_storage.dart';
import '../data/preset_repository.dart';
import '../models/preset.dart';

class PresetListScreen extends StatefulWidget {
  final PresetRepository repository;
  final int currentWaterPerc;
  final double currentOilPerc;
  final double currentSaltPerc;
  final double currentYeastPerc;
  final String currentYeastType;
  final double currentImpastoRatio;

  const PresetListScreen({
    super.key,
    required this.repository,
    required this.currentWaterPerc,
    required this.currentOilPerc,
    required this.currentSaltPerc,
    required this.currentYeastPerc,
    this.currentYeastType = 'fresh',
    required this.currentImpastoRatio,
  });

  @override
  State<PresetListScreen> createState() => _PresetListScreenState();
}

class _PresetListScreenState extends State<PresetListScreen> {
  List<Preset> _presets = [];
  bool _loading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final presets = await widget.repository.getAll();
    setState(() {
      _presets = presets;
      _loading = false;
    });
  }

  String _defaultName() {
    return 'Impasto del ${DateFormat('dd/MM').format(DateTime.now())}';
  }

  Future<void> _pickPhoto(List<String> photos, StateSetter setDialogState) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: cardDark,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryColor),
              title: Text(AppLocalizations.of(context)!.takePhoto,
                  style: const TextStyle(color: primaryTextColor)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryColor),
              title: Text(AppLocalizations.of(context)!.pickFromGallery,
                  style: const TextStyle(color: primaryTextColor)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      final saved = await savePhoto(picked);
      setDialogState(() {
        photos.add(saved);
      });
    }
  }

  Widget _buildPhotoRow(
      List<String> photos, StateSetter setDialogState, bool editable) {
    if (photos.isEmpty && !editable) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 70,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              ...photos.asMap().entries.map((entry) {
                final index = entry.key;
                final path = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image(
                          image: loadPhotoProvider(path),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: secondaryColor,
                            child: const Icon(Icons.broken_image,
                                color: secondaryTextColor, size: 24),
                          ),
                        ),
                      ),
                      if (editable)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                photos.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              if (editable)
                GestureDetector(
                  onTap: () => _pickPhoto(photos, setDialogState),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: secondaryTextColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_a_photo,
                        color: secondaryTextColor, size: 24),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _showSaveDialog() async {
    final nameController = TextEditingController(text: _defaultName());
    final notesController = TextEditingController();
    final photos = <String>[];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardDark,
          title:
              Text(AppLocalizations.of(context)!.save, style: const TextStyle(color: primaryColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.presetName,
                    labelStyle: const TextStyle(color: secondaryTextColor),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: secondaryTextColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: primaryTextColor),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.presetNotes,
                    labelStyle: const TextStyle(color: secondaryTextColor),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: secondaryTextColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                _buildPhotoRow(photos, setDialogState, true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel,
                  style: const TextStyle(color: secondaryTextColor)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(color: primaryColor)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final preset = Preset(
        name: nameController.text.trim().isEmpty
            ? _defaultName()
            : nameController.text.trim(),
        createdAt: DateTime.now(),
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        waterPerc: widget.currentWaterPerc,
        oilPerc: widget.currentOilPerc,
        saltPerc: widget.currentSaltPerc,
        yeastPerc: widget.currentYeastPerc,
        yeastType: widget.currentYeastType,
        impastoRatio: widget.currentImpastoRatio,
        mediaPaths: photos,
      );
      await widget.repository.insert(preset);
      await _loadPresets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.presetSaved, style: const TextStyle(color: primaryTextColor)),
            backgroundColor: cardDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } else {
      // User cancelled — clean up any saved photos
      await deletePhotos(photos);
    }
  }

  Future<void> _showEditDialog(Preset preset) async {
    final nameController = TextEditingController(text: preset.name);
    final notesController = TextEditingController(text: preset.notes ?? '');
    final photos = List<String>.from(preset.mediaPaths);
    final removedPhotos = <String>[];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardDark,
          title: Text(AppLocalizations.of(context)!.editPreset,
              style: const TextStyle(color: primaryColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.presetName,
                    labelStyle: const TextStyle(color: secondaryTextColor),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: secondaryTextColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: primaryTextColor),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.presetNotes,
                    labelStyle: const TextStyle(color: secondaryTextColor),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: secondaryTextColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                _buildPhotoRow(photos, (fn) {
                  setDialogState(() {
                    final before = List<String>.from(photos);
                    fn();
                    for (final p in before) {
                      if (!photos.contains(p)) removedPhotos.add(p);
                    }
                  });
                }, true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel,
                  style: const TextStyle(color: secondaryTextColor)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(color: primaryColor)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await deletePhotos(removedPhotos);
      final updated = preset.copyWith(
        name: nameController.text.trim().isEmpty
            ? preset.name
            : nameController.text.trim(),
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        mediaPaths: photos,
      );
      await widget.repository.update(updated);
      await _loadPresets();
    }
  }

  Future<void> _confirmDelete(Preset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        title:
            Text(AppLocalizations.of(context)!.deletePreset, style: const TextStyle(color: primaryColor)),
        content: Text(
          AppLocalizations.of(context)!.deletePresetConfirm(preset.name),
          style: const TextStyle(color: primaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: secondaryTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deletePhotos(preset.mediaPaths);
      await widget.repository.delete(preset.id!);
      await _loadPresets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.presetDeleted(preset.name), style: const TextStyle(color: primaryTextColor)),
            backgroundColor: cardDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _loadPreset(Preset preset) {
    Navigator.pop(context, preset);
  }

  void _showPhotoViewer(List<String> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: photos.length,
              itemBuilder: (context, index) => InteractiveViewer(
                child: Center(
                  child: Image(
                    image: loadPhotoProvider(photos[index]),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: secondaryTextColor,
                        size: 48),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetPhotos(List<String> photos) {
    if (photos.isEmpty) return const SizedBox.shrink();
    final visibleCount = photos.length > 4 ? 4 : photos.length;
    final extra = photos.length - visibleCount;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            ...photos.take(visibleCount).toList().asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () => _showPhotoViewer(photos, entry.key),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image(
                      image: loadPhotoProvider(entry.value),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 40,
                        height: 40,
                        color: secondaryColor,
                        child: const Icon(Icons.broken_image,
                            color: secondaryTextColor, size: 16),
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (extra > 0)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                        color: secondaryTextColor, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          AppLocalizations.of(context)!.saved,
          style: const TextStyle(color: primaryColor, fontSize: 24),
        ),
        backgroundColor: secondaryColor,
        iconTheme: const IconThemeData(color: primaryColor),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined, color: primaryColor, size: 28),
            tooltip: AppLocalizations.of(context)!.saveCurrentParams,
            onPressed: _showSaveDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _presets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bookmark_border,
                          color: secondaryTextColor, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.noPresets,
                        style:
                            const TextStyle(color: secondaryTextColor, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.noPresetsHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: lightGrey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _presets.length,
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    final dateStr =
                        DateFormat('dd/MM/yyyy HH:mm').format(preset.createdAt);
                    return Card(
                      color: cardDark,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        title: Text(
                          preset.name,
                          style: const TextStyle(
                            color: primaryTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                  color: lightGrey, fontSize: 13),
                            ),
                            if (preset.notes != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                preset.notes!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: secondaryTextColor, fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${AppLocalizations.of(context)!.water} ${preset.waterPerc}%  ${AppLocalizations.of(context)!.salt} ${preset.saltPerc}%  '
                              '${AppLocalizations.of(context)!.yeast} ${preset.yeastPerc}% (${preset.yeastType == 'dry' ? AppLocalizations.of(context)!.yeastDry : AppLocalizations.of(context)!.yeastFresh})  ${AppLocalizations.of(context)!.oil} ${preset.oilPerc}%',
                              style: const TextStyle(
                                  color: lightGrey, fontSize: 12),
                            ),
                            _buildPresetPhotos(preset.mediaPaths),
                          ],
                        ),
                        onTap: () => _loadPreset(preset),
                        trailing: PopupMenuButton<String>(
                          iconColor: secondaryTextColor,
                          color: cardDark,
                          onSelected: (action) {
                            if (action == 'edit') _showEditDialog(preset);
                            if (action == 'delete') _confirmDelete(preset);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(AppLocalizations.of(context)!.edit,
                                  style: const TextStyle(color: primaryTextColor)),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(AppLocalizations.of(context)!.delete,
                                  style: const TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
