//
//  UIViewController+extension.swift
//  BestMovies
//
//  Created by Daniel Merchasin on 11/09/2018
//  Copyright © 2018 Daniel Merchasin. All rights reserved.
//

import UIKit

// Just a conveniece extension to easily call frequently used functions
extension UIViewController {
    
    func displayAlert(title: String, message: String, okClickHandler: ((UIAlertAction) -> ())? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: okClickHandler))
        self.present(alert, animated: true, completion: nil)
    }
    
}
