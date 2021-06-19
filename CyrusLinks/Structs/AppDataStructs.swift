//
//  AppDataStructs.swift
//  CyrusLinks
//
//  Created by Aaron Krauss on 6/18/21.
//
import Foundation

struct AppLink: Identifiable, Codable {
    var id = UUID();
    var name: String;
    var url: String;
    var lyrics: String;
}

struct AppSubCategory: Identifiable, Codable {
    var id = UUID();
    var name: String;
    var links: [AppLink];
}

struct AppCategory: Identifiable, Codable {
    var id = UUID();
    var name: String;
    var subCategories: [AppSubCategory];
}
