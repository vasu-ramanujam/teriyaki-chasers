//
//  ARView.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/22/25.
//

import SwiftUI
import UIKit
import RealityKit
import ARKit
import MapKit
import Photos

struct WaypointComponent: Component {
    var waypoint: Waypoint
}

struct ARViewContainer: UIViewRepresentable {
    var waypoints: [Waypoint]
    var useGeoAnchors: Bool = false
    let origin = LocationManagerViewModel.shared.coordinate
    var onError: ((String) -> Void)? = nil
    @Binding var selectedWaypoint: Waypoint?
    
    // MARK: Coordinator with custom tap function
    // act as delegates (object that responds to events) for UIKit view controllers
    // inherit from NSObject, can ask the object what functionality it supports at runtime
    class Coordinator: NSObject {
        var parent: ARViewContainer
        
        init(parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            let arView = sender.view as! ARView
            let location = sender.location(in: arView)
            
            if let hitEntity = arView.entity(at: location),
               let waypoint = hitEntity.components[WaypointComponent.self]?.waypoint {
                // Trigger SwiftUI state change
                parent.selectedWaypoint = waypoint
                // print("Tapped entity: \(hitEntity.name)")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // TODO: implement math needed to convert world coordinates to AR
    func convertToARCoordinates(from coord: CLLocationCoordinate2D, relativeTo origin: CLLocationCoordinate2D) -> SIMD3<Float> {
        // Placeholder for now — compute relative distance and bearing, then map to meters
        return [Float.random(in: -1...1), 0, Float.random(in: -1...1)]
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // You can update the ARView dynamically if needed
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration)
          
        // on tap, send event to the coordinator and call the handleTap method in coordinator
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        arView.debugOptions = [.showFeaturePoints]
        for waypoint in waypoints {
            let x = Float.random(in: -1...1)
            // let y = Float.random(in: 0...1)
            let z = Float.random(in: -1 ... -0.5)
            
            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.05))
            // generateCollisionShapes makes entities "physical"
            sphere.generateCollisionShapes(recursive: true)
            
            // arbitrary component value can be set here
            sphere.components.set(WaypointComponent(waypoint: waypoint))
            sphere.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
            sphere.name = waypoint.title
            
            let anchorEntity = AnchorEntity(world: [x, 0.1, z])
            //                // Use standard world anchor at relative position
            //                let position = convertToARCoordinates(from: waypoint.coordinate, relativeTo: origin)
            //                anchorEntity = AnchorEntity(world: position)
            
            // floating label
            let textMesh = MeshResource.generateText(
                waypoint.title,
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.05),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )
            let textEntity = ModelEntity(mesh: textMesh, materials: [SimpleMaterial(color: .white, isMetallic: false)])
            textEntity.position = [0, 0.1, 0]
            textEntity.generateCollisionShapes(recursive: true)
            
            anchorEntity.addChild(textEntity)
            anchorEntity.addChild(sphere)
            arView.scene.addAnchor(anchorEntity)
        }
        return arView
    }
}

struct ARViewScreen: View {
    @State private var selectedWaypoint: Waypoint? = nil
    var waypoints: [Waypoint]
    
    var body: some View {
        ZStack {
            ARViewContainer(waypoints: waypoints, selectedWaypoint: $selectedWaypoint)
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(true)
        }
        .sheet(item: $selectedWaypoint) { waypoint in
            switch waypoint {
            case .sighting(let sighting):
                SightingPinInformationView(
                    sighting: sighting,
                    origin: .map,
                    waypointObj: waypoint
                )

            case .hotspot(let hotspot):
                // You can show a different view for hotspots, or reuse the same one
                Text("Hotspot: \(hotspot.name)")
            }
        }
    }
}



//
//#Preview {
//    ARViewScreen(waypoints: waypoints)
//}


// MARK: makeUIView using real-world location
//    func makeUIView(context: Context) -> ARView {
//        let arView = ARView(frame: .zero)
//
//        // AR session configuration
//        // ARGeoTrackingConfiguration.checkAvailability
//        // TODO: change error handling if geotracking is not supported
//        if useGeoAnchors && !ARGeoTrackingConfiguration.isSupported {
//            print("AR GeoTracking not supported.")
//            DispatchQueue.main.async {
//                onError?("GeoTracking is not supported on this device.")
//            }
//            return arView // Return early to avoid crashing
//        }
//
//        let configuration = ARGeoTrackingConfiguration()
//        configuration.planeDetection = [.horizontal, .vertical]
//        arView.session.run(configuration)
//
//        arView.debugOptions = [.showFeaturePoints]
//        for waypoint in waypoints {
//            let x = Float.random(in: -1...1)
//            // let y = Float.random(in: 0...1)
//            let z = Float.random(in: -1 ... -0.5)
//
//            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.05))
//            sphere.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
//
//            // let anchorEntity: AnchorEntity
//            let anchorEntity = AnchorEntity(world: [x, 0.2, z])
//
//            // Use ARGeoAnchor
//            let geoAnchor = ARGeoAnchor(__coordinate: waypoint.coordinate, altitude: 0)
//            arView.session.add(anchor: geoAnchor)
//
//            // floating label
//            let textMesh = MeshResource.generateText(
//                waypoint.title,
//                extrusionDepth: 0.01,
//                font: .systemFont(ofSize: 0.05),
//                containerFrame: .zero,
//                alignment: .center,
//                lineBreakMode: .byWordWrapping
//            )
//            let textEntity = ModelEntity(mesh: textMesh, materials: [SimpleMaterial(color: .white, isMetallic: false)])
//            textEntity.position = [0, 0.1, 0]
//
//            anchorEntity.addChild(textEntity)
//            anchorEntity.addChild(sphere)
//            arView.scene.addAnchor(anchorEntity)
//        }
//
//        return arView
//    }
