//
//  PostViewModel.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 10/29/25.
//
import Foundation
import UIKit
import Observation

@MainActor
@Observable
public final class PostViewModel {
    var image: UIImage?
    var audioURL: URL?
    var caption: String = ""
    var isPublic = false
    var speciesId: Int?
    var animal: Species?
    var animalImgUrl: URL?
    
    func identifySightings() async throws {
        
    }
}

