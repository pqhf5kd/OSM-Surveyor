//
//  OverpassQuest.swift
//  OSMSurveyorFramework
//
//  Created by Wolfgang Timme on 05.04.20.
//  Copyright © 2020 Wolfgang Timme. All rights reserved.
//

import Foundation

/// A query for requesting OpenStreetMap data from the Overpass API
typealias OverpassQuery = String

protocol OverpassQuest {
    /// A string that references the quest (e. g. in the database)
    var type: String { get }
    
    /// The interaction that is possible with this quest.
    var interaction: QuestInteraction { get }
    
    /// Determines the query for downloading the quest's elements in the given `BoundingBox`
    /// - Parameter boundingBox: The bounding box for which to get the query.
    func query(boundingBox: BoundingBox) -> OverpassQuery
    
    /// The message to use as the changeset's comment when uploading the change to the server.
    var commitMessage: String { get }
}

extension OverpassQuest {
    var type: String {
        guard let className = String(describing: self).split(separator: ".").last else { return "" }
        
        return className.replacingOccurrences(of: "Quest", with: "")
    }
}
