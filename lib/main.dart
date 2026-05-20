import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const CurlRunnerApp());

class CurlRunnerApp extends StatelessWidget {
  const CurlRunnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curl Runner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFE94560)),
      ),
      home: const CurlRunnerHome(),
    );
  }
}

class CurlRunnerHome extends StatefulWidget {
  const CurlRunnerHome({super.key});

  @override
  State<CurlRunnerHome> createState() => _CurlRunnerHomeState();
}

class _CurlRunnerHomeState extends State<CurlRunnerHome> {
  final _urlController = TextEditingController(text: 'https://jsonplaceholder.typicode.com/posts/1');
  final _bodyController = TextEditingController();
  String _method = 'GET';
  List<MapEntry<TextEditingController, TextEditingController>> _headers = [
    MapEntry(TextEditingController(), TextEditingController()),
  ];
  String _responseStatus = '';
  String _responseHeaders = '';
  String _responseBody = '';
  String _responseTime = '';
  bool _loading = false;

  static const _methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'];

  void _addHeader() {
    setState(() {
      _headers.add(MapEntry(TextEditingController(), TextEditingController()));
    });
  }

  void _removeHeader(int index) {
    setState(() {
      _headers.removeAt(index);
    });
  }

  Future<void> _sendRequest() async {
    if (_urlController.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final stopwatch = Stopwatch()..start();

    try {
      final headers = <String, String>{};
      for (final h in _headers) {
        if (h.key.text.trim().isNotEmpty) {
          headers[h.key.text.trim()] = h.value.text;
        }
      }

      if (['POST', 'PUT', 'PATCH'].contains(_method) &&
          _bodyController.text.trim().isNotEmpty &&
          !headers.containsKey('Content-Type') &&
          !headers.containsKey('content-type')) {
        headers['Content-Type'] = 'application/json';
      }

      final uri = Uri.parse(_urlController.text.trim());
      final body = ['POST', 'PUT', 'PATCH'].contains(_method) ? _bodyController.text.trim() : null;

      late http.Response res;
      switch (_method) {
        case 'GET':
          res = await http.get(uri, headers: headers);
          break;
        case 'POST':
          res = await http.post(uri, headers: headers, body: body);
          break;
        case 'PUT':
          res = await http.put(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: headers);
          break;
        case 'PATCH':
          res = await http.patch(uri, headers: headers, body: body);
          break;
        case 'HEAD':
          res = await http.head(uri, headers: headers);
          break;
        default:
          res = await http.get(uri, headers: headers);
      }

      stopwatch.stop();

      final respHeaders = StringBuffer();
      res.headers.forEach((k, v) => respHeaders.writeln('$k: $v'));

      String prettyBody;
      try {
        prettyBody = const JsonEncoder.withIndent('  ').convert(jsonDecode(res.body));
      } catch (_) {
        prettyBody = res.body;
      }

      setState(() {
        _responseStatus = '${res.statusCode}';
        _responseHeaders = respHeaders.toString().trim();
        _responseBody = prettyBody;
        _responseTime = '${stopwatch.elapsedMilliseconds}ms';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _responseStatus = 'Error';
        _responseBody = e.toString();
        _responseTime = '${stopwatch.elapsedMilliseconds}ms';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBody = ['POST', 'PUT', 'PATCH'].contains(_method);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('⚡ Curl Runner', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE94560))),
              const SizedBox(height: 16),

              // Method selector
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _methods.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final m = _methods[i];
                    final active = m == _method;
                    return ChoiceChip(
                      label: Text(m),
                      selected: active,
                      onSelected: (_) => setState(() => _method = m),
                      selectedColor: const Color(0xFFE94560),
                      backgroundColor: const Color(0xFF16213E),
                      side: const BorderSide(color: Color(0xFF0F3460)),
                      labelStyle: TextStyle(color: active ? Colors.white : Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // URL
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  hintText: 'https://api.example.com/endpoint',
                  filled: true, fillColor: Color(0xFF16213E),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF0F3460))),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),

              // Headers
              const Text('Headers', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              ..._headers.asMap().entries.map((entry) {
                final i = entry.key;
                final h = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(child: TextField(
                        controller: h.key, decoration: const InputDecoration(hintText: 'Key', filled: true,
                          fillColor: Color(0xFF16213E), isDense: true, border: OutlineInputBorder()),
                      )),
                      const SizedBox(width: 6),
                      Expanded(child: TextField(
                        controller: h.value, decoration: const InputDecoration(hintText: 'Value', filled: true,
                          fillColor: Color(0xFF16213E), isDense: true, border: OutlineInputBorder()),
                      )),
                      IconButton(icon: const Icon(Icons.close, color: Color(0xFFE94560)), onPressed: () => _removeHeader(i)),
                    ],
                  ),
                );
              }),
              Align(alignment: Alignment.centerLeft,
                child: TextButton(onPressed: _addHeader, child: const Text('+ Add Header', style: TextStyle(color: Color(0xFF0F3460), fontWeight: FontWeight.w600)))),
              const SizedBox(height: 4),

              // Body
              if (showBody) ...[
                const Text('Body', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                TextField(
                  controller: _bodyController, maxLines: 4,
                  decoration: const InputDecoration(hintText: '{"key": "value"}', filled: true,
                    fillColor: Color(0xFF16213E), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
              ],

              // Send
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('▶ Send Request', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),

              // Response
              if (_responseStatus.isNotEmpty) ...[
                Text('Response — $_responseStatus  ($_responseTime)',
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (_responseHeaders.isNotEmpty) ...[
                  const Text('Headers', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8), border: Border.all(color: Color(0xFF0F3460))),
                    child: SingleChildScrollView(child: Text(_responseHeaders, style: const TextStyle(color: Color(0xFF58A6FF), fontFamily: 'monospace', fontSize: 12))),
                  ),
                  const SizedBox(height: 8),
                ],
                const Text('Body', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8), border: Border.all(color: Color(0xFF0F3460))),
                  child: SingleChildScrollView(child: Text(_responseBody, style: const TextStyle(color: Color(0xFF58A6FF), fontFamily: 'monospace', fontSize: 12))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
