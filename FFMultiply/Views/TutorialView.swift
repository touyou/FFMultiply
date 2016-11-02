//
//  TutorialView.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/11/02.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class TutorialView: UIView {
    @IBOutlet weak var tutorialImageView: UIImageView!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    
    var finish: (() -> ())!
    var pos: Int = 0
    var tutorialImageList = [UIImage]()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        leftButton.isEnabled = false
        
        tutorialImageView.image = tutorialImageList[0]
    }
    
    @IBAction func exitButton() {
        finish()
    }
    
    @IBAction func pushLeft() {
        if pos == 1 {
            leftButton.isEnabled = false
        } else if pos == tutorialImageList.count - 1 {
            rightButton.isEnabled = true
        }
        pos -= 1
        tutorialImageView.image = tutorialImageList[pos]
    }
    
    @IBAction func pushRight() {
        if pos == 0 {
            leftButton.isEnabled = true
        } else if pos == tutorialImageList.count - 2 {
            rightButton.isEnabled = false
        }
        pos += 1
        tutorialImageView.image = tutorialImageList[pos]
    }
}
