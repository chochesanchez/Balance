import SwiftUI

struct AskBalanceView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @ObservedObject var subscription: SubscriptionManager
    @State private var question: String = ""
    @State private var response: AssistantService.Response? = nil
    @State private var history: [Exchange] = []
    @State private var showPaywall = false
    @FocusState private var inputFocused: Bool

    struct Exchange: Identifiable {
        let id = UUID()
        let question: String
        let response: AssistantService.Response
    }

    var body: some View {
        Group {
            if subscription.effectiveIsPlus {
                assistant
            } else {
                preview
            }
        }
        .navigationTitle("Ask Balance")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscription: subscription)
        }
    }

    private var assistant: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if history.isEmpty {
                            emptyState
                        } else {
                            ForEach(history) { exchange in
                                exchangeRow(exchange)
                                    .id(exchange.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                }
                .onChange(of: history.count) { _, _ in
                    if let last = history.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            disclaimerBar

            inputBar
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(Theme.Colors.primary)
                    .accessibilityHidden(true)
                Text("Try a question")
                    .font(.system(size: 15, weight: .semibold))
            }

            VStack(spacing: 8) {
                ForEach(AssistantService.starterPrompts, id: \.self) { prompt in
                    Button {
                        ask(prompt)
                    } label: {
                        HStack {
                            Text(prompt)
                                .font(.system(size: 14))
                                .foregroundColor(Color(uiColor: .label))
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.Colors.primary)
                                .accessibilityHidden(true)
                        }
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Sends this question to the assistant")
                }
            }
        }
    }

    @ViewBuilder
    private func exchangeRow(_ exchange: Exchange) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(exchange.question)
                .font(.system(size: 14))
                .padding(10)
                .background(Theme.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel("You asked: \(exchange.question)")

            VStack(alignment: .leading, spacing: 6) {
                Text(exchange.response.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                Text(exchange.response.body)
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: .label))
                    .fixedSize(horizontal: false, vertical: true)

                if !exchange.response.followUps.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(exchange.response.followUps, id: \.self) { f in
                                Button { ask(f) } label: {
                                    Text(f)
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Theme.Colors.primary.opacity(0.1))
                                        .foregroundColor(Theme.Colors.primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(exchange.response.title). \(exchange.response.body)")
        }
    }

    private var disclaimerBar: some View {
        Text("Balance provides educational insights, not professional financial advice.")
            .font(.system(size: 10))
            .foregroundColor(Color(uiColor: .tertiaryLabel))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about your money…", text: $question, axis: .vertical)
                .lineLimit(1...3)
                .focused($inputFocused)
                .padding(10)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(20)
                .accessibilityLabel("Ask Balance")

            Button {
                ask(question)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(question.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(uiColor: .systemGray3)
                                : Theme.Colors.primary)
                    .clipShape(Circle())
            }
            .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Send question")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }

    private var preview: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.7)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 72, height: 72)
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .accessibilityHidden(true)
                    }
                    Text("Ask Balance")
                        .font(.system(size: 22, weight: .bold))
                    Text("Private, on-device-first answers about your money. Included with Balance Plus.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 16)

                VStack(spacing: 8) {
                    ForEach(AssistantService.starterPrompts.prefix(4), id: \.self) { prompt in
                        Text(prompt)
                            .font(.system(size: 13))
                            .foregroundColor(Color(uiColor: .label))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)

                Button {
                    showPaywall = true
                } label: {
                    Text("Get Balance Plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 16)
                .accessibilityLabel("Get Balance Plus")
            }
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func ask(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let service = AssistantService(viewModel: viewModel)
        let r = service.answer(trimmed)
        withAnimation(.snappy) {
            history.append(Exchange(question: trimmed, response: r))
            question = ""
        }
        Haptics.light()
    }
}
