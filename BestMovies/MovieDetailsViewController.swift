//
//  MovieDetailsViewController.swift
//  BestMovies
//
//  Created by Daniel Merchasin on 06/09/2018
//  Copyright © 2018 Daniel Merchasin. All rights reserved.
//

import UIKit

// Screen 3 - Movie Details
class MovieDetailsViewController: UIViewController {
    
    var selectedMovie: Movie!
    
    @IBOutlet weak var imgThumbnail: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblReleaseYear: UILabel!
    @IBOutlet weak var lblRating: UILabel!
    @IBOutlet weak var lblGenre: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let theImage = selectedMovie.image {
            imgThumbnail.image = UIImage(data: theImage)
        } else {
            imgThumbnail.image = UIImage(named: "placeholder.png")
        }
        
        lblTitle.text = selectedMovie.title
        lblReleaseYear.text = "Release year: \(selectedMovie.releaseYear)"
        lblRating.text = "Rating: \(selectedMovie.rating)"
        lblGenre.text = "Genre: \(selectedMovie.genre.joined(separator: ", "))"
        
    }
    
    
}
