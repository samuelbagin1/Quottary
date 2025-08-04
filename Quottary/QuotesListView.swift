import SwiftUI

// MARK: - Quotes List View
struct QuotesListView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var quotes: [Quote] = []
    @State private var showingDeleteAlert = false
    @State private var quoteToDelete: Quote?
    @State private var selectedQuote: Quote?
    @State private var showingEditView = false
    @State private var quoteToEdit: Quote?
    @State private var showingScreenshotAlert = false
    @State private var screenshotMessage = ""
    @StateObject private var screenshotManager = ScreenshotManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color("whiteColor")
                    .ignoresSafeArea(.all)

                VStack {
                    if quotes.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 60))
                                .foregroundColor(Color("grayColor"))

                            Text("No quotes yet")
                                .font(.sectionTitle)
                                .foregroundColor(Color("grayColor"))

                            Text("Start adding quotes from the Home tab")
                                .font(.bodyText)
                                .foregroundColor(Color("grayColor"))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(quotes) { quote in
                                QuoteRowView(quote: quote)
                                    .listRowBackground(Color("whiteColor"))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedQuote = quote
                                    }
                                    .quoteContextMenu(
                                        for: quote,
                                        actions: QuoteContextMenuActions(
                                            onSaveScreenshot: {
                                                saveScreenshot(for: quote)
                                            },
                                            onEdit: {
                                                editQuote(quote)
                                            },
                                            onDelete: {
                                                deleteQuoteWithConfirmation(quote)
                                            }
                                        )
                                    )
                                    .swipeActions(
                                        edge: .trailing,
                                        allowsFullSwipe: true
                                    ) {
                                        Button(role: .destructive) {
                                            deleteQuote(quote)
                                        } label: {
                                            Label(
                                                "Delete",
                                                systemImage: "trash"
                                            )
                                        }
                                    }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("My Quotes")
                            .font(.appTitle)
                            .foregroundColor(Color("blackColor"))
                    }
                }
                .onAppear {
                    loadQuotes()
                }
                .alert("Delete Quote", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        if let quote = quoteToDelete {
                            confirmDelete(quote)
                        }
                    }
                } message: {
                    if let quote = quoteToDelete {
                        Text(
                            "Are you sure you want to delete this quote by \(quote.author)?"
                        )
                    }
                }
                .alert("Screenshot", isPresented: $showingScreenshotAlert) {
                    Button("OK") {}
                } message: {
                    Text(screenshotMessage)
                }
            }
        }
        .fullScreenCover(item: $selectedQuote) { quote in
            QuoteCardFullScreen(quote: quote)
        }
        .sheet(item: $quoteToEdit) { quote in
            EditQuoteView(quote: quote, databaseManager: databaseManager)
                .onDisappear {
                    loadQuotes() // Refresh quotes after editing
                    quoteToEdit = nil // Clear the selected quote
                }
        }
    }

    private func loadQuotes() {
        quotes = databaseManager.getAllQuotes()
    }

    private func deleteQuote(_ quote: Quote) {
        // For immediate deletion without confirmation dialog
        if databaseManager.deleteQuote(id: quote.id) {
            withAnimation(.easeInOut(duration: 0.3)) {
                quotes.removeAll { $0.id == quote.id }
            }
        }
    }

    private func deleteQuoteWithConfirmation(_ quote: Quote) {
        // Alternative method with confirmation dialog
        quoteToDelete = quote
        showingDeleteAlert = true
    }

    private func confirmDelete(_ quote: Quote) {
        if databaseManager.deleteQuote(id: quote.id) {
            withAnimation(.easeInOut(duration: 0.3)) {
                quotes.removeAll { $0.id == quote.id }
            }
        }
        quoteToDelete = nil
    }

    private func saveScreenshot(for quote: Quote) {
        screenshotManager.saveQuoteScreenshot(quote: quote) { success, message in
            screenshotMessage = message
            showingScreenshotAlert = true

            if success {
                // Show haptic feedback for success
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }
    }

    private func editQuote(_ quote: Quote) {
        quoteToEdit = quote
    }
}

// MARK: - Preview Helper
struct QuotesListViewPreview: View {
    @StateObject private var databaseManager = DatabaseManager()
    @State private var quotes: [Quote] = [
        Quote(
            id: 1,
            text: "The only way to do great work is to love what you do.",
            author: "Steve Jobs",
            dateCreated: Calendar.current.date(
                from: DateComponents(year: 2024, month: 7, day: 15)
            )!
        ),
        Quote(
            id: 2,
            text: "In the middle of difficulty lies opportunity.",
            author: "Albert Einstein",
            dateCreated: Calendar.current.date(
                from: DateComponents(year: 2024, month: 6, day: 22)
            )!
        ),
        Quote(
            id: 3,
            text:
                "Life is what happens to you while you're busy making other plans.",
            author: "John Lennon",
            dateCreated: Calendar.current.date(
                from: DateComponents(year: 2024, month: 5, day: 10)
            )!
        ),
        Quote(
            id: 4,
            text:
                "The future belongs to those who believe in the beauty of their dreams.",
            author: "Eleanor Roosevelt",
            dateCreated: Calendar.current.date(
                from: DateComponents(year: 2024, month: 4, day: 3)
            )!
        ),
        Quote(
            id: 5,
            text:
                "It is during our darkest moments that we must focus to see the light.",
            author: "Aristotle",
            dateCreated: Calendar.current.date(
                from: DateComponents(year: 2024, month: 3, day: 18)
            )!
        ),
    ]

    var body: some View {
        QuotesListView(databaseManager: databaseManager)
    }
}

// MARK: - Preview
struct QuotesListView_Previews: PreviewProvider {
    static var previews: some View {
        QuotesListViewPreview()
    }
}
