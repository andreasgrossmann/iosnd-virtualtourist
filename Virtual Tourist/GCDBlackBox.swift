//
//  GCDBlackBox.swift
//  Virtual Tourist
//
//  Created by Andreas on 10/11/16.
//  Copyright © 2016 Andreas. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(updates: @escaping () -> Void) {
    DispatchQueue.main.async() {
        updates()
    }
}
