//
//  DebugTableViewCell.swift
//  DJILeadFollow4
//
//  Created by Adam Rothberg on 1/20/18.
//  Copyright © 2018 Adam Rothberg. All rights reserved.
//

import UIKit

class DebugTableViewCell: UITableViewCell {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    var name : String! {
        didSet {
            nameLabel.text = name
        }
    }
    var value : String! {
        didSet {
            valueLabel.text = value
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
