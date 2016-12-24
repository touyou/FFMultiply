//
//  ToastView.swift
//  Toast
//
//  Created by Naohiro Hamada on 2015/12/28.
//  Copyright © 2015年 HaNoHito. All rights reserved.
//

import UIKit

/**
 Toastの表示時間の設定
 
 * Short - 3秒
 * Long - 6秒
 */
enum ToastDuration {
    case extraShort
    case short
    case long
}

/**
 Toastに表示する画像の位置
 
 * Top - テキストの上側
 * Left - テキストの左側
 * Right - テキストの右側
 * Bottom - テキストの下側
 */
enum ToastImagePosition {
    case top
    case left
    case right
    case bottom
}

/**
 Toast Viewクラス
 */
class ToastView: UIView {
    
    // MARK: - Class property
    
    /// ToastDuration.longに対応した表示秒数
    static fileprivate let LongDurationInSeconds = 6.0
    
    /// ToastDuration.shortに対応した表示秒数
    static fileprivate let ShortDurationInSeconds = 3.0
    
    /// ToastDuration.extraShortに対応した表示秒数
    static fileprivate let ExtraShortDurationInSeconds = 1.0
    
    /// Toastの表示・非表示にかかるアニメーションの秒数
    static fileprivate let FadeInOutDurationInSeconds = 0.4
    
    /// Toastの表示・非表示時のアニメーションのタイプ
    static fileprivate let ToastTransition = UIViewAnimationOptions.transitionCrossDissolve
    
    static fileprivate let MaximumImageSize = (32, 32)
    
    /// Toastの背景色
    static var toastBackgroundColor: UIColor? {
        get {
            return UIColor.init(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.8)
        }
    }
    
    /// Toastのテキストの色
    static var toastTextColor: UIColor {
        get {
            return UIColor.white
        }
    }
    
    /// Toastを非表示にするためのタイマー
    var hideTimer: Timer? = nil
    
    // MARK: - Private methods
    
