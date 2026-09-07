import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'spiritual_image_config.dart';
import 'spiritual_image_service.dart';

class SpiritualImageScreen extends StatefulWidget {
  const SpiritualImageScreen({super.key});

  @override
  State<SpiritualImageScreen> createState() => _SpiritualImageScreenState();
}

class _SpiritualImageScreenState extends State<SpiritualImageScreen> {
  final _controller = TextEditingController();
  final _service = SpiritualImageService();
  bool _loading = false;
  String? _error;
  Uint8List? _imageBytes;
  String _lastPrompt = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate({bool retry = false}) async {
    if (_loading) return;
    final prompt = (retry ? _lastPrompt : _controller.text).trim();
    if (prompt.isEmpty) {
      setState(() {
        _error = 'Խնդրում ենք գրել նկարի նկարագրությունը։';
        _imageBytes = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _lastPrompt = prompt;
      if (!retry) _imageBytes = null;
    });

    try {
      final result = await _service.generate(prompt: prompt);
      if (!mounted) return;
      setState(() {
        _imageBytes = result.bytes;
        _error = null;
      });
    } on SpiritualImageException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Կապի սխալ։ Խնդրում ենք ստուգել ինտերնետը և նորից փորձել։';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ստեղծել հոգևոր նկար'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!SpiritualImageConfig.isConfigured)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.orange.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Cloudflare Worker-ը դեռ միացված չէ։ Deploy-ից հետո հավելվածը կառուցեք SPIRITUAL_IMAGE_URL-ով։',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 6,
                enabled: !_loading,
                cursorColor: Colors.black,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  hintText:
                      'Օրինակ՝ Հիսուսը Գալիլեայի ծովի ափին մայրամուտին',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : () => _generate(),
                child: const Text('Գեներացնել'),
              ),
              if (_loading) ...[
                const SizedBox(height: 28),
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(height: 12),
                Text(
                  'Նկարը ստեղծվում է…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.grey[800],
                  ),
                ),
              ],
              if (_error != null && !_loading) ...[
                const SizedBox(height: 20),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.orange[200] : Colors.red[800],
                  ),
                ),
              ],
              if (_imageBytes != null && !_loading) ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                ),
              ],
              if (!_loading &&
                  _lastPrompt.isNotEmpty &&
                  (_imageBytes != null || _error != null)) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _generate(retry: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.grey[800],
                    side: BorderSide(color: Colors.grey[800]!),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Կրկին փորձել'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
