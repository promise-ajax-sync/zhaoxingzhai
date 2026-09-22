import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/routing/divination_tool_router.dart';

void main() {
  test('明确提到六爻时进入独立六爻排盘', () {
    expect(
      DivinationToolRouter.select('请用六爻纳甲看看工作')?.tool,
      DivinationTool.liuyao,
    );
  });

  test('明确提到紫微或大限时进入紫微斗数', () {
    expect(
      DivinationToolRouter.select('请看紫微命盘的大限')?.tool,
      DivinationTool.ziwei,
    );
  });

  test('明确指定术式时优先按名称路由', () {
    expect(
      DivinationToolRouter.select('用塔罗看看这段关系')?.tool,
      DivinationTool.tarot,
    );
    expect(DivinationToolRouter.select('请用梅花易数起卦')?.confidence, 1);
  });

  test('地点问题推荐梅花易数', () {
    final selection = DivinationToolRouter.select('我会在哪里找到对象');
    expect(selection?.tool, DivinationTool.meihua);
    expect(selection?.reason, contains('地点'));
  });

  test('心理问题推荐塔罗而短期是否问题推荐小六壬', () {
    expect(DivinationToolRouter.select('对方内心怎么想')?.tool, DivinationTool.tarot);
    expect(
      DivinationToolRouter.select('这件事近期会不会成功')?.tool,
      DivinationTool.xiaoliuren,
    );
  });

  test('模糊问题不擅自选择工具', () {
    expect(DivinationToolRouter.select('最近有点迷茫'), isNull);
    expect(DivinationToolRouter.select(''), isNull);
  });
}