    /// Toast表示後に、非表示にするためのタイマーを起動させる
    private func startTimer(duration: ToastDuration) {
        switch duration {
        case .extraShort:
            hideTimer = Timer(timeInterval: ToastView.ExtraShortDurationInSeconds, target: self, selector: #selector(self.hideSelf(timer:)), userInfo: nil, repeats: false)
        case .short:
            hideTimer = Timer(timeInterval: ToastView.ShortDurationInSeconds, target: self, selector: #selector(self.hideSelf(timer:)), userInfo: nil, repeats: false)
        case .long:
            hideTimer = Timer(timeInterval: ToastView.LongDurationInSeconds, target: self, selector: #selector(self.hideSelf(timer:)), userInfo: nil, repeats: false)
        }
        let runLoop = RunLoop.current
        runLoop.add(hideTimer!, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    /// Toastを非表示にする
    internal func hideSelf(timer: Timer) {
        if timer.isValid {
            timer.invalidate()
        }
        
        UIView.transition(with: self, duration: ToastView.FadeInOutDurationInSeconds, options: ToastView.ToastTransition, animations: nil, completion: { if $0 { self.removeFromSuperview() } } )
        self.isHidden = true
    }
    
    // MARK: - Create Toast
    
    /**
    現在の画面に表示できるようにする
     */
    
    static func showText(text: String, duration: ToastDuration = .short, target: UIViewController) -> ToastView? {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            return nil
        }
        guard let targetView = target.view  else {
            return nil
        }
        
        let offset = CGPoint(x: 8, y: 8)
        let frame = CGRect(x: keyWindow.frame.origin.x + offset.x, y: keyWindow.frame.origin.y + offset.y, width: keyWindow.frame.size.width - offset.x, height: keyWindow.frame.size.height - offset.y)
        let toast = ToastView(frame: frame)
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: toast.frame.size.width, height: toast.frame.size.height))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = ToastView.toastBackgroundColor
        backgroundView.layer.cornerRadius = 4
        
        let textLabel = UILabel(frame: CGRect(x: 0, y: 0, width: toast.frame.size.width, height: toast.frame.size.height))
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 4
        textLabel.text = text
        textLabel.textColor = toastTextColor
        textLabel.textAlignment = .center
        
        toast.addSubview(backgroundView)
        toast.addSubview(textLabel)
        
        targetView.addSubview(toast)
        
        let constraints = [NSLayoutConstraint(item: toast, attribute: .bottom, relatedBy: .equal, toItem: backgroundView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .top, relatedBy: .equal, toItem: backgroundView, attribute: .top, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .leading, relatedBy: .equal, toItem: backgroundView, attribute: .leading, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .trailing, relatedBy: .equal, toItem: backgroundView, attribute: .trailing, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: backgroundView, attribute: .bottom, relatedBy: .equal, toItem: textLabel, attribute: .bottom, multiplier: 1.0, constant: 10.0),
                           NSLayoutConstraint(item: backgroundView, attribute: .top, relatedBy: .equal, toItem: textLabel, attribute: .top, multiplier: 1.0, constant: -10.0),
                           NSLayoutConstraint(item: backgroundView, attribute: .leading, relatedBy: .equal, toItem: textLabel, attribute: .leading, multiplier: 1.0, constant: -10.0),
                           NSLayoutConstraint(item: backgroundView, attribute: .trailing, relatedBy: .equal, toItem: textLabel, attribute: .trailing, multiplier: 1.0, constant: 10.0),
                           
                           NSLayoutConstraint(item: toast, attribute: .top, relatedBy: .equal, toItem: targetView, attribute: .topMargin, multiplier: 1.0, constant: 12.0),
                           NSLayoutConstraint(item: toast, attribute: .leading, relatedBy: .equal, toItem: targetView, attribute: .leadingMargin, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .trailing, relatedBy: .equal, toItem: targetView, attribute: .trailingMargin, multiplier: 1.0, constant: 0.0),
                           ]
        
        NSLayoutConstraint.activate(constraints)
        targetView.layoutIfNeeded()
        toast.alpha = 0.0
        
        UIView.animate(withDuration: FadeInOutDurationInSeconds, delay: 0.0, options: ToastTransition, animations: { toast.alpha = 1.0 }, completion: { if $0 { toast.startTimer(duration: duration) } } )
        
        return toast

    }
    
    /**
     指定した設定でToastの表示を行う
     - parameters:
     - text:    Toastに表示するテキスト
     - duration:    Toastの表示時間を`ToastDuration`で指定。Defaultでは、`ToastDuration.Short`
     - returns:
     生成したToastのView
     */
    static func showText(text: String, duration: ToastDuration = .short) -> ToastView? {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            return nil
        }
        guard let targetView = keyWindow.rootViewController?.view else {
            return nil
        }
        
        let offset = CGPoint(x: 8, y: 8)
        let frame = CGRect(x: keyWindow.frame.origin.x + offset.x, y: keyWindow.frame.origin.y + offset.y, width: keyWindow.frame.size.width - offset.x, height: keyWindow.frame.size.height - offset.y)
        let toast = ToastView(frame: frame)
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: toast.frame.size.width, height: toast.frame.size.height))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = ToastView.toastBackgroundColor
        backgroundView.layer.cornerRadius = 4
        
        let textLabel = UILabel(frame: CGRect(x: 0, y: 0, width: toast.frame.size.width, height: toast.frame.size.height))
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 4
        textLabel.text = text
        textLabel.textColor = toastTextColor
        textLabel.textAlignment = .center
        
        toast.addSubview(backgroundView)
        toast.addSubview(textLabel)
        
        targetView.addSubview(toast)
        
