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
    
    func getFlickrPhotos(pin: Pin, completionHandler: @escaping (_ success: Bool?, _ error: String?) -> Void) {
        
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
                
                for x in photo {
                    
                    // WORK WITH IF LET HERE...?
                    
                    // Build photo URLs
                    
                    let farm = x["farm"]
                    let server = x["server"]
                    let id = x["id"]
                    let secret = x["secret"]
                    
                    let url = "http://farm\(farm!).staticflickr.com/\(server!)/\(id!)_\(secret!)_m.jpg"
                    
                    print(url)
                    
                    
                    
                    
                    _ = Photo(url: url, data: nil, context: self.stack.context)
                    
                    
                    
                    
//                    do {
//                        try self.stack.context.save()
//                    } catch {
//                        fatalError("Error while saving main context: \(error)")
//                    }
                    
                    
                    
                    
                }
                
                
                // WE HAVE THE COORDINATES HERE, SO WE MIGHT AS WELL SAVE THEM RIGHT AWARY RATHER THEN SENDING THE RESULTS BACK
                // SAVE PHOTO URLs WITH RELEVANT PIN (COORDINATES)
                
                
                
            }
            
            
            
            completionHandler(true, nil)
            
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
