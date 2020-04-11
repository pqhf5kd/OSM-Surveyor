//
//  AddAccountFlowCoordinator.swift
//  OSMSurveyor
//
//  Created by Wolfgang Timme on 11.04.20.
//  Copyright © 2020 Wolfgang Timme. All rights reserved.
//

import UIKit
import OSMSurveyorFramework

protocol AddAccountFlowCoordinatorProtocol {
    func start()
}

final class AddAccountFlowCoordinator {
    // MARK: Private properties
    
    private let navigationController: UINavigationController
    private let oAuthHandler: OAuthHandling
    
    // MARK: Initializer
    
    init(navigationController: UINavigationController,
         oAuthHandler: OAuthHandling) {
        self.navigationController = navigationController
        self.oAuthHandler = oAuthHandler
    }
}

extension AddAccountFlowCoordinator: AddAccountFlowCoordinatorProtocol {
    func start() {
    }
}