//
//  ARView.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/22/25.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    var waypoints: [Waypoint]
    var useGeoAnchors: Bool = false
    let origin = LocationManagerViewModel.shared.coordinate
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // AR session configuration
        if useGeoAnchors, ARGeoTrackingConfiguration.isSupported {
            let configuration = ARGeoTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            arView.session.run(configuration)
        } else {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            arView.session.run(configuration)
        }
        
        arView.debugOptions = [.showFeaturePoints]
        
        for waypoint in waypoints {
            let x = Float.random(in: -1...1)
            // let y = Float.random(in: 0...1)
            let z = Float.random(in: -1 ... -0.5)
            
            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.05))
            sphere.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
            
            // let anchorEntity: AnchorEntity
            // TODO: fix anchorEntity not displaying in AR view
             let anchorEntity = AnchorEntity(world: [x, 0, z])
            
            
//            if useGeoAnchors, ARGeoTrackingConfiguration.isSupported {
//                // Use ARGeoAnchor
//                let geoAnchor = ARGeoAnchor(__coordinate: waypoint.coordinate, altitude: 0)
//                arView.session.add(anchor: geoAnchor)
//                
//                anchorEntity = AnchorEntity()
//            } else {
//                // Use standard world anchor at relative position
//                let position = convertToARCoordinates(from: waypoint.coordinate, relativeTo: origin)
//                anchorEntity = AnchorEntity(world: position)
//            }
            
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
            
            anchorEntity.addChild(textEntity)
            anchorEntity.addChild(sphere)
            arView.scene.addAnchor(anchorEntity)
        }
        
        return arView
    }
    
    func convertToARCoordinates(from coord: CLLocationCoordinate2D, relativeTo origin: CLLocationCoordinate2D) -> SIMD3<Float> {
        // Placeholder for now — compute relative distance and bearing, then map to meters
        return [Float.random(in: -1...1), 0, Float.random(in: -1...1)]
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // You can update the ARView dynamically if needed
    }
}

struct ARViewScreen: View {
    var waypoints: [Waypoint]
    
    var body: some View {
        ARViewContainer(waypoints: waypoints)
            .edgesIgnoringSafeArea(.all)
    }
}
//
//#Preview {
//    ARViewScreen(waypoints: waypoints)
//}

