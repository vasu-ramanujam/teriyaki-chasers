//
//  ARDebug.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 11/19/25.
//

// uncomment to print debug messages
//            func debugAnchor(_ anchor: ARAnchor, index: Int) {
//                guard let arView = arView else { return }
//
//                let id = anchor.identifier.uuidString
//                let pos = anchor.transform.columns.3
//                let worldPos = simd_make_float3(pos.x, pos.y, pos.z)
//
//                var msg = "➕ Anchor #\(index) (\(type(of: anchor))) id=\(id)\n"
//
//                if let geo = anchor as? ARGeoAnchor {
//                    msg += String(format: "   GPS coord: lat %.6f, lon %.6f", geo.coordinate.latitude, geo.coordinate.longitude)
//                    if #available(iOS 15.0, *), let alt = geo.altitude {
//                        msg += String(format: ", alt %.2fm", alt)
//                    }
//                    if let wp = parent.waypoints.first(where: { $0.coordinate.latitude == geo.coordinate.latitude && $0.coordinate.longitude == geo.coordinate.longitude }) {
//                        msg += " (\(wp.title))"
//                    }
//                    msg += "\n"
//                }
//
//                msg += String(format: "   AR Position: x %.3f, y %.3f, z %.3f", worldPos.x, worldPos.y, worldPos.z)
//
//                if let camTransform = arView.session.currentFrame?.camera.transform {
//                    let camPos = simd_make_float3(camTransform.columns.3)
//                    let distance = simd_distance(worldPos, camPos)
//                    msg += String(format: " (distance to camera: %.2fm)", distance)
//                }
//
//                debug(msg)
//            }


// uncomment to print debug messages
//            func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
//                debug("⏱ Anchors added at device coordinate: lat:\(LocationManagerViewModel.shared.coordinate.latitude), lon:\(LocationManagerViewModel.shared.coordinate.longitude)")
//
//                for (i, anchor) in anchors.enumerated() {
//                    debugAnchor(anchor, index: i+1)
//                }
//            }
