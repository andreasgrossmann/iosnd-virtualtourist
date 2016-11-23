//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Andreas on 15/11/16.
//  Copyright © 2016 Andreas. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    
    // MARK: Initializer
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entity, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
    
    
    // MARK: Remove Photos
    
    func removePhotos(context: NSManagedObjectContext) {
        if let photo = photo {
            for photo in photo {
                context.delete(photo as! NSManagedObject)
            }
        }
    }
    
    

}
