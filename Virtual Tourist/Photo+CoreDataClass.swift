//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Andreas on 15/11/16.
//  Copyright © 2016 Andreas. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
    // MARK: Initializer
    
    convenience init(url: String, data: NSData?, context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.url = url
            self.data = data
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}
