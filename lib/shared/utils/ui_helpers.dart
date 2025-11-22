import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/feedback_service.dart';

class UIHelpers {
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        duration: duration,
      ),
    );
  }

  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: duration,
      ),
    );
  }

  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        duration: duration,
      ),
    );
  }

  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: duration,
      ),
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context,
    String message, {
    String title = 'Confirm',
    String confirmText = 'Yes',
    String cancelText = 'No',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> showInfoDialog(
    BuildContext context,
    String message, {
    String title = 'Information',
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context,
    String message, {
    String title = 'Error',
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message ?? 'Loading...'),
            ],
          ),
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static Future<T?> showCustomBottomSheet<T>(
    BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      backgroundColor: backgroundColor ?? const Color(0xFF1D0B3C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => child,
    );
  }

  static void navigateToMovie(
    BuildContext context,
    int movieId, {
    String? heroTag,
  }) {
    FeedbackService.playSound(context);
    FeedbackService.lightImpact(context);
    if (heroTag != null) {
      context.push('/movie/$movieId', extra: {'heroTag': heroTag});
    } else {
      context.push('/movie/$movieId');
    }
  }

  static void navigateToActor(BuildContext context, int actorId) {
    FeedbackService.playSound(context);
    FeedbackService.lightImpact(context);
    context.push('/actor/$actorId');
  }

  static void navigateToSeeAll(
    BuildContext context, {
    required String title,
    List<dynamic>? movies,
    List<dynamic>? cast,
  }) {
    FeedbackService.playSound(context);
    FeedbackService.lightImpact(context);
    context.push('/see-all', extra: {
      'title': title,
      if (movies != null) 'movies': movies,
      if (cast != null) 'cast': cast,
    });
  }

  static void navigateToLocalPlayer(
    BuildContext context, {
    required String filePath,
    required String title,
  }) {
    FeedbackService.playSound(context);
    FeedbackService.lightImpact(context);
    context.push('/play-local/:id', extra: {
      'filePath': filePath,
      'title': title,
    });
  }

  static void goBack(BuildContext context) {
    FeedbackService.playSound(context);
    FeedbackService.lightImpact(context);
    context.pop();
  }

  static String getProxiedImageUrl(String originalUrl) {
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return 'https://images.weserv.nl/?url=$encodedUrl&w=800&q=85';
  }
}
