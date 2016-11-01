//
//  ViewController.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/10/24.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import GoogleMobileAds

final class ViewController: UIViewController {
    @IBOutlet weak var bannerView: GADBannerView! {
        didSet {
            bannerView.adSize = kGADAdSizeSmartBannerLandscape
            bannerView.adUnitID = "ca-app-pub-2853999389157478/6345144062"
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func back(segue: UIStoryboardSegue) {}
    
    @IBAction func startGame() {
        performSegue(withIdentifier: "startGame", sender: nil)
    }
    
    @IBAction func localScore(_ sender: UIButton) {
        let viewCon = LocalScoreViewController.instantiate(sender.center)
        present(viewCon, animated: true, completion: nil)
    }
    
    @IBAction func settingView(_ sender: UIButton) {
        let viewCon = SettingViewController.instantiate(sender.center)
        present(viewCon, animated: true, completion: nil)
    }
    
    @IBAction func onlineRank(_ sender: UIButton) {
        let viewCon = OnlineRankingViewController.instantiate(sender.center)
        present(viewCon, animated: true, completion: nil)
    }
}

