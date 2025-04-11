import 'package:flutter/material.dart';
import 'package:klipper_view_micro/models/printer_data.dart';
import 'package:klipper_view_micro/services/api_services.dart';
import '../utils/swipe_wrapper.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({Key? key}) : super(key: key);

  @override
  _FileListScreenState createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  bool isLoading = true;
  String? errorMessage;
  FileList files = FileList(files: []);

  @override
  void initState() {
    super.initState();
    _loadFileList();
  }

  Future<void> _loadFileList() async {
    try {
      final fileList = null;
      setState(() {
        if (fileList != null) {
          files = fileList;
        } else {
          errorMessage = "No files found";
        }
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

    if (files.files.isEmpty) {
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
      itemCount: files.files.length,
      itemBuilder: (context, index) {
        final file = files.files[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          color: Colors.grey.shade800,
          child: ListTile(
            title: Text(
              file.path,
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