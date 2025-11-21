import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/movie_detail_provider.dart';
import '../../utils/ui_helpers.dart';

class AddReviewBox extends StatefulWidget {
  final int movieId;

  const AddReviewBox({super.key, required this.movieId});

  @override
  State<AddReviewBox> createState() => _AddReviewBoxState();
}

class _AddReviewBoxState extends State<AddReviewBox> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  double _currentRating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);

      try {
        await context
            .read<MovieDetailProvider>()
            .saveUserReview(widget.movieId, _currentRating, _textController.text);

        if (mounted) {
          _textController.clear();
          setState(() => _currentRating = 5.0);
          UIHelpers.showSuccessSnackBar(context, 'Your review has been submitted!');
        }
      } catch (e) {
        if (mounted) {
          UIHelpers.showErrorSnackBar(context, 'Failed to submit review: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Rating:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                Text(
                  _currentRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _currentRating,
              min: 0.0,
              max: 10.0,
              divisions: 20,
              activeColor: Colors.pinkAccent,
              inactiveColor: Colors.white30,
              label: _currentRating.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _currentRating = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your thoughts on this movie...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please write something for your review.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReview,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}