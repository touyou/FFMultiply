//
//  OnlineRankingViewController.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/11/01.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import RealmSwift
import Firebase

final class OnlineRankingViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            let footer = UIView()
            footer.backgroundColor = UIColor.clear
            tableView.tableFooterView = footer
            tableView.backgroundColor = UIColor.clear
        }
    }
    @IBOutlet weak var tableMode: UISegmentedControl! {
        didSet {
            tableMode.isHidden = true
        }
    }
    
    fileprivate var transitioner: Transitioner?
    var top: Bool = true
    var dataArray = [(Int, Int, String)]()
    
    let ref = FIRDatabase.database().reference()
    let storage = UserDefaults.standard
    let device_id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    class func instantiate(_ point: CGPoint) -> OnlineRankingViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "OnlineRank") as! OnlineRankingViewController
        viewController.transitioner = Transitioner(style: .circularReveal(point), viewController: viewController)
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ref.child("scores").queryOrdered(byChild: "score").queryLimited(toLast: 50).observe(.value, with: {
            snapshot in
            guard let values = snapshot.value as? [String: Any] else {
                return
            }
            print("debug -----")
            print(values)
            let rev = values.values.reversed()
            var sc = (rev[0] as AnyObject).object(forKey: "score") as! Int
            var na = (rev[0] as AnyObject).object(forKey: "name") as! String
            var r = 1
            self.dataArray.append((1, sc, na))
            for i in 1 ..< min(50, rev.count) {
                let nextSc = (rev[i] as AnyObject).object(forKey: "score") as! Int
                na = (rev[i] as AnyObject).object(forKey: "name") as! String
                if sc != nextSc {
                    r = i + 1
                    sc = nextSc
                }
                self.dataArray.append((r, sc, na))
            }
            self.tableView.reloadData()
        }) { error in
            print(error.localizedDescription)
        }
        
    }
}

extension OnlineRankingViewController {
    @IBAction func exitView(_ sender: UIButton) {
        transitioner = Transitioner(style: .circularReveal(sender.center), viewController: self)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func registerRank() {
        let realm = try! Realm()
        let score = realm.objects(Score.self).sorted(byProperty: "score", ascending: false).first
        if let name = storage.object(forKey: "playername") as? String {
            _ = score.flatMap {
                ref.child("scores").child(device_id).setValue(["name": name, "score": $0.score as NSNumber])
            }
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
                    _ = score.flatMap {
                        self.ref.child("scores").child(self.device_id).setValue(["name": name, "score": $0.score as NSNumber])
                    }
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}

extension OnlineRankingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(dataArray.count, 50)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rankCell", for: indexPath)
        
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont(name: "Futura", size: 16)
        cell.textLabel?.numberOfLines = 0
        cell.tintColor = UIColor.lightGray
        
        let d = dataArray[indexPath.row]
        cell.textLabel?.text = "\(d.0). \(d.1) points\n\t \(d.2)"
        return cell
    }
}

