import 'package:get/get.dart';
import 'package:help_ride/shared/services/api_client.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import '../models/chat_conversation.dart';
import '../services/chat_api.dart';

class ChatConversationsController extends GetxController {
  late final ChatApi _api;

  final loading = false.obs;
  final error = RxnString();
  final conversations = <ChatConversation>[].obs;
  final query = ''.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = ChatApi(client);
    await fetch();
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
