//
//  QuottaryTests.swift
//  QuottaryTests
//
//  Created by Samuel Bagín on 25/06/2025.
//

import Testing
import XCTest
import SQLite3
@testable import Quottary

struct QuottaryTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    
    
}



class DatabaseManagerTests: XCTestCase {
    
    var databaseManager: DatabaseManager!
    var testDbPath: String!
    
    override func setUp() {
        super.setUp()
        
        // Create a temporary database for testing
        let tempDirectory = NSTemporaryDirectory()
        testDbPath = "\(tempDirectory)test_quotes_\(UUID().uuidString).sqlite"
        
        // Create a test database manager with custom path
        databaseManager = TestDatabaseManager(testPath: testDbPath)
    }
    
    override func tearDown() {
        databaseManager = nil
        
        // Clean up test database file
        if FileManager.default.fileExists(atPath: testDbPath) {
            try? FileManager.default.removeItem(atPath: testDbPath)
        }
        
        super.tearDown()
    }
    
    // MARK: - Database Creation Tests
    
    func testDatabaseCreation() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: testDbPath),
                     "Database file should be created")
    }
    
    func testTableCreation() {
        // Test if quotes table exists by trying to insert data
        let success = databaseManager.insertQuote(text: "Test quote", author: "Test author")
        XCTAssertTrue(success, "Should be able to insert quote if table exists")
    }
    
    // MARK: - Insert Quote Tests
    
    func testInsertValidQuote() {
        let success = databaseManager.insertQuote(text: "Life is beautiful", author: "Anonymous")
        XCTAssertTrue(success, "Should successfully insert valid quote")
    }
    
    func testInsertMultipleQuotes() {
        let testQuotes = [
            ("Quote 1", "Author 1"),
            ("Quote 2", "Author 2"),
            ("Quote 3", "Author 3")
        ]
        
        for (text, author) in testQuotes {
            let success = databaseManager.insertQuote(text: text, author: author)
            XCTAssertTrue(success, "Should insert quote: \(text)")
        }
        
        let allQuotes = databaseManager.getAllQuotes()
        XCTAssertEqual(allQuotes.count, testQuotes.count, "Should have inserted all quotes")
    }
    
    func testInsertQuoteWithSpecialCharacters() {
        let specialText = "Quote with 'single quotes', \"double quotes\", and emojis 😊🎉"
        let specialAuthor = "Author O'Connor & Smith"
        
        let success = databaseManager.insertQuote(text: specialText, author: specialAuthor)
        XCTAssertTrue(success, "Should handle special characters")
        
        let quotes = databaseManager.getAllQuotes()
        XCTAssertEqual(quotes.first?.text, specialText, "Should preserve special characters in text")
        XCTAssertEqual(quotes.first?.author, specialAuthor, "Should preserve special characters in author")
    }
    
    func testInsertEmptyStrings() {
        // Test with empty strings (should still work technically, but might want to validate)
        let success = databaseManager.insertQuote(text: "", author: "")
        XCTAssertTrue(success, "Database should accept empty strings")
    }
    
    // MARK: - Get All Quotes Tests
    
    func testGetAllQuotesEmpty() {
        let quotes = databaseManager.getAllQuotes()
        XCTAssertTrue(quotes.isEmpty, "Should return empty array when no quotes exist")
    }
    
    func testGetAllQuotesOrder() {
        // Insert quotes with slight delays to ensure different timestamps
        let testData = [
            ("First quote", "First author"),
            ("Second quote", "Second author"),
            ("Third quote", "Third author")
        ]
        
        for (text, author) in testData {
            databaseManager.insertQuote(text: text, author: author)
            // Small delay to ensure different timestamps
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        let quotes = databaseManager.getAllQuotes()
        XCTAssertEqual(quotes.count, 3, "Should return all inserted quotes")
        
        // Should be ordered by date_created DESC (newest first)
        XCTAssertEqual(quotes[0].text, "Third quote", "Newest quote should be first")
        XCTAssertEqual(quotes[2].text, "First quote", "Oldest quote should be last")
    }
    
    func testGetAllQuotesDataIntegrity() {
        let originalText = "The only way to do great work is to love what you do."
        let originalAuthor = "Steve Jobs"
        
        databaseManager.insertQuote(text: originalText, author: originalAuthor)
        
        let quotes = databaseManager.getAllQuotes()
        let retrievedQuote = quotes.first!
        
        XCTAssertEqual(retrievedQuote.text, originalText, "Text should match")
        XCTAssertEqual(retrievedQuote.author, originalAuthor, "Author should match")
        XCTAssertGreaterThan(retrievedQuote.id, 0, "ID should be positive")
        XCTAssertNotNil(retrievedQuote.dateCreated, "Date should not be nil")
    }
    
    // MARK: - Get Random Quote Tests
    
    func testGetRandomQuoteEmpty() {
        let randomQuote = databaseManager.getRandomQuote()
        XCTAssertNil(randomQuote, "Should return nil when no quotes exist")
    }
    
    func testGetRandomQuoteSingle() {
        databaseManager.insertQuote(text: "Only quote", author: "Only author")
        
        let randomQuote = databaseManager.getRandomQuote()
        XCTAssertNotNil(randomQuote, "Should return the only quote")
        XCTAssertEqual(randomQuote?.text, "Only quote", "Should return the correct quote")
    }
    
    func testGetRandomQuoteMultiple() {
        // Insert multiple quotes
        for i in 1...5 {
            databaseManager.insertQuote(text: "Quote \(i)", author: "Author \(i)")
        }
        
        let randomQuote = databaseManager.getRandomQuote()
        XCTAssertNotNil(randomQuote, "Should return a random quote")
        
        // Test that we get different quotes (run multiple times)
        var quotesReturned = Set<String>()
        for _ in 1...20 {
            if let quote = databaseManager.getRandomQuote() {
                quotesReturned.insert(quote.text)
            }
        }
        
        // Should get some variety (not a strict test due to randomness)
        XCTAssertGreaterThan(quotesReturned.count, 1, "Should return different quotes over multiple calls")
    }
    
    // MARK: - Performance Tests
    
    func testInsertPerformance() {
        measure {
            for i in 1...100 {
                databaseManager.insertQuote(text: "Performance test quote \(i)", author: "Test Author \(i)")
            }
        }
    }
    
    func testGetAllQuotesPerformance() {
        // Insert test data
        for i in 1...100 {
            databaseManager.insertQuote(text: "Quote \(i)", author: "Author \(i)")
        }
        
        measure {
            let _ = databaseManager.getAllQuotes()
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testVeryLongText() {
        let longText = String(repeating: "A", count: 10000)
        let success = databaseManager.insertQuote(text: longText, author: "Long Text Author")
        XCTAssertTrue(success, "Should handle very long text")
        
        let quotes = databaseManager.getAllQuotes()
        XCTAssertEqual(quotes.first?.text, longText, "Should preserve long text")
    }
    
    func testUnicodeCharacters() {
        let unicodeText = "Café résumé naïve Zürich 北京 🌟"
        let unicodeAuthor = "François Müller 田中太郎"
        
        let success = databaseManager.insertQuote(text: unicodeText, author: unicodeAuthor)
        XCTAssertTrue(success, "Should handle Unicode characters")
        
        let quotes = databaseManager.getAllQuotes()
        XCTAssertEqual(quotes.first?.text, unicodeText, "Should preserve Unicode in text")
        XCTAssertEqual(quotes.first?.author, unicodeAuthor, "Should preserve Unicode in author")
    }
    
    // MARK: - Date Functionality Tests
    
    func testDateCreatedAccuracy() {
        let beforeInsert = Date()
        databaseManager.insertQuote(text: "Date test", author: "Date author")
        let afterInsert = Date()
        
        let quotes = databaseManager.getAllQuotes()
        let insertedDate = quotes.first!.dateCreated
        
        XCTAssertGreaterThanOrEqual(insertedDate, beforeInsert, "Date should be after or equal to before insert time")
        XCTAssertLessThanOrEqual(insertedDate, afterInsert, "Date should be before or equal to after insert time")
    }
    
    func testFormattedDate() {
        databaseManager.insertQuote(text: "Format test", author: "Format author")
        
        let quotes = databaseManager.getAllQuotes()
        let formattedDate = quotes.first!.formattedDate
        
        XCTAssertFalse(formattedDate.isEmpty, "Formatted date should not be empty")
        XCTAssertTrue(formattedDate.contains("2024") || formattedDate.contains("2025"), "Should contain current year")
    }
}

// MARK: - Test Helper Class

class TestDatabaseManager: DatabaseManager {
    private var testDb: OpaquePointer?
    private let testDbPath: String
    
    init(testPath: String) {
        self.testDbPath = testPath
        super.init()
        setupTestDatabase()
    }
    
    private func setupTestDatabase() {
        if sqlite3_open(testDbPath, &testDb) == SQLITE_OK {
            print("Test database opened successfully at \(testDbPath)")
            createTestTable()
        } else {
            print("Failed to open test database")
            if let errorPointer = sqlite3_errmsg(testDb) {
                let errorMessage = String(cString: errorPointer)
                print("SQLite error: \(errorMessage)")
            }
        }
    }
    
    private func createTestTable() {
        let createTableString = """
            CREATE TABLE IF NOT EXISTS quotes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            author TEXT NOT NULL,
            date_created REAL NOT NULL);
            """
        
        let result = sqlite3_exec(testDb, createTableString, nil, nil, nil)
        if result != SQLITE_OK {
            print("Failed to create table: \(result)")
        }
    }
    
    override func insertQuote(text: String, author: String) -> Bool {
        let insertString = "INSERT INTO quotes (text, author, date_created) VALUES (?, ?, ?)"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(testDb, insertString, -1, &statement, nil) == SQLITE_OK else {
            print("Failed to prepare insert statement")
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
        
        if stepResult == SQLITE_DONE {
            print("Successfully inserted: '\(text)' by '\(author)'")
            return true
        } else {
            print("Failed to insert quote. SQLite error: \(stepResult)")
            return false
        }
    }
    
    override func getAllQuotes() -> [Quote] {
        let queryString = "SELECT id, text, author, date_created FROM quotes ORDER BY date_created DESC"
        var statement: OpaquePointer?
        var quotes: [Quote] = []
        
        guard sqlite3_prepare_v2(testDb, queryString, -1, &statement, nil) == SQLITE_OK else {
            print("Failed to prepare select statement")
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
            
            print("Retrieved quote: '\(text)' by '\(author)'")
            quotes.append(Quote(id: Int(id), text: text, author: author, dateCreated: dateCreated))
        }
        
        sqlite3_finalize(statement)
        return quotes
    }
    
    override func getRandomQuote() -> Quote? {
        let queryString = "SELECT id, text, author, date_created FROM quotes ORDER BY RANDOM() LIMIT 1"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(testDb, queryString, -1, &statement, nil) == SQLITE_OK else {
            print("Failed to prepare random select statement")
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
    
    deinit {
        if testDb != nil {
            sqlite3_close(testDb)
        }
    }
}
