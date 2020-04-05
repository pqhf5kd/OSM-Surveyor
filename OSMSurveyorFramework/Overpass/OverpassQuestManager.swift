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
    private let questProvider: OverpassQuestProviding
    private let queryExecutor: OverpassQueryExecuting
    private let zoomForDownloadedTiles: Int
    private let downloadedQuestTypesManager: DownloadedQuestTypesManaging
    private let questElementProcessor: QuestElementProcessing
    
    init(questProvider: OverpassQuestProviding,
         queryExecutor: OverpassQueryExecuting,
         zoomForDownloadedTiles: Int,
         downloadedQuestTypesManager: DownloadedQuestTypesManaging,
         questElementProcessor: QuestElementProcessing) {
        self.questProvider = questProvider
        self.queryExecutor = queryExecutor
        self.zoomForDownloadedTiles = zoomForDownloadedTiles
        self.downloadedQuestTypesManager = downloadedQuestTypesManager
        self.questElementProcessor = questElementProcessor
    }
}

extension OverpassQuestManager: QuestManaging {
    func updateQuests(in boundingBox: BoundingBox, ignoreDownloadedQuestsBefore date: Date) {
        let tilesRect = boundingBox.enclosingTilesRect(zoom: zoomForDownloadedTiles)
        
        let downloadedQuestTypes = downloadedQuestTypesManager.findDownloadedQuestTypes(in: tilesRect, ignoreOlderThan: date)
        
        let questsToDownload = questProvider.quests.filter { quest in
            return !downloadedQuestTypes.contains(quest.type)
        }
        
        for quest in questsToDownload {
            let query = quest.query(boundingBox: boundingBox)
            
            queryExecutor.execute(query: query) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case let .failure(error):
                    print("Failed to execute query: \(error.localizedDescription)")
                case let .success(elements):
                    self.questElementProcessor.processElements(elements,
                                                               in: boundingBox,
                                                               forQuestOfType: quest.type)
                }
            }
        }
    }
}
