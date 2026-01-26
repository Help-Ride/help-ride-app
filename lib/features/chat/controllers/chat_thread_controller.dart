import 'package:get/get.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_client.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import 'chat_conversations_controller.dart';
import '../services/chat_api.dart';
import '../services/chat_pusher_service.dart';

class ChatThreadController extends GetxController {
  ChatThreadController({required this.conversation});

  final ChatConversation conversation;
  late final ChatApi _api;
  late final ChatPusherService _pusher;

  final messages = <ChatMessage>[].obs;
  final loading = false.obs;
  final sending = false.obs;
  final error = RxnString();
  final draft = ''.obs;

  String get currentUserId {
    if (Get.isRegistered<SessionController>()) {
      return Get.find<SessionController>().user.value?.id ?? '';
    }
    return '';
  }

  String get currentRole {
    if (Get.isRegistered<SessionController>()) {
      return Get.find<SessionController>().user.value?.roleDefault ?? 'passenger';
    }
    return 'passenger';
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = ChatApi(client);
    _pusher = ChatPusherService(_api);
    await fetch();
    await _pusher.subscribeToConversation(
      conversation.id,
      onMessage: handleIncoming,
    );
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    try {
      final list = await _api.listMessages(conversation.id);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final deduped = _dedupe(list);
      messages.assignAll(deduped);
      if (deduped.isNotEmpty) {
        _updateConversationPreview(deduped.last);
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> sendCurrent() async {
    final body = draft.value.trim();
    if (body.isEmpty) return;
    draft.value = '';

    final pending = ChatMessage.pending(
      conversationId: conversation.id,
      senderId: currentUserId,
      senderRole: currentRole,
      body: body,
    );
    _upsertMessage(pending);
    _updateConversationPreview(pending);

    sending.value = true;
    try {
      final sent = await _api.sendMessage(
        conversationId: conversation.id,
        body: body,
      );
      _replacePending(pending, sent);
      _updateConversationPreview(sent);
    } catch (e) {
      error.value = e.toString();
    } finally {
      sending.value = false;
    }
  }

  void handleIncoming(ChatMessage message) {
    if (message.conversationId != conversation.id) return;
    if (_isDuplicate(message)) return;
    _upsertMessage(message);
    _updateConversationPreview(message);
  }

  @override
  void onClose() {
    _pusher.unsubscribeFromConversation();
    super.onClose();
  }

  void _replacePending(ChatMessage pending, ChatMessage sent) {
    final index = messages.indexWhere((m) => m.id == pending.id);
    if (index != -1) {
      messages[index] = sent;
      return;
    }
    _upsertMessage(sent);
  }

  void _upsertMessage(ChatMessage message) {
    if (message.id.isNotEmpty) {
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        messages[index] = message;
        return;
      }
    }
    messages.add(message);
  }

  void _updateConversationPreview(ChatMessage message) {
    if (!Get.isRegistered<ChatConversationsController>()) return;
    final controller = Get.find<ChatConversationsController>();
    controller.updatePreview(
      conversationId: conversation.id,
      lastMessage: message.body,
      lastMessageAt: message.createdAt,
    );
  }

  bool _isDuplicate(ChatMessage message) {
    if (message.id.isNotEmpty &&
        messages.any((m) => m.id == message.id)) {
      return true;
    }
    final window = const Duration(seconds: 5);
    return messages.any((m) {
      if (m.senderId != message.senderId) return false;
      if (m.body != message.body) return false;
      final diff = m.createdAt.difference(message.createdAt).abs();
      return diff <= window;
    });
  }

  List<ChatMessage> _dedupe(List<ChatMessage> list) {
    final result = <ChatMessage>[];
    final seenIds = <String>{};
    for (final msg in list) {
      if (msg.id.isNotEmpty) {
        if (seenIds.contains(msg.id)) continue;
        seenIds.add(msg.id);
      }
      result.add(msg);
    }
    return result;
  }
}
