import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date
}

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome message
                            if viewModel.messages.isEmpty {
                                welcomeView
                            }

                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isLoading {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .id("loading")
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            if let lastId = viewModel.messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input bar
                HStack(spacing: 10) {
                    TextField("Ask about your memories...", text: $viewModel.inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.plain)
                        .focused($isInputFocused)
                        .onSubmit { sendMessage() }

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.inputText.isEmpty ? .secondary : .dmPrimary)
                    }
                    .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !viewModel.messages.isEmpty {
                        Button("Clear") { viewModel.clearChat() }
                            .font(.caption)
                    }
                }
            }
        }
    }

    private func sendMessage() {
        guard !viewModel.inputText.isEmpty else { return }
        Task { await viewModel.send() }
    }

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.dmPrimary.opacity(0.5))

            Text("Ask me anything about your memories")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                SuggestionChip(text: "Who did I meet this week?") { viewModel.inputText = $0; Task { await viewModel.send() } }
                SuggestionChip(text: "What promises have I made?") { viewModel.inputText = $0; Task { await viewModel.send() } }
                SuggestionChip(text: "How has my mood been lately?") { viewModel.inputText = $0; Task { await viewModel.send() } }
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 32)
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    let isUser: Bool

    init(message: ChatMessage) {
        self.message = message
        self.isUser = message.role == "user"
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            Text(message.content)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.dmPrimary : Color(.systemBackground))
                .foregroundColor(isUser ? .white : .primary)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(i <= dotCount ? 1 : 0.3)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}

// MARK: - Suggestion Chip

private struct SuggestionChip: View {
    let text: String
    let onTap: (String) -> Void

    var body: some View {
        Button { onTap(text) } label: {
            Text(text)
                .font(.caption)
                .foregroundColor(.dmPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.dmPrimary.opacity(0.1))
                .cornerRadius(16)
        }
    }
}

// MARK: - ViewModel

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false

    private let apiClient = APIClient.shared

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: text, timestamp: Date())
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        do {
            let history = messages.dropLast().map { ["role": $0.role, "content": $0.content] }
            struct ChatResponse: Decodable { let reply: String }

            let response: ChatResponse = try await apiClient.post("ai/chat", body: [
                "message": text,
                "history": history,
            ])

            let assistantMessage = ChatMessage(role: "assistant", content: response.reply, timestamp: Date())
            messages.append(assistantMessage)
        } catch {
            let errorMessage = ChatMessage(role: "assistant", content: "Sorry, I couldn't process that. Please try again.", timestamp: Date())
            messages.append(errorMessage)
        }

        isLoading = false
    }

    func clearChat() {
        messages.removeAll()
    }
}

#Preview {
    ChatView()
}
