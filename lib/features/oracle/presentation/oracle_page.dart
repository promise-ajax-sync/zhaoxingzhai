import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/data/ssgw_data.dart';
import 'package:zhaoxingzhai/core/engine/ssgw/ssgw_divination.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';

class OraclePage extends StatefulWidget {
  const OraclePage({super.key, this.onResult});

  final Future<void> Function(SsgwResult result)? onResult;

  @override
  State<OraclePage> createState() => _OraclePageState();
}

class _OraclePageState extends State<OraclePage> {
  final TextEditingController _numberController = TextEditingController();
  SsgwResult? _result;
  Object? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await SsgwData.load();
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = error;
        });
      }
    }
  }

  Future<void> _accept(SsgwResult result) async {
    setState(() => _result = result);
    await widget.onResult?.call(result);
  }

  Future<void> _draw() => _accept(SsgwDivination().draw());

  Future<void> _resolve() async {
    final number = int.tryParse(_numberController.text.trim());
    if (number == null || number < 1 || number > 92) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入 1 至 92 的签号')));
      return;
    }
    await _accept(SsgwDivination.resolve(number));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return AppPageContainer(
        child: AppEmptyState(
          icon: Icons.error_outline,
          title: '灵签数据加载失败',
          subtitle: _loadError.toString(),
        ),
      );
    }

    return AppPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppPageHeading(
            title: '三山国王灵签',
            subtitle: '随机抽取或按已有签号查签，共 92 签',
          ),
          if (_result == null) _buildInput(context) else _buildResult(context),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _draw,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('随机抽签'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.space4),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.space3),
                  child: Text('或按签号查询'),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),
          TextField(
            controller: _numberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '签号（1—92）'),
          ),
          const SizedBox(height: AppTheme.space3),
          OutlinedButton(onPressed: _resolve, child: const Text('查询签文')),
        ],
      ),
    ),
  );

  Widget _buildResult(BuildContext context) {
    final result = _result!;
    final sign = result.sign;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '第${sign.number}签',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppTheme.space2),
                Text(
                  sign.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.space4),
                Text(sign.poem, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppTheme.space4),
                Text(sign.story, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        ...sign.details.entries.map(
          (entry) => Card(
            child: ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        OutlinedButton(
          onPressed: () => setState(() => _result = null),
          child: const Text('重新求签'),
        ),
      ],
    );
  }
}
