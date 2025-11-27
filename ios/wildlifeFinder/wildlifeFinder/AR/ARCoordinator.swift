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
    // Track breadcrumb entities to clean them up later
    var breadcrumbAnchorEntity: AnchorEntity?
    var breadcrumbGeoAnchor: ARGeoAnchor?
    var waypointAnchors: [String: AnchorEntity] = [:]
    // For performance: "cache" the last synced waypoints
    private var lastSyncedWaypointIDs: Set<String> = []
    
    
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
            message = "Localizing… Point the camera at buildings or the road."
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
                    if arView != nil {
                        self.syncWaypoints()
                        Task { @MainActor in
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
                    self.parent.selectedWaypoint = waypointComp.waypoint
                    return
                }
                entity = entity?.parent
            }
        }
    }
    
    
    func syncWaypoints() {
        guard let arView = arView else { return }
        
        let currentIDs = Set(parent.waypoints.map { $0.id })
        
        // use lastSyncedWaypoints if nothing changed in waypoints (no add/delete)
        if currentIDs == lastSyncedWaypointIDs {
            return
        }
        lastSyncedWaypointIDs = currentIDs
        
        for (id, anchor) in waypointAnchors {
            if !currentIDs.contains(id) {
                anchor.removeFromParent()
                waypointAnchors.removeValue(forKey: id)
                 print("Removed AR anchor for ID: \(id)")
            }
        }
        
        for waypoint in parent.waypoints {
            // Only add if we don't already have an anchor for this ID
            if waypointAnchors[waypoint.id] == nil {
                addAnchor(for: waypoint, in: arView)
            }
        }
    }
    
    
    func addAnchor(for waypoint: Waypoint, in arView: ARView) {
        let geoAnchor = ARGeoAnchor(coordinate: waypoint.coordinate)
        arView.session.add(anchor: geoAnchor)

        let anchorEntity = AnchorEntity(anchor: geoAnchor)
        
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.25))
        sphere.position = [0, 0.7, 0]
        // sphere.generateCollisionShapes(recursive: true)
        sphere.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
        sphere.components.set(WaypointComponent(waypoint: waypoint))
        sphere.name = waypoint.title
        
        sphere.components.set(InputTargetComponent(allowedInputTypes: .direct))
        sphere.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.25)]))

        // Floating text label
        let textMesh = MeshResource.generateText(
            waypoint.title,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.08)
        )
        let textEntity = ModelEntity(mesh: textMesh, materials: [SimpleMaterial(color: .white, isMetallic: false)])
        textEntity.position = [0, 1, 0]
        // textEntity.generateCollisionShapes(recursive: true)
        textEntity.components.set(InputTargetComponent(allowedInputTypes: .direct))
        textEntity.components.set(CollisionComponent(shapes: [.generateBox(size: [0.2, 0.1, 0.01])]))

        anchorEntity.addChild(textEntity)
        anchorEntity.addChild(sphere)

        // Save to property instead of local variable
        self.waypointAnchors[waypoint.id] = anchorEntity
        arView.scene.addAnchor(anchorEntity)
    }
    
    
    func removeAnchor(for waypoint: Waypoint) {
        guard arView != nil else { return }
        
        if let anchor = self.waypointAnchors[waypoint.id] {
            anchor.removeFromParent()
            self.waypointAnchors.removeValue(forKey: waypoint.id)
            print("Removed AR anchor for \(waypoint.title)")
        }
    }
    
    // MARK: - Breadcrumbs Logic
    func spawnBreadcrumbs(along polyline: MKPolyline) {
        guard let arView = arView,
              let startCoord = polyline.coords.first else { return }
        
        // Cleanup existing crumbs if any
        removeBreadcrumbs()
        
        // Create ONE GeoAnchor at the start of the route
        // This acts as the "World Origin" for our breadcrumbs
        let geoAnchor = ARGeoAnchor(coordinate: startCoord)
        arView.session.add(anchor: geoAnchor)
        self.breadcrumbGeoAnchor = geoAnchor
        
        let rootEntity = AnchorEntity(anchor: geoAnchor)
        self.breadcrumbAnchorEntity = rootEntity
        
        // Calculate Points relative to that start anchor
        // We use a Task to avoid freezing the UI during math calculations
        Task {
            // Get points every 1.5 meters (adjust as needed for density)
            // 0.5m might be too dense visually; 1.5m to 2.0m is usually better for walking
            let breadcrumbCoords = polyline.evenlySpacedCoordinates(every: 1.5)
            
            var sphereEntities: [ModelEntity] = []
            
            // Create reusable assets (Optimization)
            let mesh = MeshResource.generateSphere(radius: 0.15)
            let material = SimpleMaterial(color: .cyan.withAlphaComponent(0.8), isMetallic: false)
            
            for coord in breadcrumbCoords {
                // Calculate distance and bearing from the Start Anchor
                let distance = startCoord.distance(to: coord)
                let bearing = startCoord.bearing(to: coord)
                
                // Convert Polar coordinates (Dist/Angle) to Cartesian (X/Z)
                // ARKit Coordinate System:
                // +X = East
                // -Z = North
                // +Y = Up
                let bearingRadians = bearing.degreesToRadians
                let x = Float(distance * sin(bearingRadians))
                let z = Float(-1 * distance * cos(bearingRadians))
                
                let sphere = ModelEntity(mesh: mesh, materials: [material])
                
                // Position relative to the root anchor
                sphere.position = [x, 0.5, z]
                
                // Optional: Make it non-collidable to save physics calculation
                sphere.collision = nil
                
                sphereEntities.append(sphere)
            }
            
            // Add to Scene on Main Actor
            await MainActor.run {
                // Double check root still exists (user might have quit while calculating)
                guard let root = self.breadcrumbAnchorEntity else { return }
                
                for sphere in sphereEntities {
                    root.addChild(sphere)
                }
                
                arView.scene.addAnchor(root)
                print("Added \(sphereEntities.count) breadcrumbs to AR Scene.")
            }
        }
    }
    
    func removeBreadcrumbs() {
        // Remove the visual entity
        breadcrumbAnchorEntity?.removeFromParent()
        breadcrumbAnchorEntity = nil
        
        // Remove the tracking anchor
        if let anchor = breadcrumbGeoAnchor {
            arView?.session.remove(anchor: anchor)
            breadcrumbGeoAnchor = nil
        }
    }
    
    
    func monitorScene() {
        guard let arView = arView else { return }
                
            // Cancel existing subscription to avoid duplicates
            updateCancellable?.cancel()
            
            updateCancellable = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                guard let self = self else { return }
                self.updateNavigationState()
        }
    }
    
    
    private func updateNavigationState() {
        // Access the current waypoint data via parent
        guard let currentWaypoint = parent.currentWaypoint else { return }

        let deviceLocation = LocationManagerViewModel.shared.coordinate
        let targetLocation = currentWaypoint.coordinate
        let heading = LocationManagerViewModel.shared.heading
        
        // Update Arrow Rotation
        var finalRotation: Double? = nil
            if let validHeading = heading {
                let bearingToTarget = deviceLocation.bearing(to: targetLocation)
                finalRotation = bearingToTarget - validHeading
            }
        
        // Check distance between current location and current waypoint
        let loc1 = CLLocation(latitude: deviceLocation.latitude, longitude: deviceLocation.longitude)
        let loc2 = CLLocation(latitude: targetLocation.latitude, longitude: targetLocation.longitude)
        let distance = loc1.distance(from: loc2)
        
        Task { @MainActor in
            // Update Arrow if we calculated valid rotation
            if let rotation = finalRotation {
                self.parent.arrowRotation = rotation
            }
            // Update Reached State
            if distance <= 3.0 {
                self.parent.onReachedWaypoint?(currentWaypoint)
            }
        }
    }
    
    
    // uncomment to print debug messages
    func debug(_ message: String) {
        Task { @MainActor in
            self.parent.onDebugMessage?(message)
        }
    }
}
