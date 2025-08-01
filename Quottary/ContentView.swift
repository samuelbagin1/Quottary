import SwiftUI
import SQLite3
import Foundation

// MARK: - Font Extension
extension Font {
    static func instrumentSerif(size: CGFloat, italic: Bool = false) -> Font {
        if italic {
            return .custom("InstrumentSerif-Italic", size: size)
        } else {
            return .custom("InstrumentSerif-Regular", size: size)
        }
    }
    
    // Predefined styles for the app
    static let appTitle = Font.instrumentSerif(size: 34, italic: false)
    static let sectionTitle = Font.instrumentSerif(size: 22, italic: false)
    static let bodyText = Font.instrumentSerif(size: 17, italic: false)
    static let quoteText = Font.instrumentSerif(size: 18, italic: true)
    static let captionText = Font.instrumentSerif(size: 13, italic: false)
    static let authorText = Font.instrumentSerif(size: 14, italic: true)
}

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



// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var databaseManager = DatabaseManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(databaseManager: databaseManager)
                .tabItem {
                    Image(systemName: "house.fill")
                }
                .tag(0)
            
            QuotesListView(databaseManager: databaseManager)
                .tabItem {
                    Image(systemName: "book.closed")
                }
                .tag(1)
        }
        .accentColor(Color("blackColor"))
    }
}








// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
