import SwiftUI
import SQLite3
import Foundation

// MARK: - Quote Model
struct Quote: Identifiable, Codable {
    let id: Int
    let text: String
    let author: String
    let dateCreated: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateCreated)
    }
}

// MARK: - Database Manager
class DatabaseManager: ObservableObject {
    private var db: OpaquePointer?
    private let dbPath: String
    
    init() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("quotes.sqlite")
        
        dbPath = fileURL.path
        openDatabase()
        createTable()
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("Successfully opened database at \(dbPath)")
        } else {
            print("Unable to open database")
        }
    }
    
    private func createTable() {
        let createTableString = """
            CREATE TABLE IF NOT EXISTS quotes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            author TEXT NOT NULL,
            date_created REAL NOT NULL);
            """
        
        if sqlite3_exec(db, createTableString, nil, nil, nil) == SQLITE_OK {
            print("Quotes table created.")
        } else {
            print("Quotes table could not be created.")
        }
    }
    
    func insertQuote(text: String, author: String) -> Bool {
        let insertString = "INSERT INTO quotes (text, author, date_created) VALUES (?, ?, ?)"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertString, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, text, -1, nil)
            sqlite3_bind_text(statement, 2, author, -1, nil)
            sqlite3_bind_double(statement, 3, Date().timeIntervalSince1970)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func getAllQuotes() -> [Quote] {
        let queryString = "SELECT id, text, author, date_created FROM quotes ORDER BY date_created DESC"
        var statement: OpaquePointer?
        var quotes: [Quote] = []
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int(statement, 0)
                let text = String(describing: String(cString: sqlite3_column_text(statement, 1)))
                let author = String(describing: String(cString: sqlite3_column_text(statement, 2)))
                let dateCreated = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
                
                quotes.append(Quote(id: Int(id), text: text, author: author, dateCreated: dateCreated))
            }
        }
        
        sqlite3_finalize(statement)
        return quotes
    }
    
    func getRandomQuote() -> Quote? {
        let queryString = "SELECT id, text, author, date_created FROM quotes ORDER BY RANDOM() LIMIT 1"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int(statement, 0)
                let text = String(describing: String(cString: sqlite3_column_text(statement, 1)))
                let author = String(describing: String(cString: sqlite3_column_text(statement, 2)))
                let dateCreated = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
                
                sqlite3_finalize(statement)
                return Quote(id: Int(id), text: text, author: author, dateCreated: dateCreated)
            }
        }
        
        sqlite3_finalize(statement)
        return nil
    }
    
    deinit {
        sqlite3_close(db)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var databaseManager = DatabaseManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(databaseManager: databaseManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            QuotesListView(databaseManager: databaseManager)
                .tabItem {
                    Image(systemName: "quote.bubble.fill")
                    Text("Quotes")
                }
                .tag(1)
        }
        .accentColor(.blue)
    }
}

// MARK: - Home View
struct HomeView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var quoteText = ""
    @State private var authorName = ""
    @State private var quoteOfTheDay: Quote?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text("Quottary")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top)
                
                // Quote of the Day Section
                VStack(spacing: 10) {
                    Text("Quote of the Day")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    if let quote = quoteOfTheDay {
                        QuoteCardView(quote: quote)
                    } else {
                        Text("No quotes yet. Add your first quote below!")
                            .font(.body)
                            .foregroundColor(.secondary)
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
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        TextField("Enter your quote...", text: $quoteText, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                        
                        TextField("Author name", text: $authorName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: saveQuote) {
                            Text("Save Quote")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                        }
                        .disabled(quoteText.isEmpty || authorName.isEmpty)
                        .opacity(quoteText.isEmpty || authorName.isEmpty ? 0.6 : 1.0)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            loadQuoteOfTheDay()
        }
        .alert("Quote Status", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveQuote() {
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
}

// MARK: - Quotes List View
struct QuotesListView: View {
    @ObservedObject var databaseManager: DatabaseManager
    @State private var quotes: [Quote] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if quotes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "quote.bubble")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No quotes yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Start adding quotes from the Home tab")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(quotes) { quote in
                        QuoteRowView(quote: quote)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("My Quotes")
            .onAppear {
                loadQuotes()
            }
        }
    }
    
    private func loadQuotes() {
        quotes = databaseManager.getAllQuotes()
    }
}

// MARK: - Quote Card View
struct QuoteCardView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(quote.text)\"")
                .font(.body)
                .italic()
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            HStack {
                Spacer()
                Text("— \(quote.author)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Quote Row View
struct QuoteRowView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(quote.text)\"")
                .font(.body)
                .italic()
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            HStack {
                Text(quote.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("— \(quote.author)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
