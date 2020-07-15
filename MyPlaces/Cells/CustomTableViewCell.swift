//
//  CustomTableViewCell.swift
//  MyPlaces
//
//  Created by Andrew Boldyrev on 06.05.2020.
//  Copyright © 2020 Andrew Boldyrev. All rights reserved.
//

import UIKit
import Cosmos

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var imageOfPlace: UIImageView! {
        didSet {
            imageOfPlace.layer.cornerRadius =  imageOfPlace.frame.size.height / 2
            imageOfPlace.clipsToBounds = true
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var cosmosView: CosmosView! {
        didSet {
            cosmosView.settings.updateOnTouch = false
        }
    }
    
}
