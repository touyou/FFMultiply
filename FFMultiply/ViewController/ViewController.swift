//
//  ViewController.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/10/24.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import GoogleMobileAds
import STZPopupView

final class ViewController: UIViewController {
    @IBOutlet weak var bannerView: GADBannerView! {
        didSet {
            bannerView.adSize = kGADAdSizeSmartBannerLandscape
            bannerView.adUnitID = "ca-app-pub-2853999389157478/6345144062"
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
        }
    }
    
    let storage = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if storage.object(forKey: "tutorial") == nil {
            let windowWidth = UIScreen.main.bounds.size.width - 30
            let tutorialView = TutorialView(frame: CGRect(x: 0, y: 0, width: windowWidth, height: windowWidth / 300.0 * 362.5))
            tutorialView.finish = {
                self.dismissPopupView()
            }
            presentPopupView(tutorialView)
            storage.set(true, forKey: "tutorial")
        }
    }

    @IBAction func back(segue: UIStoryboardSegue) {}
    
    @IBAction func startGame() {
        performSegue(withIdentifier: "startGame", sender: nil)
    }
    
    @IBAction func localScore(_ sender: UIButton) {
        let viewController = LocalScoreViewController.instantiate(sender.center)
        present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func settingView(_ sender: UIButton) {
        let viewController = SettingViewController.instantiate(sender.center)
        present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func onlineRank(_ sender: UIButton) {
        let viewController = OnlineRankingViewController.instantiate(sender.center)
        present(viewController, animated: true, completion: nil)
    }
}

