/// Public backend URL only. The OpenAI key stays on the server.
class SpiritualAiConfig {
  static const endpoint = String.fromEnvironment(
    'SPIRITUAL_AI_URL',
    defaultValue: 'https://ararat-bible-spiritual-ai.onrender.com',
  );
  static const gateSecret = String.fromEnvironment(
    'SPIRITUAL_AI_GATE',
    defaultValue: 'ararat-bible-local-gate',
  );

  static bool get isConfigured => endpoint.trim().isNotEmpty;
}
