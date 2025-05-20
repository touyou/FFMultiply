//
//  CircularRevealAnimator.swift
//  CircularRevealAnimator
//
//  Created by Kosuke Kito on 2015/06/23.
//  Copyright (c) 2015年 Kosuke Kito. All rights reserved.
//

import UIKit

class CircularRevealAnimator : NSObject {
    fileprivate let center: CGPoint
    fileprivate let duration: TimeInterval
    fileprivate let isPresent: Bool
    fileprivate var completionHandler: (() -> Void)?
    
    init(center: CGPoint, duration: TimeInterval = 0.5, isPresent: Bool) {
        self.center = center
        self.duration = duration
        self.isPresent = isPresent
    }
    
    @objc dynamic func animationDidStop(_ animation: CAAnimation, finished flag: Bool) {
        completionHandler?()
    }
}

extension CircularRevealAnimator : UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let source = transitionContext.view(forKey: UITransitionContextViewKey.from),
            let target = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
                return
        }
        let containerView = transitionContext.containerView
        
        completionHandler = {
            transitionContext.completeTransition(true)
        }
        
        let radius = { () -> CGFloat in
            let x = max(center.x, containerView.frame.width - center.x)
            let y = max(center.y, containerView.frame.height - center.y)
            return sqrt(x * x + y * y)
        }()
        
        let rectAroundCircle = { (radius: CGFloat) -> CGRect in
            return CGRect(origin: self.center, size: CGSize.zero).insetBy(dx: -radius, dy: -radius)
        }
        
        let zeroPath = CGPath(ellipseIn: rectAroundCircle(0), transform: nil)
        let fullPath = CGPath(ellipseIn: rectAroundCircle(radius), transform: nil)
        
        if isPresent {
            containerView.insertSubview(target, aboveSubview: source)
            addAnimation(target, fromValue: zeroPath, toValue: fullPath)
        } else {
            containerView.insertSubview(target, belowSubview: source)
            addAnimation(source, fromValue: fullPath, toValue: zeroPath)
        }
    }
}

extension CircularRevealAnimator: CAAnimationDelegate {
    fileprivate func addAnimation(_ viewController: UIView, fromValue: CGPath, toValue: CGPath) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animation.delegate = self
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        
        viewController.layer.mask = CAShapeLayer()
        viewController.layer.mask?.add(animation, forKey: nil)
    }
}
