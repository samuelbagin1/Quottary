import SwiftUI
import SQLite3
import Foundation


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
