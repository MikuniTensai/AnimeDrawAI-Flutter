import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math' as math;
import '../../../services/ad_helper.dart';
import '../../../data/providers/navigation_provider.dart';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/generation_repository.dart';
import '../../../data/utils/content_moderator.dart';
import '../../components/generation_loading_overlay.dart';
import '../../utils/content_moderator_helper.dart';
import '../../components/gem_indicator.dart';

class FaceRestoreScreen extends StatefulWidget {
  const FaceRestoreScreen({super.key});

  @override
  State<FaceRestoreScreen> createState() => _FaceRestoreScreenState();
}

class _FaceRestoreScreenState extends State<FaceRestoreScreen> {
  File? _selectedImage;
  bool _isProcessing = false;
  String _statusMessage = "";
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
  double? _progress;
  bool _isQueued = false;
  int? _queuePosition;
  int? _queueTotal;
  String? _queueInfo;

  // Face Restore Options
  double _denoise = 0.5;
  int _detailedSteps = 20;
  String _selectedCheckpoint =
      "wildcardxXLTURBO_wildcardxXLTURBOV10.safetensors";
  String _positivePrompt = "";
  String _negativePrompt = "";
  double _guideSize = 256.0;
  double _maxSize = 768.0;
  int _seed = math.Random().nextInt(1000000000);
  double _cfg = 8.0;
  bool _isConfigExpanded = true;

  final Map<String, String> _checkpointFriendlyNames = {
    "BSSEquinoxILSemi_v30.safetensors": "Animal Equinox",
    "miaomiaoPixel_vPred11.safetensors": "Anime Ah Pixel",
    "akashicpulse_v41.safetensors": "Anime Akashic Pulse",
    "ramthrustsNSFWPINK_alchemyMix176.safetensors": "Anime Alchemy Mix",
    "astreapixieRadiance_v16.safetensors": "Anime Astrea Pixie Radiance",
    "catCarrier_v70.safetensors": "Anime Cat Carrier",
    "animeCelestialMagic_v30.safetensors": "Anime Celestial Magic",
    "animeChangefulXL_v10ReleasedCandidate.safetensors":
        "Anime Change Full Perform",
    "animecollection_v420.safetensors": "Anime Collection",
    "corepomMIX2_sakuraMochi.safetensors": "Anime Corepom Mix 2",
    "dollamor_v10.safetensors": "Anime Doll Doll",
    "flatAnimix_v20.safetensors": "Anime Flat Animix",
    "floraEclipse_v10.safetensors": "Anime Flora Eclipse",
    "hotaruBlend_vPredV20.safetensors": "Anime Hotaru Blend",
    "hyperpixel_v10.safetensors": "Anime Hyper Pixel",
    "lakeLakeSeriesOfModels_renoLakeK1S.safetensors": "Anime Lake Reno Series",
    "lizmix_version18.safetensors": "Anime Lizmix",
    "lilithsLullaby_v10.safetensors": "Anime Lulaby",
    "endlustriaLUMICA_v2.safetensors": "Anime Lumica Illusion",
    "meinamix_meinaV11.safetensors": "Anime Main Mix",
    "mritualIllustrious_v20.safetensors": "Anime Mritual Ilustrious",
    "novaAnimeXL_ilV125.safetensors": "Anime Nova",
    "nova3DCGXL_ilV70.safetensors": "Anime Nova 3D",
    "novaFurryXL_ilV120.safetensors": "Anime Nova Furry",
    "novaMatureXL_v35.safetensors": "Anime Nova Mature",
    "novaOrangeXL_reV30.safetensors": "Anime Nova Orange",
    "novaRetroXL_v20.safetensors": "Anime Nova Retro",
    "novaUnrealXL_v100.safetensors": "Anime Nova Unreal",
    "scyraxPastelCore_v10.safetensors": "Anime Pastel Core",
    "perfectdeliberate_v20A.safetensors": "Anime Perfect Deliberate",
    "wildcardxXLTURBO_wildcardxXLTURBOV10.safetensors": "Anime Premium Ultra",
    "PVCStyleModelMovable_epsIll11.safetensors": "Anime PVC Moveable",
    "AnimeRealPantheon_k1ssBakedvae.safetensors": "Anime Real Pantheon",
    "redLilyIllu_v10.safetensors": "Anime Red Lily",
    "silenceMix_v7.safetensors": "Anime Silence Mix",
    "softMixKR_v23.safetensors": "Anime Soft Mix",
    "3dStock3dAnimeStyle_v30.safetensors": "Anime Stock Style",
    "tinyNovaMerge_v25.safetensors": "Anime Tiny Merge",
    "trattoNero_vitta.safetensors": "Anime Tratto Nero",
    "dvine_v60.safetensors": "Anime Well Vell",
    "xeHentaiAnimePDXL_02.safetensors": "Anime Xe",
    "asianBlendIllustrious_v10.safetensors": "General Asia Blend Illustrious",
    "asianBlendPDXLPony_v1.safetensors": "General Asia Blend Pony",
    "margaretAsianWomanPony_v10.safetensors": "General Asia Margaret Pony",
    "ponyAsianRealismAlpha_v05.safetensors": "General Asia Realism Alpha",
    "iniverseMixSFWNSFW_realXLV1.safetensors": "General Iniverse Mix",
    "intorealismUltra_v10.safetensors": "General Intorealism Ultra",
    "novaRealityXL_ilV901.safetensors": "General Nova Reality",
    "realcosplay_realchenkinv10.safetensors": "General Real Cosplay",
    "ultra_v11.safetensors": "General Ultra",
  };

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final File file = File(image.path);
        final int fileSize = await file.length();

