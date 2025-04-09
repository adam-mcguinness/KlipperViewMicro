import 'package:flutter/material.dart';
import '../screens/control_screen.dart';
import '../screens/system_usage.dart';

class NavDrawer {
  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return const _NavDrawerContent();
      },
    );
  }
}

class _NavDrawerContent extends StatelessWidget {
  const _NavDrawerContent();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400, // you can make this dynamic too
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: 400,
            ),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/system_usage');
                  },
                  icon: const Icon(
                    Icons.dashboard,
                    size: 125,
                  ),
                  color: Theme.of(context).primaryColor,
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/control_screen');
                  },
                  icon: const Icon(
                    Icons.control_camera,
                    size: 125,
                  ),
                  color: Theme.of(context).primaryColor,
                ),
                IconButton(
                  onPressed: () {
                    // Handle Settings button press
                  },
                  icon: const Icon(
                    Icons.folder_open,
                    size: 125,
                  ),
                  color: Theme.of(context).primaryColor,
                ),
                IconButton(
                  onPressed: () {
                    // Handle Settings button press
                  },
                  icon: const Icon(
                    Icons.settings,
                    size: 125,
                  ),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}