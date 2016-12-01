//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Andreas on 11/11/16.
//  Copyright © 2016 Andreas. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class FlickrClient {

    // MARK: Properties
    
    var stack: CoreDataStack!
    
    // Shared session
    var session = URLSession.shared

    // MARK: Get photo URLs from Flickr
    
    func getPhotoURLs(pin: Pin, completionHandler: @escaping (_ photos: [Photo]?, _ error: Error?) -> Void) {

        // Request page 1 to see how many pages there are for this pin
        
        makeFlickrRequest(pin: pin, page: 1) { data, error in
            
            if let result = (try! JSONSerialization.jsonObject(with: data!, options: .allowFragments)) as? [String: AnyObject] {
                
                let photos = result["photos"] as! [String: AnyObject]
                
                var numOfPages = photos["pages"] as! Int

                // If there are more than 100 pages, cap them at 100
                if numOfPages >= 100 {
                    numOfPages = 100
                }

                // Randomly select a page
                
                let randomPage = Int(arc4random_uniform(UInt32(numOfPages))) + 1

                // Get photo URLs from random page
                
                self.makeFlickrRequest(pin: pin, page: randomPage) { data, error in

                    // Use data
                    
                    if let result = (try! JSONSerialization.jsonObject(with: data!, options: .allowFragments)) as? [String: AnyObject] {

                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        self.stack = delegate.stack

                        let photos = result["photos"] as! [String: AnyObject]
                        
                        let photo = photos["photo"] as! [[String: AnyObject]]

                        var photoURLs: [Photo] = []
                        
                        for property in photo {
                            
                            // Build photo URLs
                            
                            let farm = property["farm"]
                            let server = property["server"]
                            let id = property["id"]
                            let secret = property["secret"]
                            
                            let urlString = "https://farm\(farm!).staticflickr.com/\(server!)/\(id!)_\(secret!)_m.jpg"
                            
                            let photo = Photo(url: urlString, data: nil, context: self.stack.context)
                            
                            photoURLs.append(photo)

                        }
                        
                        completionHandler(photoURLs, nil)

                    }

                }
                
            }

        }

    }

    // MARK: Make Flickr requests
    
    func makeFlickrRequest(pin: Pin, page: Int, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) {

        // Configure request
        let request = NSMutableURLRequest(url: URL(string: "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=6d7824a3602f71e90ef6a4050ef2b3b7&lat=\(pin.latitude)&lon=\(pin.longitude)&per_page=21&page=\(page)&format=json&nojsoncallback=1")!)
        
        // Make request
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            
            // GUARD: Was there an error?
            guard (error == nil) else {
                completionHandler(nil, error)
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            
            completionHandler(data, nil)

        }

        task.resume()
        
    }
    
    // MARK: Get photo data

    func downloadPhotos(photos: Photo, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) {

        let url = URL(string: photos.url!)
        
        let task = session.dataTask(with: url!) { data, response, error in
            
            // GUARD: Was there an error?
            guard (error == nil) else {
                completionHandler(nil, error)
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            
            completionHandler(data, nil)
            
            }
            
        task.resume()

    }

    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
}
