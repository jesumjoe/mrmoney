import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mrmoney/theme/neo_style.dart';

class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  String _logs = "Loading logs...";

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sms_debug.log');
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          _logs = content.isEmpty ? "Log file is empty." : content;
        });
      } else {
        setState(() {
          _logs = "Log file not found at ${file.path}";
        });
      }
    } catch (e) {
      setState(() {
        _logs = "Error reading logs: $e";
      });
    }
  }

  Future<void> _clearLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sms_debug.log');
      if (await file.exists()) {
        await file.writeAsString(''); // Clear content
        _loadLogs();
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: NeoCard(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            _logs,
            style: GoogleFonts.robotoMono(fontSize: 12),
          ),
        ),
      ),
    );
  }
}
