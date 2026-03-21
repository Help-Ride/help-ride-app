import 'dart:async';

import 'package:get/get.dart';
import 'package:help_ride/features/support/services/support_api.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_exception.dart';
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
  final moderationBusy = false.obs;
  final error = RxnString();
  final draft = ''.obs;
  final blockedByMe = false.obs;
  final blockedByOtherUser = false.obs;
  bool _markingRead = false;
  late final SupportApi _supportApi;

  String get currentUserId {
    if (Get.isRegistered<SessionController>()) {
      return Get.find<SessionController>().user.value?.id ?? '';
    }
    return '';
  }

  String get currentRole {
    if (Get.isRegistered<SessionController>()) {
      return Get.find<SessionController>().user.value?.roleDefault ??
          'passenger';
    }
    return 'passenger';
  }

  bool get chatDisabled => blockedByMe.value || blockedByOtherUser.value;

  String get participantId => conversation.participant.id.trim();

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = ChatApi(client);
    _pusher = ChatPusherService(_api);
    _supportApi = SupportApi(client);
    blockedByMe.value = conversation.blockedByMe;
    blockedByOtherUser.value = conversation.blockedByOtherUser;
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
      await _markConversationRead();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<bool> sendCurrent() async {
    final body = draft.value.trim();
    if (body.isEmpty || chatDisabled) return false;
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
      return true;
    } catch (e) {
      _removePending(pending);
      draft.value = body;
      final message = _normalizeError(e);
      error.value = message;
      Get.snackbar('Message not sent', message);
      return false;
    } finally {
      sending.value = false;
    }
  }

  Future<bool> blockParticipant() async {
    final userId = participantId;
    if (userId.isEmpty) return false;
    moderationBusy.value = true;
    try {
      final state = await _api.blockUser(userId: userId);
      _applyModerationState(state);
      await _refreshConversationListIfAvailable();
      Get.snackbar(
        'User blocked',
        'You will no longer receive chat messages from this user.',
      );
      return true;
    } catch (e) {
      final message = _normalizeError(e);
      error.value = message;
      Get.snackbar('Unable to block user', message);
      return false;
    } finally {
      moderationBusy.value = false;
    }
  }

  Future<bool> unblockParticipant() async {
    final userId = participantId;
    if (userId.isEmpty) return false;
    moderationBusy.value = true;
    try {
      final state = await _api.unblockUser(userId: userId);
      _applyModerationState(state);
      await _refreshConversationListIfAvailable();
      Get.snackbar('User unblocked', 'Chat has been restored for this thread.');
      return true;
    } catch (e) {
      final message = _normalizeError(e);
      error.value = message;
      Get.snackbar('Unable to unblock user', message);
      return false;
    } finally {
      moderationBusy.value = false;
    }
  }

  Future<bool> reportParticipant({required String details}) async {
    final subjectName = conversation.participant.name.trim().isEmpty
        ? 'Unknown user'
        : conversation.participant.name.trim();
    final rideReference = conversation.rideReference?.trim().isNotEmpty == true
        ? conversation.rideReference!.trim()
        : conversation.rideId;
    moderationBusy.value = true;
    try {
      await _supportApi.createTicket(
        subject: 'Chat report: $subjectName',
        description: [
          'Report type: user',
          'Conversation ID: ${conversation.id}',
          'Ride reference: ${rideReference.isEmpty ? 'N/A' : rideReference}',
          'Reported user ID: ${participantId.isEmpty ? 'N/A' : participantId}',
          'Reported user role: ${conversation.participant.role}',
          'Reporter user ID: ${currentUserId.isEmpty ? 'N/A' : currentUserId}',
          '',
          'Report details:',
          details.trim(),
        ].join('\n'),
      );
      Get.snackbar(
        'Report submitted',
        'Your report has been sent to support for review.',
      );
      return true;
    } catch (e) {
      final message = _normalizeError(e);
      error.value = message;
      Get.snackbar('Unable to submit report', message);
      return false;
    } finally {
      moderationBusy.value = false;
    }
  }

  Future<bool> reportMessage({
    required ChatMessage message,
    required String details,
  }) async {
    final rideReference = conversation.rideReference?.trim().isNotEmpty == true
        ? conversation.rideReference!.trim()
        : conversation.rideId;
    moderationBusy.value = true;
    try {
      await _supportApi.createTicket(
        subject: 'Chat message report',
        description: [
          'Report type: message',
          'Conversation ID: ${conversation.id}',
          'Ride reference: ${rideReference.isEmpty ? 'N/A' : rideReference}',
          'Reported user ID: ${message.senderId.isEmpty ? 'N/A' : message.senderId}',
          'Reported message ID: ${message.id.isEmpty ? 'N/A' : message.id}',
          'Reported message time: ${message.createdAt.toIso8601String()}',
          '',
          'Reported message body:',
          message.body,
          '',
          'Report details:',
          details.trim(),
        ].join('\n'),
      );
      Get.snackbar(
        'Message reported',
        'Your message report has been sent to support.',
      );
      return true;
    } catch (e) {
      final messageText = _normalizeError(e);
      error.value = messageText;
      Get.snackbar('Unable to submit report', messageText);
      return false;
    } finally {
      moderationBusy.value = false;
    }
  }

  void handleIncoming(ChatMessage message) {
    if (message.conversationId != conversation.id) return;
    if (_isDuplicate(message)) return;
    _upsertMessage(message);
    _updateConversationPreview(message);
    if (!_isMineMessage(message)) {
      unawaited(_markConversationRead());
    }
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

  void _removePending(ChatMessage pending) {
    messages.removeWhere((message) => message.id == pending.id);
  }

  void _upsertMessage(ChatMessage message) {
    if (message.id.isNotEmpty) {
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        final existing = messages[index];
        if (message.readAt == null && existing.readAt != null) {
          messages[index] = message.copyWith(readAt: existing.readAt);
        } else {
          messages[index] = message;
        }
        return;
      }
    }
    messages.add(message);
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
    if (message.id.isNotEmpty && messages.any((m) => m.id == message.id)) {
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

  bool _isMineMessage(ChatMessage message) {
    final me = currentUserId;
    if (me.isNotEmpty) return message.senderId == me;
    return message.senderRole == currentRole;
  }

  Future<void> _markConversationRead() async {
    _clearConversationUnreadLocally();
    final id = conversation.id.trim();
    if (id.isEmpty || _markingRead) return;

    _markingRead = true;
    try {
      final result = await _api.markConversationRead(id);
      final readAt = result.readAt;
      if (readAt != null && result.messageIds.isNotEmpty) {
        _applyReadAtToMessages(result.messageIds.toSet(), readAt);
      }
    } catch (_) {
      // Non-blocking: the thread should remain usable even if this call fails.
    } finally {
      _markingRead = false;
    }
  }

  void _clearConversationUnreadLocally() {
    if (!Get.isRegistered<ChatConversationsController>()) return;
    Get.find<ChatConversationsController>().markConversationReadLocally(
      conversation.id,
    );
  }

  void _applyReadAtToMessages(Set<String> messageIds, DateTime readAt) {
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (!messageIds.contains(message.id)) continue;
      if (message.readAt != null) continue;
      messages[i] = message.copyWith(readAt: readAt);
    }
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

  void _applyModerationState(ChatModerationState state) {
    blockedByMe.value = state.blockedByMe;
    blockedByOtherUser.value = state.blockedByOtherUser;
  }

  Future<void> _refreshConversationListIfAvailable() async {
    if (!Get.isRegistered<ChatConversationsController>()) return;
    await Get.find<ChatConversationsController>().fetch();
  }

  String _normalizeError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    final text = error.toString().trim();
    if (text.startsWith('Exception:')) {
      return text.substring('Exception:'.length).trim();
    }
    return text.isEmpty ? 'Something went wrong.' : text;
  }
}
