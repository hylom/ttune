//
//  TTUContentMO.swift
//  ttune
//
//  Created by Hiromichi Matsushima on 2017/04/11.
//  Copyright © 2017年 Hiromichi Matsushima. All rights reserved.
//

import Foundation
import CoreData
import Foundation

class TTUContentMO: NSManagedObject {
    @NSManaged var album: String
    @NSManaged var albumArtist: String
    @NSManaged var artist: String
    @NSManaged var genre: String
    @NSManaged var path: String
    @NSManaged var time: String
    @NSManaged var title: String
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
}