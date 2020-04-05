//
//  OverpassQuestManager.swift
//  OSMSurveyorFramework
//
//  Created by Wolfgang Timme on 05.04.20.
//  Copyright © 2020 Wolfgang Timme. All rights reserved.
//

import Foundation

final class OverpassQuestManager {
    // MARK: Private properties
    private let zoomForDownloadedTiles: Int
    private let downloadedQuestTypesManager: DownloadedQuestTypesManaging
    
    init(zoomForDownloadedTiles: Int,
         downloadedQuestTypesManager: DownloadedQuestTypesManaging) {
        self.zoomForDownloadedTiles = zoomForDownloadedTiles
        self.downloadedQuestTypesManager = downloadedQuestTypesManager
    }
}

extension OverpassQuestManager: QuestManaging {
    func updateQuests(in boundingBox: BoundingBox) {
        let tilesRect = boundingBox.enclosingTilesRect(zoom: zoomForDownloadedTiles)
        
        _ = downloadedQuestTypesManager.findDownloadedQuestTypes(in: tilesRect, ignoreOlderThan: Date())
    }
}
