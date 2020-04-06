//
//  MapViewController.swift
//  OSMSurveyor
//
//  Created by Wolfgang Timme on 3/22/20.
//  Copyright © 2020 Wolfgang Timme. All rights reserved.
//

import UIKit
import TangramMap
import OSMSurveyorFramework
import SafariServices

class MapViewController: UIViewController {
    
    @IBOutlet private var mapView: TGMapView!
    @IBOutlet private var errorLabel: UILabel!
    private let questDownloader: MapViewQuestDownloading = MapViewQuestDownloader.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        
        testDatabaseIntegration()
        configureMap()
    }
    
    private func configureMap() {
        guard let apiKey = nextzenApiKey else {
            assertionFailure("Unable to load map: Missing API key for Nextzen")
            return
        }
        
        guard let sceneURL = Bundle.main.url(forResource: "scene", withExtension: "yaml") else {
            /// Unable to get the scene.
            return
        }
        
        mapView.mapViewDelegate = self
        mapView.loadScene(from: sceneURL, with: [TGSceneUpdate(path: "global.api_key", value: apiKey)])
    }
    
    private func testDatabaseIntegration() {
        guard let database = QuestDatabase(filename: "db.sqlite3") else {
            print("Unable to get the database")
            return
        }
        
        print("\(database)")
    }
    
    private var nextzenApiKey: String? {
        guard
            let secretsPlistPath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let secretsAsDictionary = NSDictionary(contentsOfFile: secretsPlistPath)
        else {
            assertionFailure("Unable to read the property list")
            return nil
        }
        
        return secretsAsDictionary.object(forKey: "Nextzen API Key") as? String
    }

    @IBAction private func showOpenStreetMapCopyrightAndLicensePage() {
        guard let url = URL(string: "https://www.openstreetmap.org/copyright") else { return }
        
        let viewController = SFSafariViewController(url: url)
        viewController.modalPresentationStyle = .pageSheet
        present(viewController, animated: true)
    }
    
    @IBAction private func didTapDownloadQuestsButton(_ sender: AnyObject) {
        guard let boundingBox = screenAreaToBoundingBox() else {
            updateErrorLabel("Can’t scan here. Try to zoom in further or tilt the map less.")
            return
        }
        
        do {
            try questDownloader.downloadQuests(in: boundingBox, cameraPosition: cameraPosition)
            
            print("All good. Would've downloaded now.")
            updateErrorLabel(nil)
        } catch MapViewQuestDownloadError.screenAreaTooLarge {
            updateErrorLabel("Please zoom in further")
        } catch {
            assertionFailure("Unexpected error: \(error.localizedDescription)")
            
            updateErrorLabel("Unexpected error")
        }
    }
}

extension MapViewController: TGMapViewDelegate {
    func mapView(_ mapView: TGMapView, didLoadScene sceneID: Int32, withError sceneError: Error?) {
        let coordinate = CLLocationCoordinate2D(latitude: 53.55439, longitude: 9.99413)
        let cameraPosition = TGCameraPosition(center: coordinate,
                                              zoom: 16,
                                              bearing: 0,
                                              pitch: TGRadiansFromDegrees(-15))!
        mapView.fly(to: cameraPosition, withDuration: 1, callback: nil)
        
        let marker = mapView.markerAdd()
        let pointDiameter = 16
        marker.stylingString = "{ style: 'points', color: 'lightgray', outline: { width: 2px, color: 'black' }, size: [\(pointDiameter)px, \(pointDiameter)px], order: 2000, collide: false }"
        marker.point = coordinate
    }
    
    private func updateErrorLabel(_ text: String?) {
        errorLabel.text = text
        errorLabel.isHidden = text?.isEmpty ?? true
    }
    
    private var cameraPosition: CameraPosition {
        let tangramCameraPosition = mapView.cameraPosition
        
        return CameraPosition(center: Coordinate(latitude: tangramCameraPosition.center.latitude,
                                                 longitude: tangramCameraPosition.center.longitude),
                              zoom: Double(tangramCameraPosition.zoom),
                              bearing: tangramCameraPosition.bearing,
                              pitch: Double(tangramCameraPosition.pitch))
    }
    
    struct Padding {
        let left: CGFloat
        let top: CGFloat
        let right: CGFloat
        let bottom: CGFloat
        
        static var zero: Padding {
            return Padding(left: 0, top: 0, right: 0, bottom: 0)
        }
    }
    
    private func screenAreaToBoundingBox(padding: Padding = .zero) -> BoundingBox? {
        let width = mapView.bounds.width
        let height = mapView.bounds.height
        
        guard width > 0, height > 0 else { return nil }
        
        let size = (width: width - padding.left - padding.right,
                    height: height - padding.top - padding.bottom)

        /**
          the special cases here are: map tilt and map rotation:
          * map tilt makes the screen area -> world map area into a trapezoid
          * map rotation makes the screen area -> world map area into a rotated rectangle
          dealing with tilt: this method is just not defined if the tilt is above a certain limit
         */
        guard cameraPosition.pitch <= .pi / 4 else {
            // 45°
            return nil
        }
        
        let positions = [
            mapView.coordinate(fromViewPosition: CGPoint(x: padding.left, y: padding.top)),
            mapView.coordinate(fromViewPosition: CGPoint(x: padding.left + size.width, y: padding.top)),
            mapView.coordinate(fromViewPosition: CGPoint(x: padding.left, y: padding.top + size.height)),
            mapView.coordinate(fromViewPosition: CGPoint(x: padding.left +  size.width, y: padding.top + size.height))
        ]
        
        let positionsAsCoordinates = positions.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
        
        return positionsAsCoordinates.enclosingBoundingBox
    }
}

extension MapViewController: MapViewControllerProtocol {
    func fly(to position: CameraPosition, duration: TimeInterval) {
        let center = CLLocationCoordinate2D(latitude: position.center.latitude,
                                            longitude: position.center.longitude)
        
        guard
            let cameraPosition = TGCameraPosition(center: center,
                                                  zoom: CGFloat(position.zoom),
                                                  bearing: position.bearing,
                                                  pitch: CGFloat(position.pitch))
            else {
            return
        }
        
        mapView.fly(to: cameraPosition, withDuration: duration, callback: nil)
    }
}
