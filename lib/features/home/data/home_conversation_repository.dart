import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/features/home/data/home_conversation_cloud_sync.dart';
import 'package:zhaoxingzhai/core/sync/sync_version_conflict.dart';

class HomeConversationMessage {
  const HomeConversationMessage({
    required this.text,
    required this.createdAt,
    this.toolId,
  });

  final String text;
  final DateTime createdAt;
  final String? toolId;

  Map<String, dynamic> toJson() => {
    'text': text,
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (toolId != null) 'toolId': toolId,
  };

  static HomeConversationMessage? tryParse(Object? raw) {
    if (raw is! Map || raw['text'] is! String || raw['createdAt'] is! String) {
      return null;
    }
    final date = DateTime.tryParse(raw['createdAt'] as String);
    if (date == null || (raw['text'] as String).trim().isEmpty) return null;
    return HomeConversationMessage(
      text: (raw['text'] as String).trim(),
      createdAt: date,
      toolId: raw['toolId'] as String?,
    );
  }
}

class HomeConversation {
  const HomeConversation({
    required this.id,
    required this.messages,
    required this.updatedAt,
    this.cloudVersion,
  });

  final String id;
  final List<HomeConversationMessage> messages;
  final DateTime updatedAt;
  final int? cloudVersion;

  String get title => messages.isEmpty ? '新会话' : messages.first.text;

  Map<String, dynamic> toJson() => {
    'id': id,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    if (cloudVersion != null) 'cloudVersion': cloudVersion,
    'messages': messages.map((message) => message.toJson()).toList(),
  };

  static HomeConversation? tryParse(Object? raw) {
    if (raw is! Map || raw['id'] is! String || raw['updatedAt'] is! String) {
      return null;
    }
    final updatedAt = DateTime.tryParse(raw['updatedAt'] as String);
    final messages = raw['messages'] is List
        ? (raw['messages'] as List)
              .map(HomeConversationMessage.tryParse)
              .whereType<HomeConversationMessage>()
              .toList(growable: false)
        : const <HomeConversationMessage>[];
    if (updatedAt == null) return null;
    return HomeConversation(
      id: raw['id'] as String,
      messages: messages,
      updatedAt: updatedAt,
      cloudVersion: (raw['cloudVersion'] as num?)?.toInt(),
    );
  }
}

class HomeConversationRepository extends ChangeNotifier {
  HomeConversationRepository({
    Future<SharedPreferences> Function()? preferencesFactory,
    this.cloudSync,
  }) : _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance;

