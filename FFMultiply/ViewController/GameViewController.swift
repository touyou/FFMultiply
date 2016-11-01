//
//  GameViewController.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/10/24.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import STZPopupView
import RealmSwift
import Firebase

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
    
    let storage = UserDefaults.standard
    let device_id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if limitTimer.isValid {
            limitTimer.invalidate()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    // MARK: Utility
    
    private func pickProblem() {
        if problems.count == 0 {
            return
        }
        nowProblem = problems.popLast()
        leftProblemLabel.text = convertFNum(toStr: nowProblem.0)
        rightProblemLabel.text = convertFNum(toStr: nowProblem.1)
    }
    
    private func result() {
        // Realm
        let newScore = Score(value: ["date": NSDate(), "score": acceptedNum])
        let realm = try! Realm()
        try! realm.write {
            realm.add(newScore)
        }
        
        let scores = realm.objects(Score.self).sorted(byProperty: "score", ascending: false)
        if let highScore = scores.first {
            if highScore.score <= newScore.score {
                // ハイスコア更新のタイミングで書き込む
                updateHighScore(newScore)
            }
        } else {
            updateHighScore(newScore)
        }
        
        // ResultView
        let resultView = ResultView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        resultView.resultLabel.text = String(acceptedNum)
        resultView.parentViewController = self
        // Config
        let config = STZPopupViewConfig()
        config.dismissTouchBackground = false
        config.cornerRadius = 20
        presentPopupView(resultView, config: config)
    }
    
    func updateTime() {
        limitTime -= 1
        limitLabel.text = String(limitTime)
        if limitTime == 0 {
            limitTimer.invalidate()
            result()
            return
        }
    }
    
    func updateHighScore(_ newScore: Score) {
        let ref = FIRDatabase.database().reference()
        
        if let name = storage.object(forKey: "playername") as? String {
            ref.child("scores").child(device_id).setValue(["name": name, "score": newScore.score as NSNumber])
        } else {
            let alert = UIAlertController(title: "register name", message: "please set your username", preferredStyle: .alert)
            alert.addTextField {
                textField in
                _ = textField.text.flatMap {
                    self.storage.set($0, forKey: "playername")
                }
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default) {
                _ in
                if let name = self.storage.object(forKey: "playername") as? String {
                    ref.child("scores").child(self.device_id).setValue(["name": name, "score": newScore.score as NSNumber])
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
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
            acceptedNum += 10
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
