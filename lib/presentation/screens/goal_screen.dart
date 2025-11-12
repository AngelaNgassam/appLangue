import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/goal.dart';
import 'referral_source_screen.dart';

class GoalScreen extends StatefulWidget {
  final String userId;
  final String languageId;
  const GoalScreen({super.key, required this.userId, required this.languageId});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final ApiService api = ApiService();
  List<Goal> goals = [];
  String? selectedGoalId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    final data = await api.fetchGoals();
    setState(() {
      goals = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose your goal")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...goals.map((goal) => RadioListTile(
                      title: Text(goal.label),
                      value: goal.id,
                      groupValue: selectedGoalId,
                      onChanged: (value) {
                        setState(() => selectedGoalId = value.toString());
                      },
                    )),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: selectedGoalId == null
                      ? null
                      : () async {
                          await api.updateUserPreference(
                            widget.userId,
                            goalId: selectedGoalId!,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReferralSourceScreen(
                                userId: widget.userId,
                                languageId: widget.languageId,
                                goalId: selectedGoalId!,
                              ),
                            ),
                          );
                        },
                  child: const Text("Next"),
                ),
              ],
            ),
    );
  }
}
