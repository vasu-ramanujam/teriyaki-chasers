//
//  PostViewModel.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 10/29/25.
//
import Foundation
import UIKit

@MainActor
public final class PostViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var audioURL: URL?
    @Published var caption: String = ""
    @Published var isPublic = false
    @Published var speciesId: Int?
    @Published var animal: Species?
    
    func identifySightings() async throws {
        
    }
}

