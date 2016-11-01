//
//  ScoreModel.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/10/31.
//  Copyright © 2016年 touyou. All rights reserved.
//

import Foundation
import RealmSwift

final class Score: Object {
    dynamic var date = NSDate(timeIntervalSince1970: 1)
    dynamic var score: Int = 0
}
