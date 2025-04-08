import 'package:flutter/material.dart';
import 'package:klipper_view_micro/widgets/control_button.dart';
import '../services/api_services.dart';
import '../utils/swipe_up_home.dart';

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({Key? key}) : super(key: key);

  @override
  _ControlsScreenState createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen> {
  // Movement step size in mm
  double _stepSize = 10.0;
  final List<double> _stepSizes = [0.1, 1.0, 10.0, 50.0, 100.0];

  // Movement speed in mm/min
  double _speed = 3000.0;

  // For gesture tracking
  double? _startX;
  double? _startY;
  double? _lastX;
  double? _lastY;
  bool _isMoving = false;

  void _moveAxis(String axis, double distance) {
    final api = ApiService().api;

    // Different handling based on axis
    switch (axis) {
      case 'X':
        api.moveHeadRelative(x: distance, speed: _speed);
        break;
      case 'Y':
        api.moveHeadRelative(y: distance, speed: _speed);
        break;
      case 'Z':
      // Typically move Z at a slower speed
        api.moveHeadRelative(z: distance, speed: _speed / 2);
        break;
    }
  }

  void _homeAxis(String axis) {
    final api = ApiService().api;
    api.homeAxis(axis);
  }

  // Handle gesture start
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _startX = details.localPosition.dx;
      _startY = details.localPosition.dy;
      _lastX = _startX;
      _lastY = _startY;
      _isMoving = true;
    });
  }

  // Handle gesture updates
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isMoving || _lastX == null || _lastY == null) return;

    // Calculate delta movement
    final dx = details.localPosition.dx - _lastX!;
    final dy = details.localPosition.dy - _lastY!;

    // Scale movement relative to step size (more sensitive with smaller step sizes)
    final xMovement = dx * _stepSize / 50;
    final yMovement = -dy * _stepSize / 50; // Negative because screen Y is inverted

    // Only move if there's enough movement
    if (xMovement.abs() >= 0.1) {
      _moveAxis('X', xMovement);
    }

    if (yMovement.abs() >= 0.1) {
      _moveAxis('Y', yMovement);
    }

    // Update last position
    setState(() {
      _lastX = details.localPosition.dx;
      _lastY = details.localPosition.dy;
    });
  }

  // Handle gesture end
  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _startX = null;
      _startY = null;
      _lastX = null;
      _lastY = null;
      _isMoving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SwipeUpWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Text(
                'Printer Controls',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),

              const SizedBox(height: 20),

              // XY Control Pad
              Text(
                'XY Movement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),

              const SizedBox(height: 10),

              // Gesture Control Box - Takes more space in the center
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Stack(
                    children: [
                      // Direction indicators
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.home,
                              color: theme.colorScheme.primary,
                              size: 32,
                            ),
                          ),
                        ),
                      ),

                      // X/Y directional arrows
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Icon(
                            Icons.arrow_upward,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Icon(
                            Icons.arrow_downward,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ),

                      // Movement indicator (shows while dragging)
                      if (_isMoving && _startX != null && _startY != null)
                        CustomPaint(
                          size: const Size(250, 250),
                          painter: MovementPainter(
                            startX: _startX!,
                            startY: _startY!,
                            currentX: _lastX ?? _startX!,
                            currentY: _lastY ?? _startY!,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Home button below gesture box
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: ElevatedButton.icon(
                  onPressed: () => _homeAxis('XY'),
                  icon: const Icon(Icons.home),
                  label: const Text('Home XY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Z Control
              Text(
                'Z Movement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),

              const SizedBox(height: 10),

              // Z Controls in a vertical layout
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Z+ (Up)
                  DirectionButton(
                    icon: Icons.keyboard_arrow_up,
                    label: "Z+",
                    onPressed: () => _moveAxis('Z', _stepSize),
                  ),

                  const SizedBox(width: 20),

                  // Home Z
                  DirectionButton(
                    icon: Icons.home,
                    label: "Z",
                    onPressed: () => _homeAxis('Z'),
                  ),

                  const SizedBox(width: 20),

                  // Z- (Down)
                  DirectionButton(
                    icon: Icons.keyboard_arrow_down,
                    label: "Z-",
                    onPressed: () => _moveAxis('Z', -_stepSize),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Step size selector
              Text(
                'Step Size: ${_stepSize.toStringAsFixed(1)} mm',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(height: 10),

              // Step size selector buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _stepSizes.map((size) {
                  final isSelected = size == _stepSize;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _stepSize = size;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? theme.colorScheme.primary : theme.cardColor,
                        foregroundColor: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 36),
                      ),
                      child: Text(size.toStringAsFixed(1)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter to show movement vector
class MovementPainter extends CustomPainter {
  final double startX;
  final double startY;
  final double currentX;
  final double currentY;
  final Color color;

  MovementPainter({
    required this.startX,
    required this.startY,
    required this.currentX,
    required this.currentY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw line from start to current position
    canvas.drawLine(
      Offset(startX, startY),
      Offset(currentX, currentY),
      paint,
    );

    // Draw circle at current position
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(currentX, currentY),
      6,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(MovementPainter oldDelegate) {
    return oldDelegate.startX != startX ||
        oldDelegate.startY != startY ||
        oldDelegate.currentX != currentX ||
        oldDelegate.currentY != currentY;
  }
}