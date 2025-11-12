import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/referral_source.dart';
import 'success_screen.dart';

class ReferralSourceScreen extends StatefulWidget {
  final String userId;
  final String languageId;
  final String goalId;
  const ReferralSourceScreen({
    super.key,
    required this.userId,
    required this.languageId,
    required this.goalId,
  });

  @override
  State<ReferralSourceScreen> createState() => _ReferralSourceScreenState();
}

class _ReferralSourceScreenState extends State<ReferralSourceScreen> {
  final ApiService api = ApiService();
  List<ReferralSource> sources = [];
  String? selectedSourceId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSources();
  }

  Future<void> loadSources() async {
    final res = await api.fetchReferralSources();
    setState(() {
      sources = res;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Where did you hear about us?")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...sources.map((src) => RadioListTile(
                      title: Text(src.label),
                      value: src.id,
                      groupValue: selectedSourceId,
                      onChanged: (value) {
                        setState(() => selectedSourceId = value.toString());
                      },
                    )),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: selectedSourceId == null
                      ? null
                      : () async {
                          await api.updateUserPreference(
                            widget.userId,
                            sourceId: selectedSourceId!,
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SuccessScreen(),
                            ),
                          );
                        },
                  child: const Text("Finish"),
                ),
              ],
            ),
    );
  }
}
