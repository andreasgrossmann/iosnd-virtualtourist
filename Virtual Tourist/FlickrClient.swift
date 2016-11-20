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
    
    
    
    var stack: CoreDataStack!
    
    
    
    // MARK: Get photos from Flickr
    
    func getFlickrPhotos(pin: Pin, completionHandler: @escaping (_ photos: [Photo]?, _ error: String?) -> Void) {
        
        /* Configure the request */
        let request = NSMutableURLRequest(url: URL(string: "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=6d7824a3602f71e90ef6a4050ef2b3b7&lat=\(pin.latitude)&lon=\(pin.longitude)&format=json&nojsoncallback=1")!)
        
        /* Session */
        let session = URLSession.shared
        
        /* Make the request */
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(nil, "Oops, looks like you're not connected to the internet.")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandler(nil, "Your request didn't return any data. Please try again later.")
                return
            }
            
            
            
            
            /* Use data */

            if let result = (try! JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: AnyObject] {
                
                
                
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                self.stack = delegate.stack
                
                
                
                
                let photos = result["photos"] as! [String: AnyObject]
                
                let photo = photos["photo"] as! [[String: AnyObject]]
                
                
                
                
                
                
                var finalPhotos: [Photo] = []
                
                for x in photo {
                    
                    // WORK WITH IF LET HERE...?
                    
                    // Build photo URLs
                    
                    let farm = x["farm"]
                    let server = x["server"]
                    let id = x["id"]
                    let secret = x["secret"]
                    
                    let urlString = "https://farm\(farm!).staticflickr.com/\(server!)/\(id!)_\(secret!)_m.jpg"
                    
//                    print(urlString)

                    
                    

                        
                    let photo = Photo(url: urlString, data: nil, context: self.stack.context)
//                    photo.pin = pin
                
                    finalPhotos.append(photo)
                    
                    

                    
                }
                
                completionHandler(finalPhotos, nil)
                
                
                
                
                
            }
            
            
            
//            completionHandler(true, nil)
            
        }
        
        task.resume()
        
    }
    
    
    
    
    
    
    
    
    
    
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    
    func downloadImage(photos: Photo, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
//        print("Download Started")
        
        let url = URL(string: photos.url!)
        
        getDataFromUrl(url: url!) { (data, response, error)  in
            guard let data = data, error == nil else { return }
//            print(response?.suggestedFilename ?? url.lastPathComponent)
//            print("Download Finished")
            completion(data, nil)

        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
}
