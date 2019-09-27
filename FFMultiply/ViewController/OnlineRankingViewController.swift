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
import DZNEmptyDataSet

final class OnlineRankingViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            let footer = UIView()
            footer.backgroundColor = UIColor.clear
            tableView.tableFooterView = footer
            tableView.backgroundColor = UIColor.clear
            tableView.emptyDataSetSource = self
        }
    }
    @IBOutlet weak var tableMode: UISegmentedControl! {
        didSet {
            tableMode.addTarget(self, action: #selector(OnlineRankingViewController.changeSegment(sender:)), for: .valueChanged)
        }
    }
    @IBOutlet weak var rankLabel: UILabel!
    
    fileprivate var transitioner: Transitioner?
    var top: Bool = true
    var dataArray = [(Int, Int, String)]()
    var myRank: Int = 0
    var myPosition: Int = 0
    
    let ref = Database.database().reference()
    let storage = UserDefaults.standard
    let device_id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    class func instantiate(_ point: CGPoint) -> OnlineRankingViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "OnlineRank") as! OnlineRankingViewController
        viewController.transitioner = Transitioner(style: .circularReveal(point), viewController: viewController)
        viewController.modalPresentationStyle = .currentContext
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let compareDict: ((key: String, value: Any), (key: String, value: Any)) -> Bool = { (a, b) in
            let ascore = (a.value as AnyObject).object(forKey: "score") as! Int
            let bscore = (b.value as AnyObject).object(forKey: "score") as! Int
            return ascore < bscore
        }
        let loadSortScore: (DataSnapshot) -> Void = { snapshot in
            guard let values = snapshot.value as? [String: Any] else {
                return
            }
            let sortVal = values.sorted(by: compareDict)
            let rev = Array(sortVal.reversed())
            var sc = (rev[0].value as AnyObject).object(forKey: "score") as! Int
            var na = ((rev[0].value as AnyObject).object(forKey: "name") as? String) ?? ""
            na = na == "" ? "No Name" : na
            var r = 1
            self.dataArray = []
            self.dataArray.append((1, sc, na))
            if rev.first?.key == self.device_id {
                self.myPosition = 0
                self.myRank = r
                self.rankLabel.text = "Your Rank: \(self.myRank)"
            }
            for i in 1 ..< rev.count {
                let nextSc = (rev[i].value as AnyObject).object(forKey: "score") as! Int
                na = ((rev[i].value as AnyObject).object(forKey: "name") as? String) ?? ""
                na = na == "" ? "No Name" : na
                if sc != nextSc {
                    r = i + 1
                    sc = nextSc
                }
                if rev[i].key == self.device_id {
                    self.myPosition = i
                    self.myRank = r
                    self.rankLabel.text = "Your Rank: \(self.myRank)"
                }
                self.dataArray.append((r, sc, na))
            }
            self.tableView.reloadData()
        }
        
        
        ref.child("scores").queryOrderedByPriority().observe(.value, with: loadSortScore) { error in
            print(error.localizedDescription)
        }
    }
    
    @objc func changeSegment(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            top = true
        } else {
            top = false
        }
        tableView.reloadData()
    }
}

extension OnlineRankingViewController {
    @IBAction func exitView(_ sender: UIButton) {
        transitioner = Transitioner(style: .circularReveal(sender.center), viewController: self)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func registerRank() {
        let realm = try! Realm()
        let score = realm.objects(Score.self).sorted(byKeyPath: "score", ascending: false).first
        if let name = storage.object(forKey: "playername") as? String, name != "" {
            _ = score.flatMap {
                ref.child("scores").child(device_id).setValue(["name": name, "score": $0.score as NSNumber], andPriority: -$0.score)
            }
        } else {
            let alert = UIAlertController(title: "register name", message: "please set your username", preferredStyle: .alert)
            alert.addTextField {
                textField in
                textField.placeholder = "user name"
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default) {
                _ in
                let textfield = alert.textFields?.first
                if let name = textfield?.text {
                    _ = score.flatMap {
                        self.ref.child("scores").child(self.device_id).setValue(["name": name, "score": $0.score as NSNumber], andPriority: -$0.score)
                    }
                    self.storage.set(name, forKey: "playername")
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func shareBtn() {
        let shareText = "My rank is \(myRank)! Let's play FFMultiplier with me! #FFMultiplier"
        let shareURL = URL(string: "https://itunes.apple.com/us/app/ffmultiplier/id1151801381?l=ja&ls=1&mt=8")!
        let activityViewCon = UIActivityViewController(activityItems: [shareText, shareURL], applicationActivities: nil)
        let excludeType = [UIActivity.ActivityType.print]
        activityViewCon.excludedActivityTypes = excludeType
        present(activityViewCon, animated: true, completion: nil)
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
        
        if top || myPosition < 25 {
            let d = dataArray[indexPath.row]
            cell.textLabel?.text = "\(d.0). \(d.1) points\n\t \(d.2)"
            return cell
        } else {
            let d = dataArray[indexPath.row + myRank - 25]
            cell.textLabel?.text = "\(d.0). \(d.1) points\n\t \(d.2)"
            return cell
        }
    }
}

extension OnlineRankingViewController: DZNEmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = NSAttributedString(string: "No Data", attributes: [NSAttributedString.Key.font: UIFont(name: "Futura", size: 20)!, NSAttributedString.Key.foregroundColor: UIColor.white])
        return str
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return UIColor.clear
    }
}