        let constraints = [NSLayoutConstraint(item: toast, attribute: .bottom, relatedBy: .equal, toItem: backgroundView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .top, relatedBy: .equal, toItem: backgroundView, attribute: .top, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .leading, relatedBy: .equal, toItem: backgroundView, attribute: .leading, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .trailing, relatedBy: .equal, toItem: backgroundView, attribute: .trailing, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: backgroundView, attribute: .bottom, relatedBy: .equal, toItem: textLabel, attribute: .bottom, multiplier: 1.0, constant: 10.0),
                           NSLayoutConstraint(item: backgroundView, attribute: .top, relatedBy: .equal, toItem: textLabel, attribute: .top, multiplier: 1.0, constant: -10.0),
                           NSLayoutConstraint(item: backgroundView, attribute: .leading, relatedBy: .equal, toItem: textLabel, attribute: .leading, multiplier: 1.0, constant: -10.0),
                           NSLayoutConstraint(item: backgroundView, attribute: .trailing, relatedBy: .equal, toItem: textLabel, attribute: .trailing, multiplier: 1.0, constant: 10.0),
                           
                           NSLayoutConstraint(item: toast, attribute: .bottom, relatedBy: .equal, toItem: targetView, attribute: .bottomMargin, multiplier: 1.0, constant: -12.0),
                           NSLayoutConstraint(item: toast, attribute: .leading, relatedBy: .equal, toItem: targetView, attribute: .leadingMargin, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .trailing, relatedBy: .equal, toItem: targetView, attribute: .trailingMargin, multiplier: 1.0, constant: 0.0),
                           ]
        
        NSLayoutConstraint.activate(constraints)
        targetView.layoutIfNeeded()
        toast.alpha = 0.0
        
        UIView.animate(withDuration: FadeInOutDurationInSeconds, delay: 0.0, options: ToastTransition, animations: { toast.alpha = 1.0 }, completion: { if $0 { toast.startTimer(duration: duration) } } )
        
