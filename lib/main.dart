import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const JnuScheduleApp());
}

class JnuScheduleApp extends StatelessWidget {
  const JnuScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JNU Schedule',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const courseUrl =
      'https://jw.jnu.edu.cn/jwapp/sys/wdkb/*default/index.do';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JNU Schedule')),
      body: Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('登录暨南大学'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LoginPage(initialUrl: courseUrl),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({required this.initialUrl, super.key});

  final String initialUrl;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const allowedHosts = <String>{
    'jw.jnu.edu.cn',
    'jwres.jnu.edu.cn',
    'auth4.jnu.edu.cn',
    'icas.jnu.edu.cn',
    'open.weixin.qq.com',
  };

  late final WebViewController _controller;
  String _status = '正在打开暨南大学官方登录页…';
  bool _coursePageLoaded = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || !allowedHosts.contains(uri.host)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _status = '正在加载官方页面…';
            });
          },
          onPageFinished: (url) {
            final uri = Uri.tryParse(url);
            final isCoursePage = uri != null &&
                uri.host == 'jw.jnu.edu.cn' &&
                uri.path.contains('/jwapp/sys/wdkb/');

            if (!mounted) return;
            setState(() {
              _coursePageLoaded = isCoursePage;
              _status = isCoursePage ? '课表页面已加载' : '等待完成官方登录…';
            });
          },
          onWebResourceError: (error) {
            if (!mounted || _coursePageLoaded) return;
            setState(() {
              _status = '页面资源加载异常，请检查网络后重试';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('暨南大学登录'),
        actions: [
          if (_coursePageLoaded)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: _coursePageLoaded
                ? Colors.green.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(_status),
              ),
            ),
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
