import 'package:flutter/material.dart';

class PrintStatsRow extends StatelessWidget {
  final double progressPercentage;
  final int printTimeElapsed;
  final int printTimeRemaining;

  const PrintStatsRow({
    super.key,
    required this.progressPercentage,
    required this.printTimeElapsed,
    required this.printTimeRemaining,
  });

  // Format seconds into HH:MM:SS
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
              'Progress',
              '${progressPercentage.toStringAsFixed(1)}%',
              Icons.percent
          ),
          _buildStatColumn(
              'Time Elapsed',
              _formatDuration(printTimeElapsed),
              Icons.timer
          ),
          _buildStatColumn(
              'Time Remaining',
              _formatDuration(printTimeRemaining),
              Icons.hourglass_bottom
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}