  static const storageKey = 'zhaoxingzhai.home_conversations.v1';
  final Future<SharedPreferences> Function() _preferencesFactory;
  final HomeConversationCloudSync? cloudSync;
  final List<HomeConversation> _conversations = [];
  final Map<String, HomeConversation> _conflicts = {};
  int _idSequence = 0;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<HomeConversation> get conversations => List.unmodifiable(_conversations);
  List<HomeConversation> get conflicts => List.unmodifiable(_conflicts.values);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final preferences = await _preferencesFactory();
    final raw = preferences.getString(storageKey);
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _conversations
          ..clear()
          ..addAll(
            decoded
                .map(HomeConversation.tryParse)
                .whereType<HomeConversation>(),
          );
      }
    }
    _sort();
    _loaded = true;
    notifyListeners();
  }

  Future<HomeConversation> append({
    required String text,
    String? toolId,
    String? conversationId,
  }) async {
    await ensureLoaded();
    final now = DateTime.now().toUtc();
    final index = _conversations.indexWhere(
      (item) => item.id == conversationId,
    );
    final message = HomeConversationMessage(
      text: text,
      createdAt: now,
      toolId: toolId,
    );
    final conversation = index < 0
        ? HomeConversation(
            id: _newConversationId(now),
            messages: [message],
            updatedAt: now,
            cloudVersion: null,
          )
        : HomeConversation(
            id: _conversations[index].id,
            messages: [..._conversations[index].messages, message],
            updatedAt: now,
            cloudVersion: _conversations[index].cloudVersion,
          );
    if (index < 0) {
      _conversations.add(conversation);
    } else {
      _conversations[index] = conversation;
    }
    _sort();
    await _persist();
    await _syncConversation(conversation);
    notifyListeners();
    return conversation;
  }

  Future<void> delete(String id) async {
    await ensureLoaded();
    HomeConversation? conversation;
    for (final item in _conversations) {
      if (item.id == id) {
        conversation = item;
        break;
      }
    }
    _conversations.removeWhere((item) => item.id == id);
    await _persist();
    if (cloudSync != null) {
      try {
        await cloudSync!.delete(id, baseVersion: conversation?.cloudVersion);
      } on SyncVersionConflict {
        if (conversation != null) {
          _conversations.add(conversation);
          _conflicts[id] = conversation;
          _sort();
          await _persist();
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> clear() async {
    await ensureLoaded();
    _conversations.clear();
    await _persist();
    notifyListeners();
  }

  void _sort() =>
      _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<void> _persist() async {
    final preferences = await _preferencesFactory();
    await preferences.setString(
      storageKey,
      jsonEncode(
        _conversations.map((conversation) => conversation.toJson()).toList(),
      ),
    );
  }

  Future<void> syncFromCloud() async {
    final sync = cloudSync;
    if (sync == null) return;
    await ensureLoaded();
    try {
      for (final item in await sync.fetch()) {
        final index = _conversations.indexWhere(
          (local) => local.id == item.conversation.id,
        );
        if (index < 0) {
          _conversations.add(item.conversation);
        } else if (item.conversation.updatedAt.isAfter(
          _conversations[index].updatedAt,
        )) {
          _conversations[index] = item.conversation;
        } else {
          final local = _conversations[index];
          _conversations[index] = HomeConversation(
            id: local.id,
            messages: local.messages,
            updatedAt: local.updatedAt,
            cloudVersion: item.version,
          );
        }
      }
      _sort();
      await _persist();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _syncConversation(HomeConversation conversation) async {
    final sync = cloudSync;
    if (sync == null) return;
    try {
      final uploaded = await sync.upsert(
        conversation,
        baseVersion: conversation.cloudVersion,
      );
      final index = _conversations.indexWhere(
        (item) => item.id == conversation.id,
      );
      if (index >= 0) {
        _conversations[index] = HomeConversation(
          id: uploaded.conversation.id,
          messages: uploaded.conversation.messages,
          updatedAt: uploaded.conversation.updatedAt,
          cloudVersion: uploaded.version,
        );
        await _persist();
      }
    } on SyncVersionConflict {
      _conflicts[conversation.id] = conversation;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> resolveConflictKeepLocal(HomeConversation conversation) async {
    final sync = cloudSync;
    if (sync == null) return;
    try {
      int? currentVersion;
      for (final item in await sync.fetch()) {
        if (item.conversation.id == conversation.id) {
          currentVersion = item.version;
          break;
        }
      }
      final local = HomeConversation(
        id: conversation.id,
        messages: conversation.messages,
        updatedAt: conversation.updatedAt,
        cloudVersion: currentVersion,
      );
      _conflicts.remove(conversation.id);
      await _syncConversation(local);
      notifyListeners();
    } catch (_) {
      // Keep the conflict visible so the user can retry when connectivity returns.
    }
  }

  Future<void> resolveConflictUseCloud(String conversationId) async {
    final sync = cloudSync;
    if (sync == null) return;
    try {
      final cloudItems = await sync.fetch();
      CloudConversation? cloud;
      for (final item in cloudItems) {
        if (item.conversation.id == conversationId) {
          cloud = item;
          break;
        }
      }
      if (cloud == null) return;
      final index = _conversations.indexWhere(
        (conversation) => conversation.id == conversationId,
      );
      if (index < 0) {
        _conversations.add(cloud.conversation);
      } else {
        _conversations[index] = cloud.conversation;
      }
      _conflicts.remove(conversationId);
      _sort();
      await _persist();
      notifyListeners();
    } catch (_) {
      // Keep the conflict visible so the user can retry when connectivity returns.
    }
  }

  void discardConflict(String conversationId) {
    _conflicts.remove(conversationId);
    notifyListeners();
  }

  String _newConversationId(DateTime now) {
    String candidate() => 'home:${now.microsecondsSinceEpoch}:${_idSequence++}';
    var id = candidate();
    while (_conversations.any((conversation) => conversation.id == id)) {
      id = candidate();
    }
    return id;
  }
}
