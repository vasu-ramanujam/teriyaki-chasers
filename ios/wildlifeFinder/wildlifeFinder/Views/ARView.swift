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
import Combine

struct WaypointComponent: Component {
    var waypoint: Waypoint
}

struct ARViewContainer: UIViewRepresentable {
    var waypoints: [Waypoint]
    var useGeoAnchors: Bool = false
    let origin = LocationManagerViewModel.shared.coordinate
    var onError: ((String) -> Void)? = nil
    var onReachedWaypoint: ((Waypoint) -> Void)? = nil
    
    // selectedWaypoint is for determining which info card to display, current is for current waypoint user is navigating to
    @Binding var selectedWaypoint: Waypoint?
    @Binding var currentWaypoint: Waypoint?
    @Binding var arrowRotation: Double
    
    // MARK: Coordinator with custom tap function
    // act as delegates (object that responds to events) for UIKit view controllers
    // inherit from NSObject, can ask the object what functionality it supports at runtime
    class Coordinator: NSObject {
        var parent: ARViewContainer
        // provides a way to cancel the subscription to AR scene (so it doesn't run even after exiting AR mode
        var updateCancellable: Cancellable?
        
        init(parent: ARViewContainer) {
            self.parent = parent
        }
        
        // destructor
        deinit {
            updateCancellable?.cancel()
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
        
        // Check if camera is near the currentWaypoint
        func isCameraNearEntity(_ arView: ARView, entity: Entity, threshold: Float = 0.5) -> Bool {
            guard let cameraTransform = arView.session.currentFrame?.camera.transform else {
                return false
            }
            let cameraPosition = SIMD3<Float>(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )
            
            let entityPosition = entity.position(relativeTo: nil)
            let distance = simd_distance(cameraPosition, entityPosition)
//            print("Distance to \(parent.currentWaypoint?.title ?? "none"): \(distance)")
            return distance < threshold
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
    
    // MARK: main function that updates states in AR View
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
            let x = Float.random(in: -1.5...1.5)
            // let y = Float.random(in: 0...1)
            let z = Float.random(in: -1.5 ... -0.5)
            
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
        
        // Subscribe to scene updates to check camera distance each frame
        context.coordinator.updateCancellable = arView.scene.subscribe(to: SceneEvents.Update.self) { event in
            guard let currentWaypoint = self.currentWaypoint else { return }
            
            // Find the entity corresponding to the current waypoint
            if let targetEntity = arView.scene.findEntity(named: currentWaypoint.title) {
                if context.coordinator.isCameraNearEntity(arView, entity: targetEntity, threshold: 0.5) {
                    // print("✅ Camera is near current waypoint: \(currentWaypoint.title)")
                    // Tell SwiftUI the waypoint was reached, set reachedWaypoint to current one
                    DispatchQueue.main.async {
                        self.onReachedWaypoint?(currentWaypoint)
                    }
                }
            }
            
            // compute the heading needed to get to the current waypoint in route
            if let cameraTransform = arView.session.currentFrame?.camera.transform,
               let targetEntity = arView.scene.findEntity(named: currentWaypoint.title) {

                // Camera position
                let cameraPosition = simd_make_float3(cameraTransform.columns.3)

                // Target position (in world coordinates)
                let targetPosition = targetEntity.position(relativeTo: nil)
                
                // forward vector
                let cameraForward = simd_normalize(-simd_make_float3(cameraTransform.columns.2))
                let toTarget = simd_normalize(targetPosition - cameraPosition)

//                // Vector from camera → target
//                let direction = simd_normalize(targetPosition - cameraPosition)
//                
//                let dx = direction.x
//                let dz = direction.z
                let angle = atan2(toTarget.x, toTarget.z) - atan2(cameraForward.x, cameraForward.z)
                let degrees = Double(angle * 180 / .pi)
                
                DispatchQueue.main.async {
                    // invert to match screen rotation
                    self.arrowRotation = -degrees
                }
            }
        }
        
        return arView
    }
}

struct ARViewScreen: View {
    @State private var selectedWaypoint: Waypoint? = nil
    @State private var currentWaypoint: Waypoint? = nil
    
    @State private var reachedWaypoint: Waypoint? = nil
    @State private var showPopup: Bool = false
    
    @State private var arrowRotation: Double = 0.0
    
    var waypoints: [Waypoint]
    
    var body: some View {
        ZStack {
            ARViewContainer(waypoints: waypoints,
                            onReachedWaypoint: { waypoint in
                                 reachedWaypoint = waypoint
                                 showPopup = true
                             },
                            selectedWaypoint: $selectedWaypoint,
                            currentWaypoint: $currentWaypoint,
                            arrowRotation: $arrowRotation)
                .onAppear {
                    // Only set once when screen appears
                    if currentWaypoint == nil {
                        currentWaypoint = waypoints.first
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(true)
            
                VStack {
                    Spacer()
                    Image(systemName: "location.north.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(arrowRotation))
                        .padding(.bottom, 180) // push above the popup + tab bar
                }
            
                // Popup overlay
                if showPopup {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            if let waypoint = reachedWaypoint {
                                Text("✅ Reached \(waypoint.title)")
                                    .font(.headline)
                            } else {
                                Text("🎉 All waypoints reached!")
                                    .font(.headline)
                            }
                            if let waypoint = reachedWaypoint,
                               let currentIndex = waypoints.firstIndex(of: waypoint),
                               currentIndex + 1 < waypoints.count {
                                Button("Next Waypoint") {
                                    // Move to next waypoint
                                    self.currentWaypoint = waypoints[currentIndex + 1]
                                    reachedWaypoint = nil
                                    showPopup = false
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.9))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            Button("Dismiss") {
                                reachedWaypoint = nil
                                showPopup = false
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground).opacity(0.95))
                                .shadow(radius: 5)
                        )
                        .padding(.bottom, 72)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(), value: showPopup)
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
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
