import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:klipper_view_micro/screens/system_usage.dart';

import 'control_screen.dart';


class HomeMenu extends StatelessWidget {
  const HomeMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Return HomePage directly instead of wrapping with another MaterialApp
    return const HomePage();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the theme's scaffoldBackgroundColor
      // No need to specify it here as it will use the theme from MaterialApp
      body: Center(
        child: const IconNavigation(),
      ),
    );
  }
}


class IconNavigation extends StatefulWidget {
  const IconNavigation({Key? key}) : super(key: key);

  @override
  State<IconNavigation> createState() => _IconNavigationState();
}

class _IconNavigationState extends State<IconNavigation> {
  // Icon data and names
  final List<IconData> _icons = [
    Icons.system_security_update_good,
    Icons.control_camera,
    Icons.file_copy_outlined,
    Icons.settings,
  ];

  final List<String> _names = [
    'Resources',
    'Controls',
    'Files',
    'Settings',
  ];

  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.5, // Show half of neighboring icons
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Add this method to handle navigation
  void _navigateToPage(BuildContext context, int index) {
    if (index == 0) { // Resources icon (first icon)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SystemUsage(),
        ),
      );
    } else if (index == 1) { // Controls icon
      Navigator.push(
      context,
      MaterialPageRoute(
      builder: (context) => const ControlsScreen(),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display selected icon name
            Text(
              _names[_selectedIndex],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // PageView with large square icons
            SizedBox(
              height: 250, // Tall enough for our largest squares
              child: PageView.builder(
                controller: _pageController,
                itemCount: _icons.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  bool isSelected = index == _selectedIndex;

                  return GestureDetector(
                    // Add onTap handler to navigate
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      _navigateToPage(context, index);
                    },
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isSelected ? 200 : 120, // Square width
                        height: isSelected ? 200 : 120, // Equal height for square
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Icon(
                            _icons[index],
                            size: isSelected ? 120 : 70, // Large icons
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Navigation dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _icons.length,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedIndex == index ? Colors.blue : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}