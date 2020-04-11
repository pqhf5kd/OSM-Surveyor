//
//  OpenStreetMapAPIClientMock.swift
//  OSMSurveyorFrameworkMocks
//
//  Created by Wolfgang Timme on 11.04.20.
//  Copyright © 2020 Wolfgang Timme. All rights reserved.
//

import Foundation
@testable import OSMSurveyorFramework

final class OpenStreetMapAPIClientMock {
    private(set) var didCallUserDetails = false
    private(set) var userDetailsArguments: (token: String, tokenSecret: String, completion: (Result<UserDetails, Error>) -> Void)?
}

extension OpenStreetMapAPIClientMock: OpenStreetMapAPIClientProtocol {
    func userDetails(oAuthToken: String,
                     oAuthTokenSecret: String,
                     completion: @escaping (Result<UserDetails, Error>) -> Void) {
        didCallUserDetails = true
        
        userDetailsArguments = (oAuthToken, oAuthTokenSecret, completion)
    }
}
