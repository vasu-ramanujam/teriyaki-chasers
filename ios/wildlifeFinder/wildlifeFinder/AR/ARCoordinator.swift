//
//  ARCoordinator.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 11/19/25.
//

import Foundation
import ARKit
import RealityKit
import MapKit
import Combine
import UIKit

// MARK: - Coordinator
class Coordinator: NSObject, ARSessionDelegate {
    let parent: ARViewContainer
    weak var arView: ARView?
    var updateCancellable: Cancellable?
    var hasLocalized = false
    // var skipLocalization = true
    var anchorsAdded = false
    var lastBreadcrumbWaypointID: String? = nil
    
    init(parent: ARViewContainer) {
        self.parent = parent
    }
    
    deinit {
        updateCancellable?.cancel()
    }
    
    func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus) {
        ARGeoTrackingConfiguration.checkAvailability { available, error in
            print("GeoTracking available at this location:", available)
            if let err = error {
                print("Error reason:", err.localizedDescription)
            }
        }
        
        print("GeoTracking isSupported:", ARGeoTrackingConfiguration.isSupported)
        
        let message: String
        
        switch geoTrackingStatus.state {
        case .notAvailable:
            message = "AR Geo Tracking is unavailable."
        case .initializing:
            message = "Initializing… Move your phone slowly."
        case .localizing:
            message = "Localizing… Point the camera at buildings or landmarks."
        case .localized:
            message = "Localized! Placing waypoints…"
        @unknown default:
            message = "Unknown tracking state."
        }
        
        print(message)
         DispatchQueue.main.async { self.parent.onTrackingStatusChanged?(message) } // uncomment to print debug messages
        
        switch geoTrackingStatus.state {
        case .localized:
            if !anchorsAdded {
                anchorsAdded = true
                if let arView = arView {
                    parent.addAnchors(to: session, in: arView)
                    DispatchQueue.main.async {
                        self.parent.anchorsPlaced = true
                    }
                }
            } else {
                // debug("GeoTracking state: \(geoTrackingStatus.state)") // uncomment to print debug messages
            }
        default:
            print("GeoTracking status: \(geoTrackingStatus.state)")
        }
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let arView = sender.view as? ARView else { return }
        let location = sender.location(in: arView)
        
        // Get the tapped entity
        if let tappedEntity = arView.entity(at: location) {
            // Traverse up to find an entity with WaypointComponent
            var entity: Entity? = tappedEntity
            while entity != nil {
                if let waypointComp = entity!.components[WaypointComponent.self] {
                    parent.selectedWaypoint = waypointComp.waypoint
                    return
                }
                entity = entity?.parent
            }
        }
    }
    
    func removeAnchor(for waypoint: Waypoint) {
        guard arView != nil else { return }
        
        if let anchor = parent.waypointAnchors[waypoint.id] {
            anchor.removeFromParent()
            parent.waypointAnchors.removeValue(forKey: waypoint.id)
            print("Removed AR anchor for \(waypoint.title)")
        }
    }
    
//    func spawnBreadcrumbs(along polyline: MKPolyline, relativeTo origin: CLLocationCoordinate2D) {
//        guard let arView = arView else { return }
//        
//        // Avoid duplicate container
//        if let existing = arView.scene.findEntity(named: "breadcrumbs") {
//            existing.removeFromParent()
//        }
//        
//        // Get evenly spaced coordinates every 0.5 meters
//        let breadcrumbCoords = polyline.evenlySpacedCoordinates(every: 0.5)
//        guard !breadcrumbCoords.isEmpty else { return }
//        
//        debug("Spawning breadcrumbs for polyline with \(polyline.pointCount) points")
//        
//        let container = AnchorEntity()  // no need to convert coordinates
//        container.name = "breadcrumbs"
//        
//        // Spawn a sphere at each coordinate
//        for coord in breadcrumbCoords {
//            let geoAnchor = ARGeoAnchor(coordinate: coord)
//            let anchorEntity = AnchorEntity(anchor: geoAnchor)
//            
//            let sphere = ModelEntity(
//                mesh: MeshResource.generateSphere(radius: 0.15),
//                materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
//            )
//            sphere.position = [0, 0.5, 0]
//            sphere.collision = nil
//            anchorEntity.addChild(sphere)
//            container.addChild(anchorEntity)
//        }
//        
//        arView.scene.addAnchor(container)
//    }
    
    // uncomment to print debug messages
    func debug(_ message: String) {
        DispatchQueue.main.async {
            self.parent.onDebugMessage?(message)
        }
    }
}
