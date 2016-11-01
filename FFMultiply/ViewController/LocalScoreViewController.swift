//
//  LocalScoreViewController.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/11/01.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import RealmSwift

final class LocalScoreViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            let footer = UIView()
            footer.backgroundColor = UIColor.clear
            tableView.tableFooterView = footer
            tableView.backgroundColor = UIColor.clear
        }
    }
    
    fileprivate var transitioner: Transitioner?
    var rank = [(Int, Score)]()
    
    class func instantiate(_ point: CGPoint) -> LocalScoreViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "LocalScore") as! LocalScoreViewController
        viewController.transitioner = Transitioner(style: .circularReveal(point), viewController: viewController)
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let realm = try! Realm()
        let scores = realm.objects(Score.self).sorted(byProperty: "score", ascending: false)
        if let first = scores.first {
            rank.append((1, first))
            var r = 1
            var nowValue = first
            for i in 1 ..< min(50, scores.count) {
                if scores[i].score != nowValue.score {
                    r = i + 1
                    nowValue = scores[i]
                }
                rank.append((r, scores[i]))
            }
        }
        tableView.reloadData()
    }
}

extension LocalScoreViewController {
    @IBAction func exitView(_ sender: UIButton) {
        transitioner = Transitioner(style: .circularReveal(sender.center), viewController: self)
        dismiss(animated: true, completion: nil)
    }
}

extension LocalScoreViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rank.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scoreCell", for: indexPath)
        
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont(name: "Futura", size: 16)
        cell.tintColor = UIColor.lightGray
        
        let r = rank[indexPath.row]
        let dateFormat = DateFormatter()
        dateFormat.dateStyle = .medium
        
        cell.textLabel?.text = "\(r.0). \(r.1.score) points\n\t date: \(dateFormat.string(from: r.1.date as Date))"
        return cell
    }
}
