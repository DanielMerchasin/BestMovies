//
//  SplashScreenViewController.swift
//  BestMovies
//
//  Created by Daniel Merchasin on 06/09/2018
//  Copyright © 2018 Daniel Merchasin. All rights reserved.
//

import UIKit

// Identifier
let showNavControllerSegueIdentifier = "showNavController"

// Screen 1 - Splash Screen
class SplashScreenViewController: UIViewController, MovieManagerDelegate {
    
    var movieManager: MovieManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        movieManager = MovieManager()
        movieManager.delegate = self
        
        // Delete all records - currently used for debugging
//        do {
//            try movieManager.deleteAllCoreData()
//            print("All records deleted")
//        } catch {
//            print("Failed to delete CoreData records")
//        }
//
        // Load all movies and launch MovieListViewController when loading is done
        movieManager.readAllMoviesFromWeb()
    }
    
    // Move from the splash screen to the root navigation controller VC
    private func showNavController() {
        performSegue(withIdentifier: showNavControllerSegueIdentifier, sender: self)
    }

    func movieManager(_ movieManager: MovieManager, didFinishReadingFromURL url: URL, movies: [Movie]?, withError error: Error?) {
        guard let theMovies = movies, error == nil else {
            self.displayAlert(title: "Error", message: "Failed to load the movies. Please try again.") { [weak self]_ in
                // Launch the next VC anyway, so the user can still use the app offline
                self?.showNavController()
            }
            return
        }
        
        do {
            try movieManager.writeArrayToCoreData(movies: theMovies)
        } catch {
            // Ignore this error
            print("Failed to write movies to CoreData")
        }
        
        showNavController()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
