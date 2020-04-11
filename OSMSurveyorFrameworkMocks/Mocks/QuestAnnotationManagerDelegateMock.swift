//
//  QuestAnnotationManagerDelegateMock.swift
//  OSMSurveyorFrameworkTests
//
//  Created by Wolfgang Timme on 07.04.20.
//  Copyright © 2020 Wolfgang Timme. All rights reserved.
//

import Foundation
@testable import OSMSurveyorFramework

final class QuestAnnotationManagerDelegateMock {
    private(set) var didCallSetAnnotations = false
    private(set) var annotations = [Annotation]()
}

extension QuestAnnotationManagerDelegateMock: QuestAnnotationManagerDelegate {
    func setAnnotations(_ annotations: [Annotation]) {
        didCallSetAnnotations = true
        
        self.annotations = annotations
    }
}
