//
//  FavoritesTableViewCell.swift
//  FinalProject_WeatherApp
//
//  Created by Thiên Trân on 2020-12-08.
//

import UIKit

class FavoritesTableViewCell: UITableViewCell {
    
    // create a customized table cell with 2 labels and an image view
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
