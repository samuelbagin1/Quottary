import SwiftUI
import SQLite3
import Foundation


// MARK: - Home View
struct HomeView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var quoteText = ""
    @State private var authorName = ""
    @State private var quoteOfTheDay: Quote?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var isTextFieldFocused: Bool
    @FocusState private var isAuthorFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text("Quottary")
                    .font(.appTitle)
                    .foregroundColor(Color("blackColor"))
                    .padding(.top)
                
                // Quote of the Day Section
                VStack(spacing: 10) {
                    Text("Quote of the Day")
                        .font(.sectionTitle)
                        .foregroundColor(Color("grayColor"))
                    
                    if let quote = quoteOfTheDay {
                        QuoteCardView(quote: quote)
                    } else {
                        Text("No quotes yet. Add your first quote below!")
                            .font(.bodyText)
                            .foregroundColor(Color("grayColor"))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Add Quote Section
                VStack(spacing: 15) {
                    Text("Add New Quote")
                        .font(.sectionTitle)
                        .foregroundColor(Color("blackColor"))
                    
                    VStack(spacing: 30) {
                        TextField("Enter your quote...", text: $quoteText, axis: .vertical)
                            .padding(10)
                            .font(.quoteText)
                            .foregroundColor(Color("blackColor"))
                            .background(Color("inputBoxColor"))
                            .cornerRadius(10)
                            .lineLimit(3...6)
                            .focused($isTextFieldFocused)
                        
                        HStack {
                            TextField("Author name", text: $authorName)
                                .padding(12)
                                .font(.authorText)
                                .background(Color("inputBoxDarkerColor"))
                                .cornerRadius(10)
                                .lineLimit(3...6)
                                .foregroundColor(Color("blackColor"))
                                .focused($isAuthorFieldFocused)
                                
                            
                            Button(action: saveQuote) {
                                Image(systemName: "plus.circle.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(Color("blackColor"))
                            }
                        }
                    }
                    .padding(10)
                    .background(Color("inputBoxColor"))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
                .foregroundColor(Color("blackColor"))
            }
            .background(Color("whiteColor"))
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        // Dismiss keyboard when swiping down
                        if gesture.translation.height > 50 {
                            dismissKeyboard()
                        }
                    }
            )
            .onTapGesture {
                // Also dismiss keyboard when tapping outside text fields
                dismissKeyboard()
            }
        }
        .onAppear {
            loadQuoteOfTheDay()
        }
//        .alert("Quote Status", isPresented: $showingAlert) {
//            Button("OK", role: .cancel) { }
//        } message: {
//            Text(alertMessage)
//        }
    }
    
    private func saveQuote() {
        // Dismiss keyboard before showing alert
        dismissKeyboard()
        
        if databaseManager.insertQuote(text: quoteText, author: authorName) {
            alertMessage = "Quote saved successfully!"
            quoteText = ""
            authorName = ""
            loadQuoteOfTheDay() // Refresh quote of the day
        } else {
            alertMessage = "Failed to save quote. Please try again."
        }
        showingAlert = true
    }
    
    private func loadQuoteOfTheDay() {
        quoteOfTheDay = databaseManager.getRandomQuote()
    }
    
    private func dismissKeyboard() {
        isTextFieldFocused = false
        isAuthorFieldFocused = false
    }
}


struct HomePrev: View {
    @StateObject private var databaseManager = DatabaseManager()
    
    var body: some View {
        HomeView(databaseManager: databaseManager)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    
    static var previews: some View {
        HomePrev()
    }
}
