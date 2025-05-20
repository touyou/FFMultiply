//
//  SettingViewController.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/11/01.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds
import STZPopupView

final class SettingViewController: UIViewController {
    @IBOutlet weak var userTextField: UITextField! {
        didSet {
            userTextField.delegate = self
        }
    }
    @IBOutlet weak var bannerView: GADBannerView! {
        didSet {
            bannerView.adSize = kGADAdSizeSmartBannerLandscape
            bannerView.adUnitID = "ca-app-pub-2853999389157478/6345144062"
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
        }
    }
    
    fileprivate var transitioner: Transitioner?
    
    let storage = UserDefaults.standard
    
    class func instantiate(_ point: CGPoint) -> SettingViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "Setting") as? SettingViewController else {
            fatalError("SettingViewControllerのインスタンス化に失敗")
        }
        viewController.transitioner = Transitioner(style: .circularReveal(point), viewController: viewController)
        viewController.modalPresentationStyle = .currentContext
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        _ = storage.object(forKey: "playername").flatMap {
            userTextField.text = $0 as? String
        }
    } 
}

extension SettingViewController {
    @IBAction func cancelBtn(_ sender: UIButton) {
        transitioner = Transitioner(style: .circularReveal(sender.center), viewController: self)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveBtn(_ sender: UIButton) {
        transitioner = Transitioner(style: .circularReveal(sender.center), viewController: self)
        _ = userTextField.text.flatMap { storage.set($0, forKey: "playername") }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tutorialBtn() {
        let windowWidth = UIScreen.main.bounds.size.width - 30
        let tutorialView = TutorialView(frame: CGRect(x: 0, y: 0, width: windowWidth, height: windowWidth / 300.0 * 362.5))
        tutorialView.finish = {
            self.dismissPopupView()
        }
        presentPopupView(tutorialView)
    }
}

extension SettingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