        if (fileSize > 2 * 1024 * 1024) {
          setState(() {
            _errorMessage =
                "File too large. Maximum 2MB (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB)";
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = file;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Error picking image: $e");
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    // Preload Ad
    AdHelper.preloadInterstitialAd();

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = "Uploading image...";
      _progress = null;
      _isQueued = false;
    });

    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final userId = authRepo.currentUser?.uid;

      if (userId != null) {
        final genRepo = Provider.of<GenerationRepository>(
          context,
          listen: false,
        );
        final limit = await genRepo.getGenerationLimit(userId);

        if (!limit.moreEnabled) {
          final blockedPositive = ContentModerator.checkPrompt(_positivePrompt);
          final blockedNegative = ContentModerator.checkPrompt(_negativePrompt);
          final allBlocked = {...blockedPositive, ...blockedNegative}.toList();

          if (allBlocked.isNotEmpty) {
            if (mounted) {
              setState(() => _isProcessing = false);
              ContentModeratorHelper.showModerationWarning(context, allBlocked);
            }
            return;
          }
        }
      }

      if (!mounted) return;

      final repository = context.read<DrawAiRepository>();
      final fileName = _selectedImage!.path.split('/').last;
      final imageBytes = await _selectedImage!.readAsBytes();

      final options = {
        "denoise": _denoise.toString(),
        "steps": _detailedSteps.toString(),
        "ckpt_name": _selectedCheckpoint,
        "positive_prompt": _positivePrompt,
        "negative_prompt": _negativePrompt,
        "guide_size": _guideSize.toInt().toString(),
        "max_size": _maxSize.toInt().toString(),
        "seed": _seed.toString(),
        "cfg": _cfg.toString(),
      };

      await repository.executeToolAndWait(
        toolType: 'face_restore',
        imageBytes: imageBytes,
        filename: fileName,
        options: options,
        onStatusUpdate: (message, status) {
          if (mounted) {
            setState(() {
              _statusMessage = message;
              if (status != null) {
                _progress = (status.progress ?? 0) / 100.0;
                _isQueued = status.status == "queued";
                _queuePosition = status.queuePosition;
                _queueTotal = status.queueTotal;
                _queueInfo = status.queueInfo;
              }
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _statusMessage = "Success!";
          _progress = 1.0;
        });

        // Delay to show success state briefly
        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          _handlePostProcessNavigation();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _handlePostProcessNavigation() async {
    void navigateToGallery() {
      if (mounted) {
        Provider.of<NavigationProvider>(context, listen: false).setIndex(2);
        Navigator.pop(context);
      }
    }

    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final genRepo = Provider.of<GenerationRepository>(context, listen: false);
      final userId = authRepo.currentUser?.uid;

      if (userId != null) {
        final limit = await genRepo.getGenerationLimit(userId);
        final isPremium =
            limit.isPremium == true ||
            limit.subscriptionType == 'basic' ||
            limit.subscriptionType == 'pro';

        if (!isPremium) {
          AdHelper.showAdAfterSave(onCompleted: navigateToGallery);
        } else {
          navigateToGallery();
        }
      } else {
        navigateToGallery();
      }
    } catch (e) {
      navigateToGallery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, theme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildUploadCard(theme),
                        if (_errorMessage != null) _buildErrorCard(theme),
                        const SizedBox(height: 16),
                        _buildConfigCard(theme),
                        const SizedBox(height: 24),
                        if (!_isProcessing && _selectedImage != null)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _processImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                "Restore Face",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            GenerationLoadingOverlay(
              isGenerating: _isProcessing,
              statusMessage: _statusMessage,
              progress: _progress,
              isQueued: _isQueued,
              queuePosition: _queuePosition,
              queueTotal: _queueTotal,
              queueInfo: _queueInfo,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Face Restore",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "AI Face Enhancement",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Spacer(),
          StreamBuilder<int>(
            stream: context.read<DrawAiRepository>().getGemCountStream(
              context.read<AuthRepository>().currentUser?.uid ?? "",
            ),
            builder: (context, snapshot) {
              return GemIndicator(gemCount: snapshot.data ?? 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(ThemeData theme) {
    return GestureDetector(
      onTap: _isProcessing ? null : _pickImage,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        elevation: 0,
        child: Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: _selectedImage != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImage!, fit: BoxFit.contain),
                    if (!_isProcessing)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: CircleAvatar(
                          backgroundColor: theme.colorScheme.surface.withValues(
                            alpha: 0.8,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.face,
                        size: 30,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Upload Photo",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Max 2MB",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildConfigCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isConfigExpanded = !_isConfigExpanded),
            leading: Icon(
              Icons.settings_suggest,
              color: theme.colorScheme.primary,
            ),
            title: const Text(
              "Enhancement Settings",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Icon(
              _isConfigExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
          ),
          if (_isConfigExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI Model",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedCheckpoint,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    items: _checkpointFriendlyNames.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCheckpoint = val!),
                  ),
                  const SizedBox(height: 16),
                  _buildSliderRow(
                    "Denoise Strength",
                    _denoise,
                    0.0,
                    1.0,
                    (v) => setState(() => _denoise = v),
                    isFloat: true,
                  ),
                  _buildSliderRow(
                    "Detailed Steps",
                    _detailedSteps.toDouble(),
                    10,
                    50,
                    (v) => setState(() => _detailedSteps = v.toInt()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Positive Prompt (Optional)",
                      hintText: "e.g. realistic, detailed face, smile",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) => _positivePrompt = v,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Negative Prompt (Optional)",
                      hintText: "e.g. blurry, deformed, low quality",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) => _negativePrompt = v,
                  ),
                  const SizedBox(height: 16),
                  _buildSliderRow(
                    "Guide Size",
                    _guideSize,
                    128,
                    512,
                    (v) => setState(() => _guideSize = v),
                  ),
                  _buildSliderRow(
                    "Max Size",
                    _maxSize,
                    256,
                    1024,
                    (v) => setState(() => _maxSize = v),
                  ),
                  _buildSliderRow(
                    "CFG Scale",
                    _cfg,
                    1.0,
                    20.0,
                    (v) => setState(() => _cfg = v),
                    isFloat: true,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Seed", style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      SizedBox(
                        width: 150,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true),
                          controller: TextEditingController(
                            text: _seed.toString(),
                          ),
                          onChanged: (v) => _seed = int.tryParse(v) ?? _seed,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => setState(
                          () => _seed = math.Random().nextInt(1000000000),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool isFloat = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              isFloat ? value.toStringAsFixed(1) : value.toInt().toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.warning, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
