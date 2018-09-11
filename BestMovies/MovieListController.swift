//
//  MovieListController.swift
//  BestMovies
//
//  Created by Daniel Merchasin on 06/09/2018
//  Copyright © 2018 Daniel Merchasin. All rights reserved.
//

import UIKit

// Identifiers
let movieCellSegueIdentifier = "MovieCellSegue"
let showMovieDetailsSegueIdentifier = "ShowMovieDetailsSegueIdentifier"
let unwindIdentifier = "UnwindToMovieList"

// Table view cell model
class MovieTableViewCell: UITableViewCell {
    
    static let identifier = "MovieCell"
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblReleaseYear: UILabel!
    @IBOutlet weak var imgThumbnail: UIImageView!
    
}

// Screen 2 - Movie List
class MovieListController: UITableViewController, MovieManagerDelegate {

    var movies: [Movie]!
    var movieManager: MovieManager!
    var addedMovie: Movie?
    
    @IBOutlet var tblMovies: UITableView!
    @IBOutlet weak var btnAdd: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        movieManager = MovieManager()
        movieManager.delegate = self
        
        // Load all movies from CoreData to the table view
        movieManager.readArrayFromCoreData()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    private func enableUI(_ enable: Bool) {
        tblMovies.isUserInteractionEnabled = enable
        btnAdd.isEnabled = enable
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MovieTableViewCell.identifier, for: indexPath) as! MovieTableViewCell
        
        let movie = movies[indexPath.row]
        
        if let imageData = movie.image {
            cell.imgThumbnail.image = UIImage(data: imageData)
        } else {
            cell.imgThumbnail.image = UIImage(named: "placeholder.png")
        }

        cell.lblTitle.text = movie.title
        cell.lblReleaseYear.text = "Release Year: \(movie.releaseYear)"
        
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == movieCellSegueIdentifier {
            let selectedIndex = tblMovies.indexPathForSelectedRow!.row
            let destVC = segue.destination as! MovieDetailsViewController
            destVC.selectedMovie = movies[selectedIndex]
        } else if segue.identifier == showMovieDetailsSegueIdentifier, let addedMovie = self.addedMovie {
            let destVC = segue.destination as! MovieDetailsViewController
            destVC.selectedMovie = addedMovie
        }
    }
    
    // This function is called when unwinding from QRScannerViewController or MovieDetailsViewController.
    @IBAction func unwindToMovieListController(for unwindSegue: UIStoryboardSegue) {
        guard unwindSegue.identifier == unwindIdentifier else { return }
        
        if let sourceVC = unwindSegue.source as? QRScannerViewController, let result = sourceVC.result, let url = URL(string: result) {
            // Treat the returned QR code string as a URL of a movie JSON.
            // Parse the JSON, saves it in CodeData, reload the movie list and launch MovieDetailsViewController with the new movie.
            enableUI(false)
            movieManager.readMovieFromURL(url)
        } else if (unwindSegue.source as? MovieDetailsViewController) != nil {
            // Remove the addedMovie reference because it's not needed anymore
            addedMovie = nil
        }
        
    }
    
    // MARK: - Movie Manager Delegate
    
    // Handle loaded movies from web
    func movieManager(_ movieManager: MovieManager, didFinishReadingFromURL url: URL, movies: [Movie]?, withError error: Error?) {
        enableUI(true)
        
        guard let theMovies = movies, let movie = theMovies.first, error == nil else {
            displayAlert(title: "Error", message: "Failed to load the movies. Please try again.")
            return
        }
        
        do {
            try movieManager.writeMovieToCoreData(movie)
        } catch {
            displayAlert(title: "Error", message: "Failed to save the movie data on the device.")
            return
        }
        
        // Reload the movies from CoreData and sort them by release year
        movieManager.readArrayFromCoreData()
        
        // After the table view is loaded, keep a reference to the added movie and launch the movie details VC
        addedMovie = movie
        performSegue(withIdentifier: showMovieDetailsSegueIdentifier, sender: self)
        
    }
    
    // Handle loaded movies from CoreData
    func movieManager(_ movieManager: MovieManager, didFinishReadingFromCoreData movies: [Movie]?) {
        
        guard let theMovies = movies else {
            self.movies = [Movie]()
            displayAlert(title: "Error", message: "Failed to load the movies.")
            return
        }
        
        self.movies = theMovies
        self.tblMovies.reloadData()
    }
    
}
