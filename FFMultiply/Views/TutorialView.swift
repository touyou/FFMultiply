//
//  TutorialView.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/11/02.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class TutorialView: UIView {
    @IBOutlet weak var tutorialImageView: UIImageView! {
        didSet {
            tutorialImageView.image = tutorialImageList[0]
        }
    }
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton! {
        didSet {
            leftButton.isEnabled = false
        }
    }
    
    var finish: (() -> ())!
    var pos: Int = 0
    var tutorialImageList = [#imageLiteral(resourceName: "tutorial1"), #imageLiteral(resourceName: "tutorial2"), #imageLiteral(resourceName: "tutorial3"), #imageLiteral(resourceName: "tutorial4"), #imageLiteral(resourceName: "tutorial5"), #imageLiteral(resourceName: "tutorial6")]
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        let nib = UINib(nibName: "TutorialView", bundle: nil)
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
    
    @IBAction func exitButton() {
        finish()
    }
    
    @IBAction func pushLeft() {
        pos -= 1
        if pos < 1 {
            leftButton.isEnabled = false
        } else if pos < tutorialImageList.count - 1 {
            rightButton.isEnabled = true
        }
        tutorialImageView.image = tutorialImageList[pos]
    }
    
    @IBAction func pushRight() {
        pos += 1
        if pos > tutorialImageList.count - 2 {
            rightButton.isEnabled = false
        } else if pos > 0 {
            leftButton.isEnabled = true
        }
        tutorialImageView.image = tutorialImageList[pos]
    }
}
