//
//  MovieManager.swift
//  BestMovies
//
//  Created by Daniel Merchasin on 06/09/2018
//  Copyright © 2018 Daniel Merchasin. All rights reserved.
//

import UIKit
import CoreData

// Delegate
protocol MovieManagerDelegate {
    func movieManager(_ movieManager: MovieManager, didFinishReadingFromCoreData movies: [Movie]?)
    func movieManager(_ movieManager: MovieManager, didFinishReadingFromURL url: URL, movies: [Movie]?, withError error: Error?)
}

// Optional delegate functions - using extension instead of @objc
extension MovieManagerDelegate {
    func movieManager(_ movieManager: MovieManager, didFinishReadingFromCoreData movies: [Movie]?) {}
    func movieManager(_ movieManager: MovieManager, didFinishReadingFromURL url: URL, movies: [Movie]?, withError error: Error?) {}
}

// Movies URL
let moviesJsonUrl = "https://api.androidhive.info/json/movies.json"

// MovieManager handles various operations related to reading and writing movie data.
// e.g. loading the data from a URL, parsing JSON, writing to CoreData, etc.
// The result of the operations will be passed to a handler provided when calling the function.
// If no handler is provided, the result will be passed to the delegate.
class MovieManager {
    
    var delegate: MovieManagerDelegate?
    
    func readArrayFromJSON(_ json: Data) throws -> [Movie] {
        
        let movies = try JSONSerialization.jsonObject(with: json, options: .allowFragments) as! [[String:Any]]
        
        var result = [Movie]()
        
        for m in movies {
            result.append(try Movie(json: m))
        }
        
        return result
    }
    
    func readArrayFromCoreData(handler: (([Movie]?) -> ())? = nil) {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Movies")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "releaseYear", ascending: false)]
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            if let fetchResults = try context.fetch(fetchRequest) as? [NSManagedObject] {
                
                var result = [Movie]()
                
                for m in fetchResults {
                    
                    let movie = Movie(title: m.value(forKey: "title") as! String,
                                      rating: m.value(forKey: "rating") as! Float,
                                      releaseYear: m.value(forKey: "releaseYear") as! Int,
                                      genre: (m.value(forKey: "genre") as! String).components(separatedBy: ","))
                    movie.image = m.value(forKey: "image") as? Data
                    
                    result.append(movie)
                }
                
                // Pass result
                if let theHandler = handler {
                    theHandler(result)
                } else {
                    delegate?.movieManager(self, didFinishReadingFromCoreData: result)
                }
                
                return
            }
        } catch {/* Ignore this error, all errors are handled in the handler/delegate call below */}
        
