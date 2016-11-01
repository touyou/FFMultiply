//
//  ResultView.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/10/31.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

final class ResultView: UIView {
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var highScoreLabel: UILabel! {
        didSet {
            highScoreLabel.isHidden = true
        }
    }
    
    var parentViewController: UIViewController!
    var score: Int!
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        let nib = UINib(nibName: "ResultView", bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        addSubview(view)
        
        // カスタムViewのサイズを自分自身と同じサイズにする
        view.translatesAutoresizingMaskIntoConstraints = false
        let bindings = ["view": view]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                      options:NSLayoutFormatOptions(rawValue: 0),
                                                                      metrics:nil,
                                                                      views: bindings))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                      options:NSLayoutFormatOptions(rawValue: 0),
                                                                      metrics:nil,
                                                                      views: bindings))
    }
    
    @IBAction func exitBtn() {
        parentViewController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareBtn() {
        
    }
}
