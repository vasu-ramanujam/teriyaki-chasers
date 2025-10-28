//
//  MockSpecies.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 10/28/25.
//
import Foundation

struct MockSpecies {
    static let apiSquirrel = APISpecies(
        id: 1, common_name: "American Red Squirrel", scientific_name: "T. hudsonicus", habitat: "North America", diet: "Omnivore", behavior: nil, description: "The American red squirrel is one of three species of tree squirrels currently classified in the genus Tamiasciurus, known as the pine squirrels. The American red squirrel is variously known as the pine squirrel or piney squirrel, North American red squirrel, chickaree, boomer, or simply red squirrel. The squirrel is a small, 200–250 g (7.1–8.8 oz), diurnal mammal that defends a year-round exclusive territory. It feeds primarily on the seeds of conifer cones, and is widely distributed across much of the United States and Canada wherever conifers are common, except in the southwestern United States, where it is replaced by the formerly conspecific southwestern red squirrel, and along the Pacific coast of the United States, where its cousin the Douglas squirrel is found instead.", other_sources: nil, created_at: "10/28/25"
    )
    
    static let squirrel = Species(
        id: 1, common_name: "American Red Squirrel", scientific_name: "T. hudsonicus", habitat: "North America", diet: "Omnivore", behavior: nil, description: "The American red squirrel is one of three species of tree squirrels currently classified in the genus Tamiasciurus, known as the pine squirrels. The American red squirrel is variously known as the pine squirrel or piney squirrel, North American red squirrel, chickaree, boomer, or simply red squirrel. The squirrel is a small, 200–250 g (7.1–8.8 oz), diurnal mammal that defends a year-round exclusive territory. It feeds primarily on the seeds of conifer cones, and is widely distributed across much of the United States and Canada wherever conifers are common, except in the southwestern United States, where it is replaced by the formerly conspecific southwestern red squirrel, and along the Pacific coast of the United States, where its cousin the Douglas squirrel is found instead.", other_sources: nil, created_at: Date()
    )
}
