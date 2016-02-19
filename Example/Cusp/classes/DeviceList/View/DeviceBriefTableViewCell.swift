//
//  DeviceBriefTableViewCell.swift
//  CuspExample
//
//  Created by keyOfVv on 2/16/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import UIKit
import Cusp

// MARK: - Protocol
@objc protocol DeviceBriefTableViewCellDelegate: NSObjectProtocol {
	optional func deviceBriefTableViewCell(deviceBriefTableViewCell: DeviceBriefTableViewCell, wantsConnectTo peripheral: Peripheral) -> Void
	optional func deviceBriefTableViewCell(deviceBriefTableViewCell: DeviceBriefTableViewCell, wantsDisconnectFrom peripheral: Peripheral) -> Void
	optional func deviceBriefTableViewCell(deviceBriefTableViewCell: DeviceBriefTableViewCell, wantsCancelConnectTo peripheral: Peripheral) -> Void
}

class DeviceBriefTableViewCell: UITableViewCell {

	@IBOutlet weak var nameLabel: UILabel!

	@IBOutlet weak var nameLabelWidthConstraint: NSLayoutConstraint!

	@IBOutlet weak var stateLabel: UILabel! {
		didSet {
			stateLabel.backgroundColor = UIColor.greenColor()
			stateLabel.layer.cornerRadius = 2.0
			stateLabel.layer.masksToBounds = true
		}
	}

	@IBOutlet weak var stateLabelWidthConstraint: NSLayoutConstraint!

	@IBOutlet weak var idLabel: UILabel!

	@IBOutlet weak var idLabelWidthConstraint: NSLayoutConstraint!

	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!

	@IBOutlet weak var operationButton: UIButton! {
		didSet {
			operationButton.backgroundColor = UIColor.blueColor()
			operationButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
			operationButton.layer.cornerRadius = 2.0
			operationButton.layer.masksToBounds = true
		}
	}

	@IBOutlet weak var operationButtonWidthConstraint: NSLayoutConstraint!

	var peripheral: Peripheral? {
		didSet {
			if let peripheral = self.peripheral {
				self.nameLabel.text = (peripheral.name == nil ? "?" : peripheral.name!)
				switch peripheral.state {
				case .Connected:
					self.stateLabel.text = "connected"
					self.operationButton.enabled = true
					self.operationButton.setTitle("disconnect", forState: UIControlState.Normal)
				case .Connecting:
					self.stateLabel.text = "connecting"
					self.operationButton.enabled = true
					self.operationButton.setTitle("cancel", forState: UIControlState.Normal)
				case .Disconnected:
					self.stateLabel.text = "disconnected"
					self.operationButton.enabled = true
					self.operationButton.setTitle("connect", forState: UIControlState.Normal)
				case .Disconnecting:
					self.stateLabel.text = "disconnecting"
					self.operationButton.enabled = false
				}
				self.idLabel.text = peripheral.identifier.UUIDString
			}
		}
	}

	weak var delegate: DeviceBriefTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

	override func layoutSubviews() {
		super.layoutSubviews()

		if let text = self.nameLabel.text {
			let size = (text as NSString).boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: self.nameLabel.font], context: nil)
			self.nameLabelWidthConstraint.constant = size.width + 1.0
		}

		if let text = self.stateLabel.text {
			let size = (text as NSString).boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: self.stateLabel.font], context: nil)
			self.stateLabelWidthConstraint.constant = size.width + 3.0
		}

		if let text = self.idLabel.text {
			let size = (text as NSString).boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: self.idLabel.font], context: nil)
			self.idLabelWidthConstraint.constant = size.width + 1.0
		}

		if let text = self.operationButton.currentTitle {
			let size = (text as NSString).boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: self.operationButton.titleLabel!.font], context: nil)
			self.operationButtonWidthConstraint.constant = size.width + 6.0
		}
	}
    
	@IBAction func buttonClicked(sender: UIButton) {
		if let title = sender.currentTitle {
			switch title {
			case "connect":
				if self.delegate?.respondsToSelector("deviceBriefTableViewCell:wantsConnectTo:") == true {
					self.delegate!.deviceBriefTableViewCell!(self, wantsConnectTo: self.peripheral!)
				}
				break
			case "disconnect":
				if self.delegate?.respondsToSelector("deviceBriefTableViewCell:wantsDisconnectFrom:") == true {
					self.delegate!.deviceBriefTableViewCell!(self, wantsDisconnectFrom: self.peripheral!)
				}
				break
			case "cancel":
				if self.delegate?.respondsToSelector("deviceBriefTableViewCell:wantsCancelConnectTo:") == true {
					self.delegate!.deviceBriefTableViewCell!(self, wantsCancelConnectTo: self.peripheral!)
				}
				break
			default:
				break
			}
		}
	}
}
