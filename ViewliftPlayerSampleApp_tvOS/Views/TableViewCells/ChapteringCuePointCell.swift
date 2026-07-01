//
//  ChapteringCuePointCell.swift
//
//  Created by devendragaur@viewlift.com on 29/06/26.
//  VLPlayerLib
//

import UIKit
import Kingfisher

final class ChapteringCuePointCell: UICollectionViewCell {
    static let reuseIdentifier = "ChapteringCuePointCell"

    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var metaLabel: UILabel!
    @IBOutlet private weak var tagLabel: UILabel!


    var onDirectionalPress: ((UIPress.PressType) -> Bool)?
    // The placeholder image is provided by the host app's main bundle, so it is
    // looked up explicitly from Bundle.main and keeps working under SPM integration.
    let plaholderImage = UIImage(named: "placeholderImage.png", in: .main, with: nil)

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = false
        contentView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        tagLabel.layer.cornerRadius = 4
        tagLabel.clipsToBounds = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.kf.cancelDownloadTask()
        setFocusedAppearance(false)
        onDirectionalPress = nil
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if onDirectionalPress?(press.type) == true {
                return
            }
        }
        super.pressesBegan(presses, with: event)
    }

    func setFocusedAppearance(_ focused: Bool) {
        contentView.layer.borderWidth = focused ? 4 : 0
        contentView.layer.borderColor = UIColor.white.cgColor
    }

    func configure(
        label: String,
        tagText: String?,
        formattedTime: String,
        thumbnail: String?,
        expanded: Bool
    ) {
        applyLayout(expanded: expanded)

        titleLabel.text = label
        if let tagText {
            tagLabel.text = tagText
            tagLabel.isHidden = !expanded
        } else {
            tagLabel.isHidden = true
        }
        metaLabel.text = formattedTime
        metaLabel.isHidden = !expanded

        if let thumbnail, let url = URL(string: thumbnail) {
            let options: KingfisherOptionsInfo = [.transition(.fade(0.2))]
            thumbnailImageView.kf.setImage(with: url, placeholder: plaholderImage, options: options)
        } else {
            thumbnailImageView.kf.cancelDownloadTask()
            thumbnailImageView.image = plaholderImage
        }
    }

    private func applyLayout(expanded: Bool) {
        titleLabel.isHidden = false
        titleLabel.numberOfLines = expanded ? 2 : 1
        titleLabel.font = expanded
            ? UIFont.boldSystemFont(ofSize: 20)
            : UIFont.boldSystemFont(ofSize: 18)

    }
}
