//
//  SettingViewController.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/11/01.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import Firebase

class SettingViewController: UIViewController {

    @IBOutlet weak var userTextField: UITextField! {
        didSet {
            userTextField.delegate = self
        }
    }
    
    fileprivate var transitioner: Transitioner?
    
    let storage = UserDefaults.standard
    
    class func instantiate(_ point: CGPoint) -> SettingViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "Setting") as! SettingViewController
        viewController.transitioner = Transitioner(style: .circularReveal(point), viewController: viewController)
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
}

extension SettingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
