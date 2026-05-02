import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/signal_provider.dart';
import '../models/signal_model.dart';
import '../widgets/signal_card.dart';

class SavedSignalsScreen extends ConsumerStatefulWidget {
  const SavedSignalsScreen({super.key});

  @override
  ConsumerState<SavedSignalsScreen> createState() => _SavedSignalsScreenState();
}

class _SavedSignalsScreenState extends ConsumerState<SavedSignalsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedSignals = ref.watch(savedSignalsProvider);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0F14),
        appBar: AppBar(
          backgroundColor: const Color(0xFF161A22),
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text(
            'Saved Signals',
            style: TextStyle(
              color: Color(0xFFEFF2F7),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFEFF2F7)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (savedSignals.isNotEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFFEFF2F7)),
                color: const Color(0xFF1E2330),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearAllDialog();
                  } else if (value == 'export_json') {
                    _exportToJson();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export_json',
                    child: Row(
                      children: [
                        Icon(Icons.download, color: Color(0xFF4F8EF7), size: 20),
                        SizedBox(width: 12),
                        Text('Export JSON', style: TextStyle(color: Color(0xFFEFF2F7))),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 12),
                        Text('Clear All', style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: savedSignals.isEmpty 
                ? _buildEmptyState()
                : _buildSignalsList(savedSignals),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.bookmark_outline_rounded,
              color: Colors.purple,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Saved Signals',
            style: TextStyle(
              color: Color(0xFFEFF2F7),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save signals to see them here',
            style: TextStyle(
              color: const Color(0xFF8B93A7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF4F8EF7), Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Browse Signals',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalsList(List<Signal> signals) {
    return Column(
      children: [
        // Header with count
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161A22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF252B38)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.bookmark_rounded,
                color: Colors.purple,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '${signals.length} Saved Signal${signals.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFFEFF2F7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Tap bookmark to remove',
                style: TextStyle(
                  color: const Color(0xFF8B93A7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Signals list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemCount: signals.length,
            itemBuilder: (context, index) {
              return SignalCard(signal: signals[index]);
            },
          ),
        ),
      ],
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161A22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear All Saved Signals?',
          style: TextStyle(color: Color(0xFFEFF2F7)),
        ),
        content: const Text(
          'This will remove all saved signals from your device. This action cannot be undone.',
          style: TextStyle(color: Color(0xFF8B93A7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8B93A7)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(savedSignalsProvider.notifier).clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All saved signals cleared'),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  void _exportToJson() {
    final savedSignals = ref.read(savedSignalsProvider);
    if (savedSignals.isEmpty) return;

    final jsonData = savedSignals.map((signal) => signal.toJson()).toList();
    final jsonString = '[\n${jsonData.map((json) => '  ${_formatJson(json)}').join(',\n')}\n]';
    
    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON data copied to clipboard!'),
        backgroundColor: Color(0xFF22C55E),
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    return json.entries
        .map((entry) => '"${entry.key}": ${_formatValue(entry.value)}')
        .join(',\n    ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is num || value is bool) return value.toString();
    if (value is List) return '[${value.map((e) => _formatValue(e)).join(', ')}]';
    if (value is Map) {
      return '{${value.entries.map((e) => '"${e.key}": ${_formatValue(e.value)}').join(', ')}}';
    }
    return '"$value"';
  }
}
