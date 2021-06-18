//
//  AppDataStructs.swift
//  CyrusLinks
//
//  Created by Aaron Krauss on 6/18/21.
//
import Foundation

struct AppLink {
    var name: String;
    var url: String;
}

struct AppSubCategory {
    var name: String;
    var links: [AppLink];
}

struct AppCategory: Identifiable {
    let id = UUID();
    var name: String;
    var subCategories: [AppSubCategory];
}