        return toast
    }
    
    /**
     指定した設定でToastの表示を行う
     - parameters:
     - text:    Toastに表示するテキスト
     - image:   Toastに表示する画像
     - imagePosition:   Toastに表示する画像の位置を指定。Defaultでは、`ToastImagePosition.Left`
     - duration:    Toastの表示時間を`ToastDuration`で指定。Defaultでは、`ToastDuration.Short`
     - returns:
     生成したToastのView
     */
    static func showText(text: String, image: UIImage, imagePosition: ToastImagePosition = .left, duration: ToastDuration = .short) -> ToastView? {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            return nil
        }
        guard let targetView = keyWindow.rootViewController?.view else {
            return nil
        }
        
        
        let offset = CGPoint(x: 8, y: 8)
        let frame = CGRect(x: keyWindow.frame.origin.x + offset.x, y: keyWindow.frame.origin.y + offset.y, width: keyWindow.frame.size.width - offset.x, height: keyWindow.frame.size.height - offset.y)
        let toast = ToastView(frame: frame)
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: toast.frame.size.width, height: toast.frame.size.height))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = ToastView.toastBackgroundColor
        backgroundView.layer.cornerRadius = 4
        
        let textLabel = UILabel(frame: CGRect(x: 0, y: 0, width: toast.frame.size.width, height: toast.frame.size.height))
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 4
        textLabel.text = text
        textLabel.textColor = toastTextColor
        textLabel.textAlignment = .center
        
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        toast.addSubview(backgroundView)
        toast.addSubview(textLabel)
        toast.addSubview(imageView)
        
        targetView.addSubview(toast)
        
        var constraints = [NSLayoutConstraint(item: toast, attribute: .bottom, relatedBy: .equal, toItem: backgroundView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .top, relatedBy: .equal, toItem: backgroundView, attribute: .top, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .leading, relatedBy: .equal, toItem: backgroundView, attribute: .leading, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .trailing, relatedBy: .equal, toItem: backgroundView, attribute: .trailing, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .bottom, relatedBy: .equal, toItem: targetView, attribute: .bottomMargin, multiplier: 1.0, constant: -12.0),
                           NSLayoutConstraint(item: toast, attribute: .leading, relatedBy: .equal, toItem: targetView, attribute: .leadingMargin, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: toast, attribute: .trailing, relatedBy: .equal, toItem: targetView, attribute: .trailingMargin, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(MaximumImageSize.0)),
                           NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(MaximumImageSize.1)),
                           ]
        switch imagePosition {
        case .top:
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .top, multiplier: 1.0, constant: -10.0))
            constraints.append(NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: backgroundView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            constraints.append(NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: textLabel, attribute: .top, multiplier: 1.0, constant: -8.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .bottom, relatedBy: .equal, toItem: textLabel, attribute: .bottom, multiplier: 1.0, constant: 10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .leading, relatedBy: .equal, toItem: textLabel, attribute: .leading, multiplier: 1.0, constant: -10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .trailing, relatedBy: .equal, toItem: textLabel, attribute: .trailing, multiplier: 1.0, constant: 10.0))
        case .bottom:
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .top, relatedBy: .equal, toItem: textLabel, attribute: .top, multiplier: 1.0, constant: -10.0))
            constraints.append(NSLayoutConstraint(item: textLabel, attribute: .bottom, relatedBy: .equal, toItem: imageView, attribute: .top, multiplier: 1.0, constant: -8.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .bottom, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1.0, constant: 10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .leading, relatedBy: .equal, toItem: textLabel, attribute: .leading, multiplier: 1.0, constant: -10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .trailing, relatedBy: .equal, toItem: textLabel, attribute: .trailing, multiplier: 1.0, constant: 10.0))
        case .left:
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1.0, constant: 0.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .centerY, relatedBy: .equal, toItem: textLabel, attribute: .centerY, multiplier: 1.0, constant: 0.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: imageView, attribute: .bottom, multiplier: 1.0, constant: 10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .top, relatedBy: .lessThanOrEqual, toItem: imageView, attribute: .top, multiplier: 1.0, constant: -10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: textLabel, attribute: .bottom, multiplier: 1.0, constant: 10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .top, relatedBy: .lessThanOrEqual, toItem: textLabel, attribute: .top, multiplier: 1.0, constant: -10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .trailing, relatedBy: .equal, toItem: textLabel, attribute: .trailing, multiplier: 1.0, constant: 10.0))
            constraints.append(NSLayoutConstraint(item: imageView, attribute: .trailing, relatedBy: .equal, toItem: textLabel, attribute: .leading, multiplier: 1.0, constant: -8.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .leading, relatedBy: .equal, toItem: imageView, attribute: .leading, multiplier: 1.0, constant: -10.0))
        case .right:
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1.0, constant: 0.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .centerY, relatedBy: .equal, toItem: textLabel, attribute: .centerY, multiplier: 1.0, constant: 0.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: imageView, attribute: .bottom, multiplier: 1.0, constant: 10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .top, relatedBy: .lessThanOrEqual, toItem: imageView, attribute: .top, multiplier: 1.0, constant: -10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: textLabel, attribute: .bottom, multiplier: 1.0, constant: 10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .top, relatedBy: .lessThanOrEqual, toItem: textLabel, attribute: .top, multiplier: 1.0, constant: -10.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .trailing, relatedBy: .equal, toItem: imageView, attribute: .trailing, multiplier: 1.0, constant: 10.0))
            constraints.append(NSLayoutConstraint(item: textLabel, attribute: .trailing, relatedBy: .equal, toItem: imageView, attribute: .leading, multiplier: 1.0, constant: -8.0))
            constraints.append(NSLayoutConstraint(item: backgroundView, attribute: .leading, relatedBy: .equal, toItem: textLabel, attribute: .leading, multiplier: 1.0, constant: -10.0))
        }
        NSLayoutConstraint.activate(constraints)
        targetView.layoutIfNeeded()
        
        toast.alpha = 0.0
        
        UIView.animate(withDuration: FadeInOutDurationInSeconds, delay: 0.0, options: ToastTransition, animations: { toast.alpha = 1.0 }, completion: { if $0 { toast.startTimer(duration: duration) } } )
        
        return toast
    }
}
