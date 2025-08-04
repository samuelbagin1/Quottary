import SwiftUI

// MARK: - Edit Quote View
struct EditQuoteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var databaseManager: DatabaseManager

    let quote: Quote
    @State private var editedText: String
    @State private var editedAuthor: String
    @State private var showingSaveAlert = false

    init(quote: Quote, databaseManager: DatabaseManager) {
        self.quote = quote
        self.databaseManager = databaseManager
        self._editedText = State(initialValue: quote.text)
        self._editedAuthor = State(initialValue: quote.author)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color("whiteColor")
                    .ignoresSafeArea(.all)

                VStack(spacing: 24) {
                    // Quote text edit box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quote")
                            .font(.sectionTitle)
                            .foregroundColor(Color("blackColor"))

                        TextEditor(text: $editedText)
                            .font(.quoteText)
                            .foregroundColor(Color("blackColor"))
                            .scrollContentBackground(.hidden) // This removes the default background
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .frame(minHeight: 20)


                    }

                    // Author edit box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Author")
                            .font(.sectionTitle)
                            .foregroundColor(Color("blackColor"))

                        TextField("Enter author name", text: $editedAuthor)
                            .font(.authorText)
                            .foregroundColor(Color("blackColor"))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Save button
                    Button(action: saveQuote) {
                        Text("Save")
                            .font(.instrumentSerif(size: 20, italic: false))
                            .fontWeight(.semibold)
                            .foregroundColor(Color("whiteColor"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("buttonColor"))
                            )
                    }
                    .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             editedAuthor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("buttonColor"))
                }
            }
        }
        .alert("Quote Updated", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your quote has been successfully updated.")
        }
    }

    private func saveQuote() {
        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = editedAuthor.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty && !trimmedAuthor.isEmpty else {
            return
        }

        let updatedQuote = Quote(
            id: quote.id,
            text: trimmedText,
            author: trimmedAuthor,
            dateCreated: quote.dateCreated
        )

        if databaseManager.updateQuote(updatedQuote) {
            showingSaveAlert = true
        }
    }
}

// MARK: - Preview
struct EditQuoteView_Previews: PreviewProvider {
    static var previews: some View {
        EditQuoteView(
            quote: Quote(
                id: 1,
                text: "The only way to do great work is to love what you do.",
                author: "Steve Jobs",
                dateCreated: Date()
            ),
            databaseManager: DatabaseManager()
        )
    }
}
