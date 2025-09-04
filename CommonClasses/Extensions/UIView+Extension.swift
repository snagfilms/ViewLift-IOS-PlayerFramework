//
//  UIView+Extension.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 27/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

extension UIView {
    
    func setupConstraints(superView: UIView, withHeightConstraint: Bool? = false, topOffset: CGFloat = 0) {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self,
                           attribute: .top,
                           relatedBy: .equal,
                           toItem: superView,
                           attribute: .top,
                           multiplier: 1,
                           constant: topOffset).isActive = true
        NSLayoutConstraint(item: self,
                           attribute: .leading,
                           relatedBy: .equal,
                           toItem: superView,
                           attribute: .leading,
                           multiplier: 1,
                           constant: 0).isActive = true
        NSLayoutConstraint(item: self,
                           attribute: .trailing,
                           relatedBy: .equal,
                           toItem: superView,
                           attribute: .trailing,
                           multiplier: 1,
                           constant: 0).isActive = true
        if withHeightConstraint == true {
            NSLayoutConstraint(item: self,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .notAnAttribute,
                               multiplier: 1,
                               constant: self.bounds.height).isActive = true
        } else {
            NSLayoutConstraint(item: self,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: superView,
                               attribute: .bottom,
                               multiplier: 1,
                               constant: 0).isActive = true
        }
    }
    
    func pinToSuperview(edges: UIRectEdge = .all, insets: UIEdgeInsets = .zero) {
        guard let superview = superview else {
            debugPrint("⚠️ No superview to pin to.")
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        
        var constraints = [NSLayoutConstraint]()
        
        if edges.contains(.top) || edges == .all {
            constraints.append(topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top))
        }
        if edges.contains(.left) || edges == .all {
            constraints.append(leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left))
        }
        if edges.contains(.bottom) || edges == .all {
            constraints.append(bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom))
        }
        if edges.contains(.right) || edges == .all {
            constraints.append(trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.right))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
}
