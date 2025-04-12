import 'package:flutter/material.dart';
import 'package:klipper_view_micro/models/printer_data.dart';
import 'package:klipper_view_micro/providers/printer_state_provider.dart';
import 'package:provider/provider.dart';
import '../utils/swipe_wrapper.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({Key? key}) : super(key: key);

  @override
  _FileListScreenState createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<PrintFile> files = [];

  @override
  void initState() {
    super.initState();
    _loadFileList();
  }

  Future<void> _loadFileList() async {
    final provider = Provider.of<PrinterStateProvider>(context, listen: false);

    try {
      final response = await provider.api.call('server.files.list', {'root': 'gcodes'});

      setState(() {
        // Convert response directly to List<PrintFile>
        files = (response as List)
            .map((file) => PrintFile.fromJson(file))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error loading files: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwipeWrapper(
      disableSwipeDown: true,
      child: Container(
        padding: const EdgeInsets.all(5),
        color: Colors.grey.shade900,
        child: RefreshIndicator(
          onRefresh: _loadFileList,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (files.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'No files found',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index]; // Get the file at the current index
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          color: Colors.grey.shade800,
          child: ListTile(
            title: Text(
              file.filename, // Use the filename property
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Size: ${file.size} bytes',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.print, color: Colors.white),
              onPressed: () {
                _showPrintDialog(file);
              },
            ),
          ),
        );
      },
    );
  }

  void _showPrintDialog(PrintFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Start Print',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Do you want to print ${file.path}?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              print(file.path);
              final provider = Provider.of<PrinterStateProvider>(context, listen: false);
              provider.api.call('printer.print.start', {'filename': file.path}).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Print job started')),
                );
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error starting print: $error')),
                );
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print job started')),
              );
            },
            child: const Text('Print', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}