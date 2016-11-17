//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Andreas on 15/11/16.
//  Copyright © 2016 Andreas. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var data: NSData?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?

}
