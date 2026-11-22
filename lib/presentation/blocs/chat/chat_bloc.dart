import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/usecases/chat/send_message_usecase.dart';
import '../../../domain/usecases/chat/get_chat_history_usecase.dart';
import '../../../domain/usecases/ai/analyze_emotion_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// Chat BLoC for AI assistant conversations
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetChatHistoryUseCase getChatHistoryUseCase;
  final AnalyzeEmotionUseCase analyzeEmotionUseCase;

  ChatBloc({
    required this.sendMessageUseCase,
    required this.getChatHistoryUseCase,
    required this.analyzeEmotionUseCase,
  }) : super(const ChatInitial()) {
    on<ChatLoadHistory>(_onLoadHistory);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatClear>(_onClear);
  }

  Future<void> _onLoadHistory(
    ChatLoadHistory event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    final result = await getChatHistoryUseCase(event.userId);

    result.fold(
      (failure) => emit(ChatError(message: failure.message)),
      (messages) => emit(ChatLoaded(messages: messages)),
    );
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    final currentMessages = currentState is ChatLoaded
        ? List<ChatMessage>.from(currentState.messages)
        : <ChatMessage>[];

    emit(ChatLoaded(messages: currentMessages, isSending: true));

    final result = await sendMessageUseCase(
      userId: event.userId,
      content: event.content,
    );

    result.fold(
      (failure) =>
          emit(ChatError(message: failure.message, messages: currentMessages)),
      (aiResponse) => emit(
        ChatLoaded(
          messages: [...currentMessages, aiResponse],
          isSending: false,
        ),
      ),
    );
  }

  Future<void> _onClear(ChatClear event, Emitter<ChatState> emit) async {
    emit(const ChatLoaded(messages: []));
  }
}
