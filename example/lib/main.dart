import 'package:flutter/material.dart';
import 'package:windows_screen_guard/windows_screen_guard.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WindowsScreenGuard Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _protected = false;
  bool _printScreenBlocked = false;
  ScreenGuardResult? _lastResult;

  void _toggleProtection() {
    final result = _protected
        ? WindowsScreenGuard.unprotect()
        : WindowsScreenGuard.protect();
    setState(() {
      _protected = !_protected && result.success;
      _lastResult = result;
    });
  }

  void _togglePrintScreen() {
    if (_printScreenBlocked) {
      WindowsScreenGuard.unblockPrintScreen();
    } else {
      WindowsScreenGuard.blockPrintScreen();
    }
    setState(() {
      _printScreenBlocked = WindowsScreenGuard.isPrintScreenBlocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WindowsScreenGuard Example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _protected ? Icons.shield : Icons.shield_outlined,
              size: 80,
              color: _protected ? Colors.greenAccent : Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              _protected ? 'Screen capture BLOCKED' : 'Screen capture ALLOWED',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_lastResult != null && !_lastResult!.success)
              Text(
                'Error code: ${_lastResult!.errorCode}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _toggleProtection,
              icon: Icon(_protected ? Icons.lock_open : Icons.lock),
              label: Text(_protected ? 'Remove Protection' : 'Enable Protection'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _togglePrintScreen,
              icon: Icon(_printScreenBlocked
                  ? Icons.keyboard_hide
                  : Icons.keyboard),
              label: Text(_printScreenBlocked
                  ? 'Unblock PrintScreen Key'
                  : 'Block PrintScreen Key'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Try taking a screenshot while protection is enabled.\n'
              'Your window will appear black in the capture.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
