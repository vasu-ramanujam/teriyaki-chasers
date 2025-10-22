//
//  SightingPinInformationViewModel.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/21/25.
//
/*
 Instantiates a new information view model every time the info pin is called
 
 gets the information
 
 */

import Foundation
import SwiftUI

@MainActor
public class SightingPinInformationViewModel: ObservableObject {
    
    @Published var currentSighting: Sighting
    @Published var origin: where_from
    
    init(s: Sighting, o: where_from) {
        self.currentSighting = s
        self.origin = o
    }
    
    // call function to get description
    @Published var description = "Sample description. Replace with call to wherever owen puts the compile description thing. \n\n Learn more at whatever.com"
    
    // call API to get image and sound URLs if they exist
    @Published var image_url: String? = "Caribbean_Flamingo"
    @Published var sound_url: String? = nil
    
    
    
    
}
