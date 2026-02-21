import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/generation_model.dart';
import '../../components/gem_indicator.dart';

class MakeBackgroundAdvancedScreen extends StatefulWidget {
  const MakeBackgroundAdvancedScreen({super.key});

  @override
  State<MakeBackgroundAdvancedScreen> createState() =>
      _MakeBackgroundAdvancedScreenState();
}

class _MakeBackgroundAdvancedScreenState
    extends State<MakeBackgroundAdvancedScreen> {
  final TextEditingController _positivePromptController =
      TextEditingController();
  final TextEditingController _negativePromptController =
      TextEditingController();

  String _selectedSize = "1280x720";
  int _seed = math.Random().nextInt(1000000000);
  double _cfgScale = 8.0;
  int _steps = 30;
  String _selectedCheckpoint = "BSSEquinoxILSemi_v30.safetensors";
  bool _isGenerating = false;
  String _statusMessage = "";
  String? _errorMessage;
  bool _isConfigExpanded = true;

  final List<Map<String, String>> _sizeOptions = [
    {"id": "1024x1024", "label": "Square (1:1)"},
    {"id": "1280x720", "label": "Landscape (16:9)"},
    {"id": "720x1280", "label": "Portrait (9:16)"},
  ];

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

  Future<void> _generateBackground() async {
    if (_positivePromptController.text.isEmpty) {
      setState(() => _errorMessage = "Please enter a positive prompt");
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _statusMessage = "Generating...";
    });

    try {
      final repository = context.read<DrawAiRepository>();
      final options = {
        "positive_prompt": _positivePromptController.text,
        "negative_prompt": _negativePromptController.text,
        "width": _selectedSize.split('x')[0],
        "height": _selectedSize.split('x')[1],
        "seed": _seed.toString(),
        "cfg_scale": _cfgScale.toString(),
        "steps": _steps.toString(),
        "ckpt_name": _selectedCheckpoint,
      };

      final result = await repository.executeToolAndWait(
        toolType: 'make_background_advanced',
        options: options,
        onStatusUpdate: (message, status) {
          setState(() => _statusMessage = message);
        },
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = "";
        });
        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showSuccessDialog(TaskStatusResponse result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: const Text(
          "Advanced background generated! Check your gallery for the masterpiece.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildPreviewCard(theme),
                    const SizedBox(height: 16),
                    _buildConfigCard(theme),
                    const SizedBox(height: 24),
                    if (_isGenerating) _buildProcessingCard(theme),
                    if (!_isGenerating)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _generateBackground,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            "Generate Advanced Background",
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Advanced Background",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Precision Control • Cinematic Scenes",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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

  Widget _buildPreviewCard(ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Image.network(
        "https://drawai-api.drawai.site/workflow-image/make_background_advanced_v1",
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.auto_awesome)),
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
            leading: Icon(Icons.tune, color: theme.colorScheme.primary),
            title: const Text(
              "Advanced Configuration",
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
                  TextField(
                    controller: _positivePromptController,
                    decoration: InputDecoration(
                      labelText: "Detailed Positive Prompt",
                      hintText:
                          "e.g. masterpiece, high resolution, anime style garden...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _negativePromptController,
                    decoration: InputDecoration(
                      labelText: "Negative Prompt",
                      hintText: "e.g. low quality, blurry, text, logo...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Canvas Size",
                              style: TextStyle(fontSize: 12),
                            ),
                            DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedSize,
                              items: _sizeOptions.map((opt) {
                                return DropdownMenuItem(
                                  value: opt["id"],
                                  child: Text(opt["label"]!),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedSize = val!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSliderColumn(
                          "CFG Scale",
                          _cfgScale,
                          1.0,
                          20.0,
                          (v) => setState(() => _cfgScale = v),
                          isFloat: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSliderColumn(
                    "Generation Steps",
                    _steps.toDouble(),
                    10,
                    60,
                    (v) => setState(() => _steps = v.toInt()),
                  ),
                  const SizedBox(height: 16),
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
                  if (_errorMessage != null) _buildErrorText(theme),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliderColumn(
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

  Widget _buildErrorText(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        _errorMessage!,
        style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
      ),
    );
  }

  Widget _buildProcessingCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(
              _statusMessage.isEmpty ? "Generating..." : _statusMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
