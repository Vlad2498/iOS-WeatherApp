//
//  FavoritesTableViewController.swift
//  FinalProject_WeatherApp
//
//  Created by Thiên Trân on 2020-12-08.
//

import UIKit

class FavoritesTableViewController: UITableViewController {

    // api keys from OpenWeatherMap
    let vldKey = "092476d4e022ba1a3098c9483bd9411e"
    let thnKey = "91b3048d817f3aa43f54db93b944274e"
    
    let userDefaults = UserDefaults.standard
    var citiesArray = [String]()
    var citiesNameHoldingArray = [String]()
    var citiesTemperatureArray = [Int]()
    var citiesWeatherArray = [String]()
    var temperatureUnitSign = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        
        temperatureUnitSign = self.getTemperatureUnit()
        
        // create an array of city names taken from UserDefaults to assign to each cell of the table
        citiesNameHoldingArray = userDefaults.stringArray(forKey: "FavCities") ?? [String]()
        citiesNameHoldingArray.reverse()
        citiesArray = citiesNameHoldingArray
        
        for city in citiesNameHoldingArray {
            
            // for each city in the array, append an element with default value to each of the following arrays
            citiesTemperatureArray.append(1000)
            citiesWeatherArray.append("nil")
            
            // get the index of the city in the city array, which is also the loop count (e.g. loop 1, loop 2,...), which will be used to determine which row in the table this city is, so later we can update the value of that row
            let cityIndex = citiesArray.firstIndex(of: city)!
            
            // send the city name at this specific loop, the temperature unit taken from UserDefaults, and the index value to the api data download function
            downloadCurrentWeatherData(currentCity: city, temperatureUnit: userDefaults.string(forKey: "TemperatureUnit") ?? "Celsius", cityIndex: cityIndex)
            
        }
        
        // reload the table everytime the view will be diplayed
        tableView.reloadData()
        
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // create as many rows as the number of cities save in UserDefaults "FavCities"
        let cities = userDefaults.stringArray(forKey: "FavCities") ?? [String]()
        return cities.count
    }
    
    // MARK: - Set up/ update cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // initialize a cell object which is from the FavoritesTableViewCell class
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as! FavoritesTableViewCell
        
        // when citiesArray is empty, it means all the rows have been initialized in the table, and this time this function was called when a cell was being updated after the api data download has finished
        if citiesArray.isEmpty {
            
            // gassign value to cityLabel, get the element at position n in the city name array, n = indexPath.row
            cell.cityLabel?.text = citiesNameHoldingArray[indexPath.row]
            
            // assign value to temperatureLabel, get the element at position n in the temperature array, n = indexPath.row
            cell.temperatureLabel?.text = "\(citiesTemperatureArray[indexPath.row])°\(temperatureUnitSign)"
            
            // switch cases for the value of the element at position n in the weather array, n = indexPath.row
            switch citiesWeatherArray[indexPath.row] {
            case "Clouds":
                cell.weatherImageView.image = UIImage(systemName: "cloud.fill")
                cell.weatherImageView.tintColor = .systemGray
            case "Drizzle":
                cell.weatherImageView.image = UIImage(systemName: "cloud.drizzle.fill")
                cell.weatherImageView.tintColor = .systemBlue
            case "Mist":
                cell.weatherImageView.image = UIImage(systemName: "cloud.fog.fill")
                cell.weatherImageView.tintColor = .systemGray
            case "Fog":
                cell.weatherImageView.image = UIImage(systemName: "cloud.fog.fill")
                cell.weatherImageView.tintColor = .systemGray
            case "Thunderstorm":
                cell.weatherImageView.image = UIImage(systemName: "cloud.bolt.rain.fill")
                cell.weatherImageView.tintColor = .systemGray
            case "Rain":
                cell.weatherImageView.image = UIImage(systemName: "cloud.rain.fill")
                cell.weatherImageView.tintColor = .systemBlue
            case "Snow":
                cell.weatherImageView.image = UIImage(systemName: "snow")
                cell.weatherImageView.tintColor = .systemGray
            case "Clear":
                cell.weatherImageView.image = UIImage(systemName: "sun.max.fill")
                cell.weatherImageView.tintColor = .systemYellow
            case "Haze":
                cell.weatherImageView.image = UIImage(systemName: "sun.haze.fill")
                cell.weatherImageView.tintColor = .systemYellow
            default:
                cell.weatherImageView.image = UIImage(systemName: "questionmark")
            }

            return cell
        }
        
        // if the citiesArray is not empty, remove 1 the first value from the array
        citiesArray.removeFirst()

        return cell
    }
    
    private func getTemperatureUnit() -> String {
        let temperatureUnit = userDefaults.string(forKey: "TemperatureUnit") ?? "Celsius"
        if temperatureUnit == "Celsius" {
            return "C"
        } else {
            return "F"
        }
    }
    
    //MARK: - Download API data
    //code adapted from this tutorial : https://www.youtube.com/watch?v=mnKUut8atD4
    private func downloadCurrentWeatherData(currentCity : String, temperatureUnit: String, cityIndex: Int) {
        
        //eliminating diacritics from city name
        let currentCityWithoutDiacritics = currentCity.folding(options: .diacriticInsensitive, locale: .current)
        
        // percent encoding city name
        let currentCityPercentEncoded = currentCityWithoutDiacritics.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        //set unit parameters depending on weather parameters
        var unit = ""
        if temperatureUnit == "Celsius" {
            unit = "metric"
        } else {
            unit = "imperial"
        }
        
        guard let urlForCurrentWeather = URL(string: "http://api.openweathermap.org/data/2.5/weather?q=\(currentCityPercentEncoded!)&units=\(unit)&appid=\(thnKey)")
        else {
            print("There is a problem with the url string for current weather")
            return
        }
//        initializing async download of weather data
        let task = URLSession.shared.dataTask(with: urlForCurrentWeather) {(data,response,error) in
            if let data = data, error == nil {
                do {
                    //getting the entire object from the source
                    guard let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any] else {
                        print("There is a problem with the JSON object for current weather")
                        return
                    }
                    //filtering the relevant information from the big object
                    guard let weatherDetails = json["weather"] as? [[String : Any]], let weatherMain = json["main"] as? [String : Any] else {
                        print("There is a problem with either the weather, main or city object(s)")
                        return
                    }
                    // getting the temperature data from the "main" object
                    let temp = Int(weatherMain["temp"] as? Double ?? 0)
                    
                    // calls setweather function after it is done with fetching all the weather data
                    DispatchQueue.main.async {
                        
                        // assign the temperature value to the element at position n in the temperature array
                        self.citiesTemperatureArray[cityIndex] = temp
                        
                        // assign the weather type to the element at position n in the weather array
                        self.citiesWeatherArray[cityIndex] = weatherDetails.first?["main"] as! String
                        
                        // call the row reload function to update the values of this row
                        self.tableView.reloadRows(at: [IndexPath(row: cityIndex, section: 0)], with: .automatic)

                    }
                } catch {
                    print("Error retrieving weather data")
                }
            }
        }
        //starts async task
        task.resume()
    }
    
    //MARK: - Handler for pressing on cells
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Pressed on \(citiesNameHoldingArray[indexPath.row])")
        
        // add the name of the city in the row that was pressed on to "DetailedCity" in UserDefaults, so that city name can be accessed by CityDetailsScreen
        userDefaults.set(citiesNameHoldingArray[indexPath.row], forKey: "DetailedCity")
       
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//                if let detailsViewController = segue.destination as? DetailsViewController{
//                    detailsViewController.cityName = sentCity
//                }
//    }
    

}
