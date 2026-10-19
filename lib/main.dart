import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SigmaStudyApp());
}

const String baseUrl = 'https://zoo0.pages.dev';

class SigmaStudyApp extends StatelessWidget {
  const SigmaStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sigma Study',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const BatchListScreen(),
    );
  }
}

class BatchListScreen extends StatefulWidget {
  const BatchListScreen({super.key});

  @override
  State<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen> {
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  List<dynamic> _batches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBatches();
  }

  Future<void> _fetchBatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _dio.get('/api/v1/batches');
      setState(() {
        _batches = response.data['data'] ?? response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Direct API requires web session or key. You can use Web Mode below.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Sigma Study'),
        actions: [
          IconButton(
            icon: const Icon(Icons.VpnKey),
            tooltip: 'Activation Key',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: 'Open Web Platform',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FullWebViewScreen(
                    title: 'Sigma Study Web',
                    url: baseUrl,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _batches.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school, size: 64, color: Colors.deepPurpleAccent),
                        const SizedBox(height: 16),
                        const Text(
                          'Padhlo Chahe Kahi Se Selection Hoga Yahi Se!!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (_error != null)
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_circle_fill),
                          label: const Text("Let's Study (Open Platform)"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FullWebViewScreen(
                                  title: 'Sigma Study',
                                  url: baseUrl,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry API Load'),
                          onPressed: _fetchBatches,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _batches.length,
                  itemBuilder: (context, index) {
                    final batch = _batches[index];
                    final name = batch['name'] ?? batch['title'] ?? 'Batch ${index + 1}';
                    final id = (batch['id'] ?? batch['_id'] ?? '').toString();
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(name.toString()),
                        subtitle: Text('ID: $id'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubjectsScreen(batchId: id, batchName: name.toString()),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class SubjectsScreen extends StatefulWidget {
  final String batchId;
  final String batchName;
  const SubjectsScreen({super.key, required this.batchId, required this.batchName});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  List<dynamic> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final res = await _dio.get('/api/v1/batch/${widget.batchId}/subjects');
      setState(() {
        _subjects = res.data['data'] ?? res.data ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.batchName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? const Center(child: Text('Failed to load subjects. Please try again.'))
              : ListView.builder(
                  itemCount: _subjects.length,
                  itemBuilder: (context, i) {
                    final sub = _subjects[i];
                    final name = (sub['name'] ?? sub['subject'] ?? 'Subject').toString();
                    final subId = (sub['id'] ?? sub['_id'] ?? '').toString();
                    return ListTile(
                      title: Text(name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChaptersScreen(
                              batchId: widget.batchId,
                              subjectId: subId,
                              subjectName: name,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class ChaptersScreen extends StatefulWidget {
  final String batchId;
  final String subjectId;
  final String subjectName;
  const ChaptersScreen({
    super.key,
    required this.batchId,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final res = await _dio.get('/subject/${widget.subjectId}/content?type=ALL&page=1');
      setState(() {
        _items = res.data['data'] ?? res.data ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Failed to load lectures. Please try again.'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final title = (item['title'] ?? item['name'] ?? 'Lecture').toString();
                    final videoUrl = (item['streamUrl'] ?? item['url'] ?? '').toString();
                    return ListTile(
                      leading: const Icon(Icons.play_circle_outline),
                      title: Text(title),
                      onTap: () {
                        if (videoUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(title: title, streamUrl: videoUrl),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController _keyController = TextEditingController();

  Future<void> _generateKey(int server) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/generate?server=$server');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('x-api-key', _keyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get Free Keys')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Choose a server to generate key:'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _generateKey(1),
              child: const Text('Select Server 1 (Generate Free Key)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _generateKey(2),
              child: const Text('Select Server 2 (Generate Free Key)'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Paste activation key here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saveKey,
              child: const Text('Activate Key'),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final String title;
  final String streamUrl;
  const PlayerScreen({super.key, required this.title, required this.streamUrl});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _initialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
              child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }
}

class FullWebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  const FullWebViewScreen({super.key, required this.title, required this.url});

  @override
  State<FullWebViewScreen> createState() => _FullWebViewScreenState();
}

class _FullWebViewScreenState extends State<FullWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
