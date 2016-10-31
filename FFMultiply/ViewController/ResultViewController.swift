//
//  ResultViewController.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/10/31.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

final class ResultViewController: UIViewController {
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    var score: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        _ = score.flatMap { scoreLabel.text = String($0) }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
