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
    var combo = 0
    var interstitial: GADInterstitial!
    
    let storage = UserDefaults.standard
    let device_id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    let pointsAccepted = 10
    let pointsFailed = -5
    let pointsCombo = 5
    let maxComboBonus = 15

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        resultLabel.text = "0"
        
        problems = makeProblem(1000)
        
        pickProblem()
        
        limitTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
        
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-2853999389157478/3692728869")
        interstitial.load(GADRequest())
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
        
        // ResultView
        let windowWidth = UIScreen.main.bounds.size.width - 30
        let resultView = ResultView(frame: CGRect(x: 0, y: 0, width: windowWidth, height: windowWidth))
        resultView.resultLabel.text = String(acceptedNum)
        resultView.parentViewController = self
        resultView.score = acceptedNum 
        // HighScore
        let scores = realm.objects(Score.self).sorted(byKeyPath: "score", ascending: false)
        if let highScore = scores.first {
            if highScore.score <= newScore.score {
                // ハイスコア更新のタイミングで書き込む
                updateHighScore(newScore)
                resultView.highScoreLabel.isHidden = false
            }
        } else {
            updateHighScore(newScore)
        }
        
        // Config
        let config = STZPopupViewConfig()
        config.dismissTouchBackground = false
        config.cornerRadius = 20
        presentPopupView(resultView, config: config)
        
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        }
    }
    
    @objc func updateTime() {
        limitTime -= 1
        limitLabel.text = String(limitTime)
        if limitTime == 0 {
            limitTimer.invalidate()
            result()
            return
        }
    }
    
    func updateHighScore(_ newScore: Score) {
        let ref = Database.database().reference()
        
        if let name = storage.object(forKey: "playername") as? String, name != "" {
            ref.child("scores").child(device_id).setValue(["name": name, "score": newScore.score as NSNumber], andPriority: -newScore.score)
        } else {
            let alert = UIAlertController(title: "register name", message: "please set your username", preferredStyle: .alert)
            alert.addTextField {
                textField in
                textField.placeholder = "user name"
                textField.text = self.storage.object(forKey: "playername") as? String
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default) {
                _ in
                let textfield = alert.textFields?.first
                if let name = textfield?.text {
                    ref.child("scores").child(self.device_id).setValue(["name": name, "score": newScore.score as NSNumber], andPriority: -newScore.score)
                    self.storage.set(name, forKey: "playername")
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }

    }
    
    // MARK: - Button

    @IBAction func tapNumber(_ sender: UIButton) {
        let tapped = FNum(rawValue: sender.tag) ?? .zero
        if nowValue.count < 2 {
            nowValue += convertFNum(toStr: tapped)
            inputNumberLabel.text = nowValue
        }
    }
    
    @IBAction func tapDone() {
        let res = nowProblem.2 == nowValue ? "accepted" : "failed"
        _ = ToastView.showText(text: res, duration: .extraShort, target: self)
        if res == "accepted" {
            acceptedNum += pointsAccepted + min(pointsCombo * (combo / 5), maxComboBonus)
            combo += 1
        } else {
            acceptedNum += pointsFailed
            combo = 0
        }
        pickProblem()
        nowValue = ""
        inputNumberLabel.text = "--"
        resultLabel.text = String(acceptedNum)
    }
    
    @IBAction func tapDelete() {
        if nowValue.count > 0 {
            nowValue.remove(at: nowValue.index(before: nowValue.endIndex))
            inputNumberLabel.text = nowValue
        }
        if nowValue.count == 0 {
            inputNumberLabel.text = "--"
        }
    }
}
