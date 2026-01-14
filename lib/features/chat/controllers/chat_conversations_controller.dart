import 'package:get/get.dart';
import 'package:help_ride/shared/services/api_client.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import '../models/chat_conversation.dart';
import '../models/chat_participant.dart';
import '../services/chat_api.dart';
import '../services/chat_pusher_service.dart';

class ChatConversationsController extends GetxController {
  late final ChatApi _api;
  late final ChatPusherService _pusher;

  final loading = false.obs;
  final error = RxnString();
  final conversations = <ChatConversation>[].obs;
  final query = ''.obs;
  final activeConversationId = RxnString();

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = ChatApi(client);
    _pusher = ChatPusherService(_api);
    await fetch();
    await _subscribeToUpdates();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    try {
      final session = Get.isRegistered<SessionController>()
          ? Get.find<SessionController>()
          : null;
      final currentUserId = session?.user.value?.id ?? '';
      final currentRole = session?.user.value?.roleDefault;
      final list = await _api.listConversations(
        currentUserId: currentUserId,
        currentRole: currentRole,
      );
      conversations.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _subscribeToUpdates() async {
    final userId = currentUserId;
    if (userId.isEmpty) return;
    await _pusher.subscribeToUserConversations(
      userId,
      currentUserId: userId,
      currentRole: currentRole,
      onConversationUpdated: _handleConversationUpdated,
      onUnknownPayload: () {
        fetch();
      },
    );
  }

  void setActiveConversation(String? conversationId) {
    activeConversationId.value = conversationId;
  }

  String get currentUserId {
    if (Get.isRegistered<SessionController>()) {
      return Get.find<SessionController>().user.value?.id ?? '';
    }
    return '';
  }

  String? get currentRole {
    if (Get.isRegistered<SessionController>()) {
      return Get.find<SessionController>().user.value?.roleDefault;
    }
    return null;
  }

  void _handleConversationUpdated(ChatConversation conversation) {
    if (conversation.id.isEmpty) {
      fetch();
      return;
    }
    final index = conversations.indexWhere((c) => c.id == conversation.id);
    if (index == -1) {
      if (_isPlaceholderName(conversation.participant.name)) {
        fetch();
        return;
      }
      conversations.insert(0, conversation);
      return;
    }

    final existing = conversations[index];
    final isActive = activeConversationId.value == conversation.id;
    final isNewer = _isNewer(existing, conversation);
    var incoming = conversation;
    if (!isActive && conversation.unreadCount == 0 && isNewer) {
      // If backend doesn't provide unread counts on updates, bump locally.
      // This avoids a full fetch and still shows a badge.
      final bumped = existing.unreadCount + 1;
      incoming = conversation.copyWith(unreadCount: bumped);
    }
    final mergedPassenger =
        _mergeParticipant(existing.passenger, incoming.passenger);
    final mergedDriver =
        _mergeParticipant(existing.driver, incoming.driver);
    final mergedParticipant =
        _mergeParticipant(existing.participant, incoming.participant);

    final updated = conversations[index].copyWith(
      rideId: incoming.rideId,
      passengerId: incoming.passengerId,
      driverId: incoming.driverId,
      passenger: mergedPassenger,
      driver: mergedDriver,
      participant: mergedParticipant,
      lastMessage: incoming.lastMessage,
      lastMessageAt: incoming.lastMessageAt,
      unreadCount: isActive ? 0 : incoming.unreadCount,
      tripSummary: incoming.tripSummary,
      tripTimeLabel: incoming.tripTimeLabel,
    );

    conversations[index] = updated;
    final moved = conversations.removeAt(index);
    conversations.insert(0, moved);
  }

  bool _isNewer(ChatConversation current, ChatConversation incoming) {
    final incomingAt = incoming.lastMessageAt;
    final currentAt = current.lastMessageAt;
    if (incomingAt != null && currentAt != null) {
      return incomingAt.isAfter(currentAt);
    }
    if (incomingAt != null && currentAt == null) return true;
    return incoming.lastMessage.isNotEmpty &&
        incoming.lastMessage != current.lastMessage;
  }

  ChatParticipant _mergeParticipant(
    ChatParticipant current,
    ChatParticipant incoming,
  ) {
    final incomingName = incoming.name.trim();
    final useIncomingName =
        incomingName.isNotEmpty && !_isPlaceholderName(incomingName);
    final incomingId = incoming.id.trim();
    final incomingAvatar = incoming.avatarUrl?.trim() ?? '';
    final useIncomingAvatar = incomingAvatar.isNotEmpty;

    return current.copyWith(
      id: incomingId.isNotEmpty ? incoming.id : current.id,
      name: useIncomingName ? incoming.name : current.name,
      role: incoming.role.trim().isNotEmpty ? incoming.role : current.role,
      rating: incoming.rating ?? current.rating,
      avatarUrl: useIncomingAvatar ? incoming.avatarUrl : current.avatarUrl,
      isOnline: useIncomingName ? incoming.isOnline : current.isOnline,
    );
  }

  bool _isPlaceholderName(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized == 'driver' ||
        normalized == 'passenger' ||
        normalized == 'user';
  }

  @override
  void onClose() {
    _pusher.unsubscribeFromUserConversations();
    super.onClose();
  }

  void setQuery(String value) => query.value = value.trim();

  List<ChatConversation> get filtered {
    final q = query.value.toLowerCase();
    if (q.isEmpty) return conversations;
    return conversations
        .where(
          (c) =>
              c.participant.name.toLowerCase().contains(q) ||
              c.lastMessage.toLowerCase().contains(q),
        )
        .toList();
  }
}
