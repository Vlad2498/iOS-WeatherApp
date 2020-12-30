//
//  AddViewController.swift
//  FinalProject_WeatherApp
//
//  Created by Ioan-Vlad Vamos on 2020-12-05.
//

import UIKit
import Foundation

class AddViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let vldKey = "092476d4e022ba1a3098c9483bd9411e"
    let thnKey = "91b3048d817f3aa43f54db93b944274e"
    let defaults = UserDefaults.standard
    var temperatureUnit = ""
    
    var favCities = [String]()
    
    var searchedCity = [String]()
    var searching = false
    var cityNameArr = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        
        hideKeyboardOnTap()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        temperatureUnit = defaults.string(forKey: "TemperatureUnit") ?? "Celsius"
    }

    //MARK: Get weather for searched city
    private func downloadCurrentWeatherData(currentCity : String) {
        
        //eliminating diacritics from city name
        let currentCityWithoutDiacritics = currentCity.folding(options: .diacriticInsensitive, locale: .current)
        
        // percent encoding the city name
        let currentCityPercentEncoded = currentCityWithoutDiacritics.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        //set unit parameters depending on weather parameters
        var unit = ""
        var sign = ""
        if temperatureUnit == "Celsius" {
            unit = "metric"
            sign = "C"
        } else {
            unit = "imperial"
            sign = "F"
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
                    guard let weatherMain = json["main"] as? [String : Any], let city = json["name"] as? String else {
                        print("There is a problem with either the weather, main or city object(s)")
                        return
                    }
                    // getting the temperature data from the "main" object
                    let temp = Int(weatherMain["temp"] as? Double ?? 0)
//                    print("Temperature is: ",temp)
                    
                    // calls setweather function after it is done with fetching all the weather data
                    DispatchQueue.main.async {
                        
                        self.cityNameArr.append("\(city) | \(temp)°\(sign)")
                        self.searchedCity = ["\(city) | \(temp)°\(sign)"]
                        
                        self.tableView.reloadData()
                        print("The array of cities present into the table view is: \(self.cityNameArr)")
                        
                    }
                } catch {
                    print("Error retrieving weather data")
                }
            }
        }
        //starts async task
        task.resume()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

//MARK: table view handlers
extension AddViewController: UITableViewDelegate, UITableViewDataSource {
    
    //returns all the search results if it the user is not currently searching or the current search result if the user is currently searching
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return searchedCity.count
        } else {
            return cityNameArr.count
        }
    }
    
    // populates the table view with the city name and temoerature
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if searching {
            cell?.textLabel?.text = searchedCity[indexPath.row]
        } else {
//            cityNameArr.reverse()
            cell?.textLabel?.text = cityNameArr[indexPath.row]
        }
        return cell!
    }
    
    //MARK: Handler for pressing on cells
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //Checking if the user is currently searching or not
        
        if searching {
//            print("Pressed on cell with", searchedCity[indexPath.row])
            
            let cityName = searchedCity[indexPath.row].split(separator: "|")[0].dropLast()
            //self.favCities.append(String(cityName))
            //print(self.favCities)
            
            //MARK: Alert that handles adding search result to fav city list
            let alert = UIAlertController(title: "Add", message: "Are you sure you want to add \(cityName) to your favorite cities list?", preferredStyle: .alert)
                        
                alert.addAction(UIAlertAction(title: "No", style: .destructive))

            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (alertAction) in
                
                //clears user defaults array
//                self.defaults.set("", forKey: "FavCities")
                
                var cities = self.defaults.stringArray(forKey: "FavCities") ?? [String]()
                //check for duplicates inside the favcities array
                var duplicate = false
                for city in cities {
                    if city == cityName {
                        duplicate = true
                    }
                }
                if duplicate {
                    let alert = UIAlertController(title: "Add", message: "This city is already in your favourite list", preferredStyle: .alert)
                                
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                    
                    self.present(alert, animated: true)
                } else {
                    // if there are no duplicates then add the selected city to the favcity array
                    cities.append(String(cityName))
                    self.defaults.set(cities, forKey: "FavCities")
//                    cities = self.defaults.stringArray(forKey: "FavCities") ?? [String]()
//                    print("Cities in user defaults are : \(cities)")
                }
                
            }))
            self.present(alert, animated: true)
        }

        else {
            //MARK: Alert that adds a city fo favcity list from the search results list
//            print("Pressed on cell with", cityNameArr[indexPath.row])
            let cityName = cityNameArr[indexPath.row].split(separator: "|")[0].dropLast()

            
            let alert = UIAlertController(title: "Add", message: "Are you sure you want to add \(cityName) to your favorite cities list?", preferredStyle: .alert)
                        
                alert.addAction(UIAlertAction(title: "No", style: .destructive))

            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (alertAction) in
                var cities = self.defaults.stringArray(forKey: "FavCities") ?? [String]()
                //check for duplicates
                var duplicate = false
                for city in cities {
                    if city == cityName {
                        duplicate = true
                    }
                }
                if duplicate {
                    let alert = UIAlertController(title: "Add", message: "This city is already in your favourite list", preferredStyle: .alert)
                                
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                    
                    self.present(alert, animated: true)
                } else {
                    // if there are no duplicates then add the selected city to the favcity array
                    cities.append(String(cityName))
                    self.defaults.set(cities, forKey: "FavCities")
//                    cities = self.defaults.stringArray(forKey: "FavCities") ?? [String]()
//                    print("Cities in user defaults are : \(cities)")
                }
            }))
            self.present(alert, animated: true)
        }
        
    }
}

//MARK: Search functions handler
extension AddViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        downloadCurrentWeatherData(currentCity: searchText)
        
        searching = true
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchBar.text = ""
        tableView.reloadData()
    }
    
}

//MARK: Removes keyboard when the user presses on the screen
extension UIViewController {
    func hideKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
