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
    @IBOutlet weak var leftProblemLabel: UILabel!
    @IBOutlet weak var rightProblemLabel: UILabel!
    
    
    var nowValue: String = ""
    var problems: [FFProblem]!
    var nowProblem: FFProblem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        resultLabel.text = "0"
        
        problems = makeProblem(10)
        
        pickProblem()
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
    
    // MARK: Initialize Utility
    
    fileprivate func pickProblem() {
        if problems.count == 0 {
            return
        }
        nowProblem = problems.popLast()
        leftProblemLabel.text = convertFNum(toStr: nowProblem.0)
        rightProblemLabel.text = convertFNum(toStr: nowProblem.1)
    }
    
    // MARK: - Button

    @IBAction func tapNumber(_ sender: UIButton) {
        let tapped = FNum(rawValue: sender.tag) ?? .zero
        if nowValue.characters.count < 2 {
            nowValue += convertFNum(toStr: tapped)
            inputNumberLabel.text = nowValue
        }
    }
    
    @IBAction func tapDone() {
        let res = nowProblem.2 == nowValue ? "accepted" : "failed"
        _ = ToastView.showText(text: res, duration: .extraShort)
        pickProblem()
        nowValue = ""
        inputNumberLabel.text = "--"
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
