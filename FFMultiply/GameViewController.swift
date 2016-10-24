//
//  GameViewController.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/10/24.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    
    @IBOutlet weak var inputNumberLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    
    
    var nowValue: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    @IBAction func tapNumber(_ sender: UIButton) {
        let tapped = FNum(rawValue: sender.tag) ?? .zero
        if nowValue.characters.count < 2 {
            nowValue += convertFNum(toStr: tapped)
            inputNumberLabel.text = nowValue
        }
    }
    
    @IBAction func tapDone() {
        
    }
    
    @IBAction func tapDelete() {
        if nowValue.characters.count > 0 {
            nowValue.remove(at: nowValue.index(before: nowValue.endIndex))
            inputNumberLabel.text = nowValue
        }
        if nowValue.characters.count == 0 {
            inputNumberLabel.text = "--"
        }
    }
}
