//
//  MapDataDownloader.swift
//  OSMSurveyorFramework
//
//  Created by Wolfgang Timme on 01.04.20.
//  Copyright © 2020 Wolfgang Timme. All rights reserved.
//

import Foundation

public enum MapDataDownloadError: Error {
    case screenAreaTooLarge
}

public protocol MapDataDownloading {
    /// Downloads the quests in the given `BoundingBox`.
    /// - Parameters:
    ///   - boundingBox: The bounding box in which to download the quests.
    ///   - cameraPosition: The current camera position of the map. Will be used to calculate a larger bounding box in case the provided one is too small.
    ///   - ignoreDownloaded: Flag whether to ignore the tiles/areas that have already been downloaded, and forces the downloaded.
    func downloadQuests(in boundingBox: BoundingBox,
                        cameraPosition: CameraPosition,
                        ignoreDownloaded: Bool) throws
}

public final class MapDataDownloader {
    public static let shared: MapDataDownloader = {
        let downloadedQuestTypesManager = DownloadedTileDataHelper()
        let overpassQuestProvider = StaticOverpassQuestProvider()
        let overpassQueryExecutor = OverpassDownloader()
        let zoomForDownloadedTiles = 14
        let questElementProcessor = QuestElementProcessor(zoomForDownloadedTiles: zoomForDownloadedTiles,
                                                          downloadedQuestTypesManager: DownloadedTileDataHelper(),
                                                          questDataManager: QuestDataHelper(),
                                                          elementGeometryDataManager: ElementsGeometryDataHelper(),
                                                          nodeDataManager: NodeDataHelper())

        let questManager = OverpassQuestManager(questProvider: overpassQuestProvider,
                                                queryExecutor: overpassQueryExecutor,
                                                zoomForDownloadedTiles: zoomForDownloadedTiles,
                                                downloadedQuestTypesManager: downloadedQuestTypesManager,
                                                questElementProcessor: questElementProcessor)

        return MapDataDownloader(questManager: questManager)
    }()

    // MARK: Private properties

    private let questManager: QuestManaging
    private let questTileZoom: Int
    private let minimumDownloadableAreaInSquareKilometers: Double
    private let maximumDownloadableAreaInSquareKilometers: Double
    private let minimumDownloadRadiusInMeters: Double

    init(questManager: QuestManaging,
         questTileZoom: Int = 14,
         minimumDownloadableAreaInSquareKilometers: Double = 1,
         maximumDownloadableAreaInSquareKilometers: Double = 20,
         minimumDownloadRadiusInMeters: Double = 600)
    {
        self.questManager = questManager
        self.questTileZoom = questTileZoom
        self.minimumDownloadableAreaInSquareKilometers = minimumDownloadableAreaInSquareKilometers
        self.maximumDownloadableAreaInSquareKilometers = maximumDownloadableAreaInSquareKilometers
        self.minimumDownloadRadiusInMeters = minimumDownloadRadiusInMeters
    }
}

extension MapDataDownloader: MapDataDownloading {
    public func downloadQuests(in boundingBox: BoundingBox,
                               cameraPosition: CameraPosition,
                               ignoreDownloaded: Bool) throws
    {
        let boundingBoxOfEnclosingTiles = boundingBox.asBoundingBoxOfEnclosingTiles(zoom: 14)
        let areaInSquareKilometers = boundingBoxOfEnclosingTiles.enclosedAreaInSquareKilometers()

        guard areaInSquareKilometers <= maximumDownloadableAreaInSquareKilometers else {
            throw MapDataDownloadError.screenAreaTooLarge
        }

        let boundingBoxToDownload: BoundingBox
        if areaInSquareKilometers < minimumDownloadableAreaInSquareKilometers {
            boundingBoxToDownload = cameraPosition.center.enclosingBoundingBox(radius: minimumDownloadRadiusInMeters)
        } else {
            boundingBoxToDownload = boundingBoxOfEnclosingTiles
        }

        let ignoreDownloadedQuestsBefore: Date
        if ignoreDownloaded {
            ignoreDownloadedQuestsBefore = Date()
        } else {
            ignoreDownloadedQuestsBefore = Date(timeIntervalSinceNow: -60 * 60 * 24)
        }

        questManager.updateQuests(in: boundingBoxToDownload, ignoreDownloadedQuestsBefore: ignoreDownloadedQuestsBefore)
    }
}
