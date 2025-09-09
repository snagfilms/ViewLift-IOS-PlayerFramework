//
//  VLCustomPlayerControlsView+TrickPlay.swift
//  ViewliftPlayerSampleApp
//
//  Created by Japneet Singh on 29/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

//MARK: - Trick_Play Integration
extension VLCustomPlayerControlsView {
    
    internal func removeTrickPlayView() {
        trickPlayImageView?.removeFromSuperview()
        trickPlayTimeView?.removeFromSuperview()
        trickPlayImageView = nil
        trickPlayTimeView = nil
    }
    
    internal func updateSeekingThumbnail(_ slider: TvOSSlider) {
        removeTrickPlayView()
        
        let trickPlayData = delegate?.getTrickPlayData(Double(slider.value))
        
        switch trickPlayType {
        case .thumbnail:
            if let image = trickPlayData?.image {
                updateTrickPlayImage(image, forSlider: slider)
            } else {
                trickPlayImageView?.removeFromSuperview()
                trickPlayImageView = nil
            }
        case .time:
            if let time = trickPlayData?.time {
                updateTrickPlayTime(time, forSlider: slider)
            } else {
                trickPlayTimeView?.removeFromSuperview()
                trickPlayTimeView = nil
            }
        case .auto:
            if let image = trickPlayData?.image {
                updateTrickPlayImage(image, forSlider: slider)
            } else {
                trickPlayImageView?.removeFromSuperview()
                trickPlayImageView = nil
            }
            
            if let time = trickPlayData?.time {
                updateTrickPlayTime(time, forSlider: slider)
            } else {
                trickPlayTimeView?.removeFromSuperview()
                trickPlayTimeView = nil
            }
        default:
            trickPlayImageView?.removeFromSuperview()
            trickPlayTimeView?.removeFromSuperview()
            trickPlayImageView = nil
            trickPlayTimeView = nil
        }
    }
    
    private func updateTrickPlayImage(_ image: UIImage, forSlider slider: TvOSSlider) {
        let width: CGFloat = 200.0
        let height: CGFloat = width * 9.0 / 16.0
        let trickPlayFrame = getTrickPlayViewFrame(width: width, height: height, slider: slider)
        if let trickPlayView = self.trickPlayImageView  {
            trickPlayView.image = image
            trickPlayView.center = CGPoint(x: trickPlayFrame.midX, y: trickPlayFrame.midY)
        } else {
            trickPlayImageView?.removeFromSuperview()
            let imageView = UIImageView(frame: trickPlayFrame)
            imageView.image = image
            trickPlayImageView = imageView
            self.addSubview(imageView)
            imageView.layer.cornerRadius = 2
            imageView.clipsToBounds = true
        }
    }
    
    private func updateTrickPlayTime(_ time: String, forSlider slider: TvOSSlider) {
        let font = UIFont.systemFont(ofSize: 12)
        let height: CGFloat = "9".height(withConstraintWidth: 30, withConstraintHeight: nil, font: font)
        let width: CGFloat = time.width(withConstraintWidth: nil, withConstraintHeight: height, font: font) + 10
        let trickPlayFrame = getTrickPlayViewFrame(width: width, height: height, slider: slider, bottomMargin: 5)
        if let trickPlayView = self.trickPlayTimeView {
            trickPlayView.text = time
            trickPlayView.frame = trickPlayFrame
            trickPlayView.center = CGPoint(x: trickPlayImageView?.frame.midX ?? trickPlayFrame.midX, y: trickPlayView.center.y)
        } else {
            trickPlayTimeView?.removeFromSuperview()
            let label = UILabel(frame: trickPlayFrame)
            label.text = time
            label.textColor = .white
            label.textAlignment = .center
            label.font = font
            label.backgroundColor = .black.withAlphaComponent(0.5)
            label.alpha = 0.7
            trickPlayTimeView = label
            self.addSubview(label)
            trickPlayTimeView?.center = CGPoint(x: trickPlayImageView?.frame.midX ?? trickPlayFrame.midX, y: label.center.y)
            label.layer.cornerRadius = height / 2.0
            label.clipsToBounds = true
        }
    }
    
    private func getTrickPlayViewFrame(width: CGFloat, height: CGFloat, slider: TvOSSlider, bottomMargin: CGFloat = 8.0) -> CGRect {
        // Get track frame relative to controls view
        let trackFrameInSelf = slider.convert(slider.trackView.frame, to: self)
        
        let percent = CGFloat((slider.value - slider.minimumValue) / (slider.maximumValue - slider.minimumValue))
        let thumbCenterX = trackFrameInSelf.minX + (trackFrameInSelf.width * percent)
        
        let midX = thumbCenterX
        let yPosition = trackFrameInSelf.minY - bottomMargin - height - 10
        
        var rect = CGRect(x: midX - (width / 2.0), y: yPosition, width: width, height: height)
        
        // Clamp inside parent bounds
        if rect.minX < 0 {
            rect.origin.x = 0
        } else if rect.maxX > self.bounds.width {
            rect.origin.x = self.bounds.width - width
        }
        
        return rect
    }
    
    private func getTrickPlayData(_ slider: TvOSSlider) -> (image: UIImage?, time: String?) {
        let (image, time) = delegate?.getTrickPlayData(Double(slider.value)) ?? (nil, nil)
        if image == nil && time == nil {
            if let placeHolderImage = UIImage(named: "trickPlay_placeholder_16x9") {
                return (image:placeHolderImage , time: nil)
            }
            return (image: nil, time: nil)
        } else {
            return (image: image, time: time)
        }
    }
}

extension String {
    
    func height(withConstraintWidth:CGFloat, withConstraintHeight:CGFloat?, font:UIFont, paragraphStyle: NSParagraphStyle? = nil) -> CGFloat {
        
        let constraintRect = CGSize(width: withConstraintWidth, height: withConstraintHeight ?? .greatestFiniteMagnitude)
        var attribs: [NSAttributedString.Key: Any] = [ .font: font,
                                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
        if let paragraphStyle {
            attribs[.paragraphStyle] = paragraphStyle
        }
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: attribs, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstraintWidth:CGFloat?, withConstraintHeight:CGFloat, font:UIFont) -> CGFloat {
        
        let constraintRect = CGSize(width: withConstraintWidth ?? .greatestFiniteMagnitude, height: withConstraintHeight)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}
