//
//  KeychainHandlerTestCase.swift
//  OSMSurveyorFrameworkTests
//
//  Created by Wolfgang Timme on 12.04.20.
//  Copyright © 2020 Wolfgang Timme. All rights reserved.
//

import XCTest
@testable import OSMSurveyorFramework

class KeychainHandlerTestCase: XCTestCase {
    
    var handler: KeychainHandling!

    override func setUpWithError() throws {
        handler = KeychainHandler(service: "test")
    }

    override func tearDownWithError() throws {
        handler = nil
    }
    
    func testAdd_shouldInsertEntry() {
        let username = "jane.doe"
        let credentials = OAuth1Credentials(token: "lorem",
                                            tokenSecret: "ipsum")
        
        try? handler.add(username: username, credentials: credentials)
        
        XCTAssertEqual(handler.entries.first?.username, username)
        XCTAssertEqual(handler.entries.first?.credentials, credentials)
    }
    
    func testAdd_whenInsertingAUsernameThatAlreadyExists_shouldThrowCorrespondingError() {
        let username = "jane.doe"
        let credentials = OAuth1Credentials(token: "lorem", tokenSecret: "ipsum")
        
        /// Add the entry for the first time.
        try? handler.add(username: username, credentials: credentials)
        
        do {
            /// Add the entry for a second time.
            try handler.add(username: username, credentials: credentials)
            
            /// Adding an entry for a username that already exist should throw; execution should jump to `catch` clause and _not_ continue here.
            XCTFail()
        } catch {
            XCTAssertEqual(error as? KeychainError, KeychainError.usernameAlreadyExists)
        }
    }
    
    func testAdd_whenInsertingTheSameUsernameMultipleTimes_shouldResultInOnlyOneEntry() {
        for _ in 1...10 {
            let username = "jane.doe"
            let credentials = OAuth1Credentials(token: "lorem",
                                                tokenSecret: "ipsum")
            
            try? handler.add(username: username, credentials: credentials)
        }
        
        XCTAssertEqual(handler.entries.count, 1)
    }
    
    func testRemove_shouldRemoveTheItem() {
        let username = "jane.doe"
        let credentials = OAuth1Credentials(token: "lorem",
                                            tokenSecret: "ipsum")
        
        try? handler.add(username: username, credentials: credentials)
        
        handler.remove(username: username)
        
        let usernamesInKeychain = handler.entries.map { $0.username }
        XCTAssertFalse(usernamesInKeychain.contains(username))
    }

}