        if let theHandler = handler {
            theHandler(nil)
        } else {
            delegate?.movieManager(self, didFinishReadingFromCoreData: nil)
        }
        
    }
    
    // Delete all CoreData records, used for debugging only at this stage
    func deleteAllCoreData() throws {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Movies")
        fetchRequest.returnsObjectsAsFaults = false
        let results = try context.fetch(fetchRequest)
        for object in results {
            guard let data = object as? NSManagedObject else { continue }
            context.delete(data)
        }
    }
    
    func writeArrayToCoreData(movies: [Movie]) throws {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        for movie in movies {
            try writeMovieToCoreData(movie, context: context)
        }
        
        try context.save()
        
    }
    
    // This function gets the context itself if it isn't passed to it
    func writeMovieToCoreData(_ movie: Movie) throws {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        try writeMovieToCoreData(movie, context: context)
        try context.save()
    }
    
    func writeMovieToCoreData(_ movie: Movie, context: NSManagedObjectContext) throws {
        
        // First check if this movie already exists
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Movies")
        fetchRequest.predicate = NSPredicate(format: "title = %@", movie.title)
        
        do {
            if let fetchResults = try context.fetch(fetchRequest) as? [NSManagedObject] {
                if fetchResults.count != 0 {
                    // If it exists, just update the values
                    let managedObject = fetchResults[0]
                    
                    managedObject.setValue(movie.image, forKey: "image")
                    managedObject.setValue(movie.rating, forKey: "rating")
                    managedObject.setValue(movie.releaseYear, forKey: "releaseYear")
                    managedObject.setValue(movie.genre.joined(separator: ","), forKey: "genre")
                    
                    return
                }
            }
        } catch {}
        
        // Create a new movie if it doesn't exist
        
        let entity = NSEntityDescription.entity(forEntityName: "Movies", in: context)
        let newMovie = NSManagedObject(entity: entity!, insertInto: context)
        
        newMovie.setValue(movie.title, forKey: "title")
        newMovie.setValue(movie.image, forKey: "image")
        newMovie.setValue(movie.rating, forKey: "rating")
        newMovie.setValue(movie.releaseYear, forKey: "releaseYear")
        newMovie.setValue(movie.genre.joined(separator: ","), forKey: "genre")
        
    }
    
    func readAllMoviesFromWeb(handler: (([Movie]?, Error?) -> ())? = nil) {
        
        DispatchQueue.global().async { [weak self] in
            
            let url = URL(string: moviesJsonUrl)!
            
            URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
                guard let theData = data,
                    let movies = try? self?.readArrayFromJSON(theData),
                    let theMovies = movies,
                    error == nil else {
                        DispatchQueue.main.async { [weak self] in
                            if let theHandler = handler {
                                theHandler(nil, error)
                            } else {
                                self?.delegate?.movieManager(self!, didFinishReadingFromURL: url, movies: nil, withError: error)
                            }
                        }
                        return
                }
                
                for m in theMovies {
                    
                    // Fetch the image of the movie
                    do {
                        try self?.loadImage(forMovie: m)
                    } catch {
                        // Just print, not much to do here
                        print("Failed to load image for movie: \(m.title)")
                    }
                    
                }
                
                DispatchQueue.main.async { [weak self] in
                    if let theHandler = handler {
                        theHandler(theMovies, nil)
                    } else {
                        self?.delegate?.movieManager(self!, didFinishReadingFromURL: url, movies: theMovies, withError: nil)
                    }
                }
                
            }.resume()
            
        }
        
    }
    
    // Read a movie from the given URL (if it's a valid movie JSON)
    func readMovieFromURL(_ url: URL, handler: (([Movie]?, Error?) -> ())? = nil) {
        DispatchQueue.global().async { [weak self] in
            
            URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
                
                guard let theData = data,
                    let json = try? JSONSerialization.jsonObject(with: theData, options: .allowFragments) as! [String:Any],
                    let movie = try? Movie(json: json),
                    error == nil else {
                        DispatchQueue.main.async { [weak self] in
                            if let theHandler = handler {
                                theHandler(nil, error)
                            } else {
                                self?.delegate?.movieManager(self!, didFinishReadingFromURL: url, movies: nil, withError: error)
                            }
                        }
                        return
                }
                
                // Get the movie image
                do {
                    try self?.loadImage(forMovie: movie)
                } catch {
                    // Ignore the error, a placeholder will be displayed instead of the image
                    print("Failed to load image for movie: \(movie.title)")
                }
                
                // Return a response to the handler or the delegate
                DispatchQueue.main.async { [weak self] in
                    if let theHandler = handler {
                        theHandler([movie], nil)
                    } else {
                        self?.delegate?.movieManager(self!, didFinishReadingFromURL: url, movies: [movie], withError: nil)
                    }
                }
                
            }.resume()
            
        }
    }
    
    func loadImage(forMovie movie: Movie) throws {
        
        var e: Error?
        
        let imageURL = URL(string: movie.imageLocation!)
        URLSession.shared.dataTask(with: imageURL!) { (data, response, error) in
            guard let imageData = data, error == nil else {
                e = error
                return
            }
            
            movie.image = imageData
        }.resume()
        
        // Throw an error if the image couldn't be loaded
        if let theError = e {
            throw theError
        }
        
    }
    
}
