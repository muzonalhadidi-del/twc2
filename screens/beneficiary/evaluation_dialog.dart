import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> showEvaluationDialog(BuildContext context, String requestId, String volunteerId) async {
  double _rating = 5.0;
  TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Evaluate Volunteer', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How was your experience?'),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Leave a comment (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () async {
                  setState(() => _isSubmitting = true);
                  try {
                    await FirebaseFirestore.instance.collection('evaluations').add({
                      'requestId': requestId,
                      'volunteerId': volunteerId,
                      'rating': _rating,
                      'comment': _commentController.text.trim(),
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    // Update request to show it has been evaluated
                    await FirebaseFirestore.instance.collection('beneficiaries_request').doc(requestId).update({
                      'isEvaluated': true,
                    });

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you for your feedback!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    setState(() => _isSubmitting = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9EA4FF)),
                child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      );
    }
  );
}
