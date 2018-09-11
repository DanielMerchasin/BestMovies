//
//  Movie.swift
//  BestMovies
//
//  Created by Daniel Merchasin on 06/09/2018
//  Copyright © 2018 Daniel Merchasin. All rights reserved.
//

import UIKit
import CoreData

// Movie data model
class Movie {
    
    var title: String
    var imageLocation: String?
    var image: Data?
    var rating: Float
    var releaseYear: Int
    var genre: [String]
    
    // Parse JSON
    convenience init(json: [String:Any]) throws {
        
        // Check if all required fields exist, throw an error if not
        guard let title = json["title"] as? String,
            let rating = json["rating"] as? Float,
            let releaseYear = json["releaseYear"] as? Int,
            let genre = json["genre"] as? [String] else {
            throw NSError(domain: "JSON Parse Error", code: 0, userInfo: nil)
        }
        
        self.init(title: title, rating: rating, releaseYear: releaseYear, genre: genre)
        imageLocation = json["image"] as? String
    }
    
    init(title: String, rating: Float, releaseYear: Int, genre: [String]) {
        self.title = title
        self.rating = rating
        self.releaseYear = releaseYear
        self.genre = genre
    }
    
}
