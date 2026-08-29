import SwiftUI
import SwiftData

struct SupportChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SupportMessage.timestamp) private var messages: [SupportMessage]
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader

            Divider()

            // Chat area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Welcome message
                        Text("Ask us anything, or share your feedback.")
                            .font(LebolFont.subheadline())
                            .foregroundColor(.lebolTextSecondary)
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                        // Messages
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                        // Waiting status
                        if let lastMessage = messages.last, lastMessage.isFromUser {
                            waitingStatus
                        }
                    }
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input bar
            inputBar
        }
        .background(Color.lebolBackground)
        .navigationBarHidden(true)
    }

    // MARK: - Header
    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.lebolTextPrimary)
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(Color.lebolPrimary)
                    .frame(width: 36, height: 36)
                Text("S")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Lebol")
                    .font(LebolFont.headline())
                    .foregroundColor(.lebolTextPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("Within a day")
                        .font(LebolFont.caption())
                }
                .foregroundColor(.lebolTextSecondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.lebolTextPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.lebolCardBackground)
    }

    // MARK: - Waiting Status
    private var waitingStatus: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.lebolPrimary)
                    .frame(width: 28, height: 28)
                Text("S")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text("Waiting for a teammate")
                .font(LebolFont.caption())
                .foregroundColor(.lebolTextSecondary)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask a question...", text: $inputText, axis: .vertical)
                .font(LebolFont.body())
                .lineLimit(1...4)
                .focused($isInputFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.lebolBorder, lineWidth: 1)
                )

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .lebolTextTertiary : .lebolPrimary)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.lebolCardBackground)
    }

    // MARK: - Actions
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let message = SupportMessage(text: text, isFromUser: true)
        modelContext.insert(message)
        modelContext.saveWithLogging()

        inputText = ""
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: SupportMessage

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var timeString: String {
        Self.timeFormatter.string(from: message.timestamp)
    }

    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 60) }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(LebolFont.body())
                    .foregroundColor(message.isFromUser ? .white : .lebolTextPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.isFromUser ? Color.lebolPrimary : Color.lebolDivider)
                    )

                Text(timeString)
                    .font(.system(size: 10))
                    .foregroundColor(.lebolTextTertiary)
            }

            if !message.isFromUser { Spacer(minLength: 60) }
        }
    }
}
