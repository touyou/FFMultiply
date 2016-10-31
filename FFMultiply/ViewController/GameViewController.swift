//
//  GameViewController.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/10/24.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

final class GameViewController: UIViewController {
    
    @IBOutlet weak var inputNumberLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var leftProblemLabel: UILabel!
    @IBOutlet weak var rightProblemLabel: UILabel!
    @IBOutlet weak var limitLabel: UILabel!
    
    
    var nowValue: String = ""
    var acceptedNum: Int = 0
    var problems: [FFProblem]!
    var nowProblem: FFProblem!
    var limitTimer: Timer!
    var limitTime: Int = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        resultLabel.text = "0"
        
        problems = makeProblem(1000)
        
        pickProblem()
        
        limitTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
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
        switch (segue.destination, segue.identifier) {
        case (let viewCon as ResultViewController, "toResultView"?):
            viewCon.score = acceptedNum
        default:
            break
        }
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
    
    func toResultView() {
        performSegue(withIdentifier: "toResultView", sender: nil)
    }
    
    func updateTime() {
        limitTime -= 1
        limitLabel.text = String(limitTime)
        if self.limitTime == 0 {
            limitTimer.invalidate()
            self.toResultView()
            return
        }

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
        _ = ToastView.showText(text: res, duration: .extraShort, target: self)
        if res == "accepted" {
            acceptedNum += 1
        }
        pickProblem()
        nowValue = ""
        inputNumberLabel.text = "--"
        resultLabel.text = String(acceptedNum)
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
