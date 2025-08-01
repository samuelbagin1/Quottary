import SwiftUI
import SQLite3
import Foundation

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
        
        guard sqlite3_prepare_v2(db, insertString, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        
        // Bind text with explicit UTF-8 handling
        let textData = text.data(using: .utf8)!
        let authorData = author.data(using: .utf8)!
        
        textData.withUnsafeBytes { textBytes in
            sqlite3_bind_text(statement, 1, textBytes.bindMemory(to: CChar.self).baseAddress, Int32(textData.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        }
        
        authorData.withUnsafeBytes { authorBytes in
            sqlite3_bind_text(statement, 2, authorBytes.bindMemory(to: CChar.self).baseAddress, Int32(authorData.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        }
        
        sqlite3_bind_double(statement, 3, Date().timeIntervalSince1970)
        
        let stepResult = sqlite3_step(statement)
        sqlite3_finalize(statement)
        
        return stepResult == SQLITE_DONE
    }
    
    func getAllQuotes() -> [Quote] {
        let queryString = "SELECT id, text, author, date_created FROM quotes ORDER BY date_created DESC"
        var statement: OpaquePointer?
        var quotes: [Quote] = []
        
        guard sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK else {
            return quotes
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int(statement, 0)
            
            // Get text with proper UTF-8 handling
            var text = ""
            if let textPointer = sqlite3_column_text(statement, 1) {
                let textLength = sqlite3_column_bytes(statement, 1)
                if textLength > 0 {
                    let textData = Data(bytes: textPointer, count: Int(textLength))
                    text = String(data: textData, encoding: .utf8) ?? ""
                }
            }
            
            // Get author with proper UTF-8 handling
            var author = ""
            if let authorPointer = sqlite3_column_text(statement, 2) {
                let authorLength = sqlite3_column_bytes(statement, 2)
                if authorLength > 0 {
                    let authorData = Data(bytes: authorPointer, count: Int(authorLength))
                    author = String(data: authorData, encoding: .utf8) ?? ""
                }
            }
            
            let dateCreated = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
            
            quotes.append(Quote(id: Int(id), text: text, author: author, dateCreated: dateCreated))
        }
        
        sqlite3_finalize(statement)
        return quotes
    }
    
    func getRandomQuote() -> Quote? {
        let queryString = "SELECT id, text, author, date_created FROM quotes ORDER BY RANDOM() LIMIT 1"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int(statement, 0)
            
            // Get text with proper UTF-8 handling
            var text = ""
            if let textPointer = sqlite3_column_text(statement, 1) {
                let textLength = sqlite3_column_bytes(statement, 1)
                if textLength > 0 {
                    let textData = Data(bytes: textPointer, count: Int(textLength))
                    text = String(data: textData, encoding: .utf8) ?? ""
                }
            }
            
            // Get author with proper UTF-8 handling
            var author = ""
            if let authorPointer = sqlite3_column_text(statement, 2) {
                let authorLength = sqlite3_column_bytes(statement, 2)
                if authorLength > 0 {
                    let authorData = Data(bytes: authorPointer, count: Int(authorLength))
                    author = String(data: authorData, encoding: .utf8) ?? ""
                }
            }
            
            let dateCreated = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
            
            sqlite3_finalize(statement)
            return Quote(id: Int(id), text: text, author: author, dateCreated: dateCreated)
        }
        
        sqlite3_finalize(statement)
        return nil
    }
    
    func deleteQuote(id: Int) -> Bool {
        let deleteString = "DELETE FROM quotes WHERE id = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, deleteString, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        
        sqlite3_bind_int(statement, 1, Int32(id))
        
        let stepResult = sqlite3_step(statement)
        sqlite3_finalize(statement)
        
        return stepResult == SQLITE_DONE
    }
    
    deinit {
        sqlite3_close(db)
    }
}
