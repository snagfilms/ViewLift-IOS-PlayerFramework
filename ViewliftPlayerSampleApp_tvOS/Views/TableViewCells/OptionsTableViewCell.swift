//
//  OptionsTableViewCell.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 17/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

class OptionsTableViewCell: UITableViewCell {
    @IBOutlet weak var optionLabel: UILabel!
    @IBOutlet weak var imageViewArrow: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
            if context.nextFocusedView == self {
                self.addFocus(withBorder: true, andScale: 1.1, borderRadius: 10)
            } else {
                self.removeFocus()
            }
        }
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        guard let focusedView = context.nextFocusedView else {return true}
        if !(focusedView.isKind(of: OptionsTableViewCell.self)) {
            if context.focusHeading == .down{
                return false
            }
        }
        return true
    }
}
