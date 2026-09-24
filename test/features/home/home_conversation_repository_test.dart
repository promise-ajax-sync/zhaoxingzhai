import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/features/home/data/home_conversation_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('首页会话可以保存、恢复和追加消息', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = HomeConversationRepository();
    final first = await repository.append(text: '我想了解近期工作');
    await repository.append(
      text: '请重点说明行动建议',
      conversationId: first.id,
      toolId: 'meihua',
    );

    final restored = HomeConversationRepository();
    await restored.ensureLoaded();
    expect(restored.conversations, hasLength(1));
    expect(restored.conversations.single.messages, hasLength(2));
    expect(restored.conversations.single.messages.last.toolId, 'meihua');
  });

  test('首页会话会持久化云端版本号', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      HomeConversationRepository.storageKey,
      '[{"id":"home:version","updatedAt":"2026-09-24T00:00:00.000Z",'
      '"cloudVersion":3,"messages":[]}]',
    );

    final repository = HomeConversationRepository();
    await repository.ensureLoaded();

    expect(repository.conversations.single.cloudVersion, 3);
  });

  test('首页会话支持删除和清空', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = HomeConversationRepository();
    final first = await repository.append(text: '问题一');
    await repository.append(text: '问题二');
    await repository.delete(first.id);
    expect(repository.conversations, hasLength(1));
    await repository.clear();
    expect(repository.conversations, isEmpty);
  });
}
