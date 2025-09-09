//
//  AdEmbeddedView.swift
//
//  Created by Shivamsharma@viewlift.com on 18/05/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

protocol AdControlDelegate: AnyObject {
    func adPlayPause(isPlaying: Bool)
    func muteButton(enabled status: Bool)
    func adFullScreenBtnTapped(status: Bool)
}

final class PlayerAdEmbeddedView: UIView {
    
    @IBOutlet weak var contentView: UIView?
    @IBOutlet weak var adEmbeddedPlayerControlView: UIView?
    
    @IBOutlet weak var adSlider: CustomSlider? {
        didSet {
            adSlider?.isUserInteractionEnabled = false
            adSlider?.setThumbImage(UIImage(), for: .normal)
            adSlider?.maximumTrackTintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4322559932)
            adSlider?.minimumTrackTintColor = .yellow
            adSlider?.minimumValue = 0.0
            adSlider?.maximumValue = 1.0
        }
    }
    
    @IBOutlet weak var lblTimer: UILabel?
    
    @IBOutlet weak var lblAdCounter: UILabel?
    
    @IBOutlet weak var muteUnmuteBtn: UIButton?
    
    @IBOutlet weak var playPauseBtn: UIButton?
    
    @IBOutlet weak var vwAdView: UIView?
    
    @IBOutlet weak var lblSponsoredAd: UILabel?
    
    @IBOutlet weak var imgViewProvider: UIImageView?
    
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var fullscreenBtn: UIButton?
    
    
    var timer: Timer?
    var currentAdDuration: Double = 0
    var currentAdElapsed: Double = 0
    weak var delegate: AdControlDelegate?
    var isPlaying: Bool = true
    var imageProvider: UIImage?
    var isCreateViewEventTriggered: Bool = false
    var isFullscreen: Bool = false
    var trackingUrl = ""
    var fullScreen = false
    var firedOnce:Bool = true
    
    var muteUnmuteBtnTapped:Bool = false {
        didSet {
            muteUnmuteBtn?.setImage(UIImage(systemName: !muteUnmuteBtnTapped ? "speaker.wave.3.fill" : "speaker.slash.fill"), for: .normal)
        }
    }
    
    init(frame: CGRect, delegate: AdControlDelegate) {
        super.init(frame: frame)
        self.delegate = delegate
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override var accessibilityElements: [Any]? {
        get {
            return sortSubviews(views: getAccessibleElements(from: self.contentView))
        }
        set {
            super.accessibilityElements = newValue
        }
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("PlayerAdEmbeddedView", owner: self, options: nil)
        guard let contentView else { fatalError() }
        addSubview(contentView)
        
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        adSlider?.minimumTrackTintColor = .yellow
        
        playPauseBtn?.alpha = 0
        playPauseBtn?.isSelected = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleVideoViewTapped))
        tapGesture.cancelsTouchesInView = false
        lblSponsoredAd?.text = "Sponsored Ad"
        lblSponsoredAd?.font =  UIFont.systemFont(ofSize: 14, weight: .bold) //.font(.bold, andSize: 12)
        lblTimer?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        lblAdCounter?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        if UIWindow.isLandscape {
            fullscreenBtn?.setImage(UIImage(named: "icon-zoomout"), for: .normal)
            isFullscreen = false
        } else {
            imgViewProvider?.isHidden = true
            fullscreenBtn?.setImage(UIImage(named: "icon-zoomin"), for: .normal)
            isFullscreen = true
        }
        self.contentView?.addGestureRecognizer(tapGesture)
        let adPlayButtonImage = UIImage.init(named: "mediaPlay", in: Bundle.main, compatibleWith: nil)
        let adPauseButtonImage = UIImage.init(named: "Pause", in: Bundle.main, compatibleWith: nil)
        
        playPauseBtn?.setImage(adPlayButtonImage, for: .normal)
        playPauseBtn?.setImage(adPauseButtonImage, for: .selected)
        adSlider?.minimumTrackTintColor = .yellow
    }
    
    func setupTVEProviderImage(with image: UIImage) {
        self.imgViewProvider?.isHidden = true
        self.imgViewProvider?.image = image
    }
    
    func didChangeOrientation(isLandscape: Bool) {
        if isLandscape {
            trailingConstraint = trailingConstraint?.setMultiplier(multiplier: 0.92)
            bottomConstraint = bottomConstraint?.setMultiplier(multiplier: 0.92)
            if imgViewProvider?.image != nil {
                imgViewProvider?.isHidden = true
            }
            
            fullscreenBtn?.setImage(UIImage(named: "icon-zoomout"), for: .normal)
            isFullscreen = false
        } else {
            trailingConstraint = trailingConstraint?.setMultiplier(multiplier: 0.96)
            bottomConstraint = bottomConstraint?.setMultiplier(multiplier: 0.96)
            imgViewProvider?.isHidden = true
            
            fullscreenBtn?.setImage(UIImage(named: "icon-zoomin"), for: .normal)
            isFullscreen = true
        }
        imgViewProvider?.isHidden = true
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    private func getAccessibleElements(from container: UIView?) -> [UIView] {
        guard let container = container else { return [] }
        
        // Recursive function to extract all accessible elements
        func extractAccessibleElements(from view: UIView) -> [UIView] {
            var elements = [UIView]()
            
            // Check if this view itself should be accessible
            let isInteractiveView = view is UIButton ||
            view is UISlider || view is UILabel ||
            view is UIImageView
            
            if isInteractiveView {
                elements.append(view)
            }
            
            // Special handling for stack views
            if let stackView = view as? UIStackView {
                return stackView.arrangedSubviews.flatMap { extractAccessibleElements(from: $0) }
            }
            
            // Handle container views (but skip if it's one of our interactive types)
            if !isInteractiveView && view.subviews.count > 0 {
                return view.subviews.flatMap { extractAccessibleElements(from: $0) }
            }
            
            return elements.filter({ $0.isHidden == false })
        }
        
        let elements = extractAccessibleElements(from: container)
        
        // Configure accessibility properties
        elements.forEach { view in
            view.isAccessibilityElement = true
            
            switch view {
            case is UIButton:
                view.accessibilityTraits = .button
                view.accessibilityHint = "Double tap to activate"
            case is UISlider:
                view.isAccessibilityElement = false
            case is UILabel:
                view.accessibilityTraits = .staticText
                if let label = view as? UILabel, label.accessibilityLabel == nil {
                    label.accessibilityLabel = label.text
                }
            case is UIImageView:
                view.accessibilityTraits = .image
                if let imageView = view as? UIImageView, imageView.accessibilityLabel == nil {
                    imageView.accessibilityLabel = "Image"
                }
            default:
                break
            }
        }
        
        return elements
    }
    
    private func sortSubviews(views: [UIView]) -> [Any]? {
        let sortedElements = views.sorted {
            return (Int($0.accessibilityIdentifier ?? "") ?? 0) < (Int($1.accessibilityIdentifier ?? "") ?? 0)
        }
        return sortedElements
    }
    
    func clearThumbImage(size: CGSize = CGSize(width: 20, height: 20)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    @objc func handleVideoViewTapped() {
        UIView.animate(withDuration: 0.3) {
            self.playPauseBtn?.alpha = 1
        }
        self.playPauseBtn?.layer.zPosition = 10
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hidePlayButton), object: nil)
        perform(#selector(hidePlayButton), with: nil, afterDelay: 3)
    }
    
    @objc func hidePlayButton() {
        UIView.animate(withDuration: 0.3) {
            self.playPauseBtn?.alpha = 0
        }
    }
        
    @IBAction func onClickPlayPauseButn(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3) {
            self.playPauseBtn?.alpha = 1
        }
        
        playPauseBtn?.isSelected.toggle()
        UserDefaults.standard.set(playPauseBtn?.isSelected, forKey: "isPlayingAdKey")
        if let isSelected = playPauseBtn?.isSelected as? Bool {
            delegate?.adPlayPause(isPlaying:  isSelected)
            
        }
    }
    
    @IBAction func onClickMuteUmnuteBtn(_ sender: UIButton) {
        muteUnmuteBtnTapped = !muteUnmuteBtnTapped
        delegate?.muteButton(enabled: muteUnmuteBtnTapped)
    }
    
    @IBAction func onClickFullscreenBtn(_ sender: UIButton) {
        fullScreen.toggle()
        NotificationCenter.default.post(name: .playerAdDidHideStatusbarOnFullScreen,object: nil,userInfo: ["isStatusbarHiddenOnFullScreen": fullScreen])
        delegate?.adFullScreenBtnTapped(status: fullScreen)
        didChangeOrientation(isLandscape: fullScreen)
    }
    
}

extension NSLayoutConstraint {
    
    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {
        
        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        
        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        newConstraint.isActive = true
        
        NSLayoutConstraint.deactivate([self])
        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
    
}
