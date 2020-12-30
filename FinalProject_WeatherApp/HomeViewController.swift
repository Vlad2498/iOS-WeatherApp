//
//  HomeViewController.swift
//  FinalProject_WeatherApp
//
//  Created by vlad on 23/11/2020.
//

import UIKit

import CoreLocation
import Foundation


class HomeViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var settings: UIButton!
    
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var futureForecast: UIStackView!
    
    
    @IBOutlet weak var forecastDay1WeekdayLabel: UILabel!
    @IBOutlet weak var forecastDay1Image: UIImageView!
    @IBOutlet weak var forecastDay1TempLabel: UILabel!
    
    @IBOutlet weak var forecastDay2WeekdayLabel: UILabel!
    @IBOutlet weak var forecastDay2Image: UIImageView!
    @IBOutlet weak var forecastDay2TempLabel: UILabel!
    
    @IBOutlet weak var forecastDay3WeekdayLabel: UILabel!
    @IBOutlet weak var forecastDay3Image: UIImageView!
    @IBOutlet weak var forecastDay3TempLabel: UILabel!
    
    @IBOutlet weak var forecastDay4WeekdayLabel: UILabel!
    @IBOutlet weak var forecastDay4Image: UIImageView!
    @IBOutlet weak var forecastDay4TempLabel: UILabel!
    
    @IBOutlet weak var forecastDay5WeekdayLabel: UILabel!
    @IBOutlet weak var forecastDay5Image: UIImageView!
    @IBOutlet weak var forecastDay5TempLabel: UILabel!
    
    @IBOutlet weak var forecastDay6WeekdayLabel: UILabel!
    @IBOutlet weak var forecastDay6Image: UIImageView!
    @IBOutlet weak var forecastDay6TempLabel: UILabel!
    
    var forecastWeekdayLabelArray: [UILabel] = []
    var forecastImageArray: [UIImageView] = []
    var forecastTempLabelArray: [UILabel] = []
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var long = 0.0
    var lat = 0.0
        
    var currentCity = ""

    let vldKey = "092476d4e022ba1a3098c9483bd9411e"
    let thnKey = "91b3048d817f3aa43f54db93b944274e"
    let defaults = UserDefaults.standard
    var temperatureUnit = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cityLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .vertical)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //code that runs everytime so temp and forecast can be updated withour restarting the app
        
        temperatureUnit = defaults.string(forKey: "TemperatureUnit") ?? "Celsius"
//        print( "Temperature unit is: ", temperatureUnit)
        
        setupLocation()
        
        // add the weekday labels, weather images and temperatures into 3 arrays
        forecastWeekdayLabelArray = [forecastDay1WeekdayLabel, forecastDay2WeekdayLabel, forecastDay3WeekdayLabel, forecastDay4WeekdayLabel, forecastDay5WeekdayLabel, forecastDay6WeekdayLabel]
        forecastImageArray = [forecastDay1Image, forecastDay2Image, forecastDay3Image, forecastDay4Image, forecastDay5Image, forecastDay6Image]
        forecastTempLabelArray = [forecastDay1TempLabel, forecastDay2TempLabel, forecastDay3TempLabel, forecastDay4TempLabel, forecastDay5TempLabel, forecastDay6TempLabel]
    }

    //MARK: Location setup and manager
    // Location fetching code adapted from https://developer.apple.com/documentation/corelocation/getting_the_user_s_location and https://stackoverflow.com/questions/25296691/get-users-current-location-coordinates
    func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !locations.isEmpty, currentLocation == nil {
            currentLocation = locations.first
            locationManager.stopUpdatingLocation()
            setCityName()
        } else if (currentLocation != nil){
            locationManager.stopUpdatingLocation()
            setCityName()
        }
    }
    
    //MARK: Get and set the name of current city
    func setCityName() {
        
        guard let currentLocation = currentLocation else {
            return
        }
        long = currentLocation.coordinate.longitude
        lat = currentLocation.coordinate.latitude
        
        let geoCoder = CLGeocoder()
        let cityLocation = CLLocation(latitude: lat, longitude: long)
        
        geoCoder.reverseGeocodeLocation(cityLocation, completionHandler: {(placemarks, _) -> Void in
            placemarks?.forEach{
                (placemark) in
                if let city = placemark.locality {
                    self.currentCity = city
//                    print("City is:", self.currentCity)
                    self.cityLabel.text = city
                    
                    //MARK: call download weather functions
                    self.downloadCurrentWeatherData()
                    self.downloadForecastWeatherData()
                }
            }
        })
    }
    
    //MARK: Download Weather Data
    //gets weather for the current location | NOT FORECAST FOR FUTURE DAYS
    //code adapted from this tutorial : https://www.youtube.com/watch?v=mnKUut8atD4
    private func downloadCurrentWeatherData() {
        // print("Now in downloadWeatherData \(currentCity)")
        
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
                    guard let weatherDetails = json["weather"] as? [[String : Any]], let weatherMain = json["main"] as? [String : Any], let city = json["name"] as? String else {
                        print("There is a problem with either the weather, main or city object(s)")
                        return
                    }
                    // getting the temperature data from the "main" object
                    let temp = Int(weatherMain["temp"] as? Double ?? 0)
//                    print("Temperature is: ",temp)
                    
                    //getting the description from the first string of the "weather" object
                    let description = (weatherDetails.first?["description"] as? String)
                    
                    // calls setweather function after it is done with fetching all the weather data
                    DispatchQueue.main.async {
                        self.setLocationWeather(weather: weatherDetails.first?["main"] as? String, description: description , temp: temp, city: city)
                    }
                } catch {
                    print("Error retrieving weather data")
                }
            }
        }
        //starts async task
        task.resume()
    }
    
    //MARK: Download forecast for the next 6 days
    private func downloadForecastWeatherData() {
        
        //set unit parameters depending on weather parameters
        var unit = ""
        if temperatureUnit == "Celsius" {
            unit = "metric"
        } else {
            unit = "imperial"
        }
        
        
        guard let urlForForecastWeather = URL(string: "http://api.openweathermap.org/data/2.5/onecall?lat=\(lat)&lon=\(long)&exclude=current,minutely,hourly,alerts&units=\(unit)&appid=\(thnKey)")
        else {
            print("There is a problem with the url string for forecast weather")
            return
        }
//        initializing async download of weather data
        let task = URLSession.shared.dataTask(with: urlForForecastWeather) {(data,response,error) in
            if let data = data, error == nil {
                do {
                    //getting the entire object from the source
                    guard let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any] else {
                        print("There is a problem with the JSON object for forecast weather")
                        return
                    }
                    
                    //filtering the relevant information from the big object
                    guard let weatherDaily = json["daily"] as? [[String : Any]] else {
                        print("There is a problem with the daily list")
                        return
                    }
                    
                    // calls setweather function after it is done with fetching all the weather data
                    DispatchQueue.main.async {
                        var loopCounter = 0
                        // loop through each object in the daily list object
                        for day in weatherDaily {
                            
                            // assign the temp object from the daily list
                            let weatherTemp = day["temp"] as? [String : Any]
                            
                            // assign the weather object from the daily list
                            let weatherData = day["weather"] as? [[String : Any]]
                            
                            // getting the forecast weather from the "weather" object
                            let forecastWeather = weatherData?.first?["main"] as? String
                            
                            // getting the forecast temperature from the "daily" object
                            let forecastTemp = Int(weatherTemp?["min"] as? Double ?? 0)
                            
                            //getting the forecast weather description from the first string of the "weather" object
                            let forecastWeatherDescription = weatherData?.first?["description"] as? String
                            
                            if loopCounter < 6 {
                            self.setForecastWeather(weekdayLabel: self.forecastWeekdayLabelArray[loopCounter], imageView: self.forecastImageArray[loopCounter], tempLabel: self.forecastTempLabelArray[loopCounter], weather: forecastWeather, description: forecastWeatherDescription, temp: forecastTemp, loopRound: loopCounter)
                            }
                            loopCounter+=1
                        }
                    }
                } catch {
                    print("Error retrieving weather data")
                }
            }
        }
        //starts async task
        task.resume()
    }
    
    
    //MARK: Set Weather For Location
    private func setLocationWeather(weather: String?, description: String?, temp: Int, city: String?){
        // sets Celsius or Fahrenheit sign depending on the temp unit switch
        var sign = ""
        if temperatureUnit == "Celsius" {
            sign = "C"
        } else {
            sign = "F"
        }
//        print("Weather forecast for today is: '\(weather!)' with description: '\(description!)' and temperature: '\(temp)' in '\(city!)'")
        
        tempLabel.text = "\(temp)°\(sign)"
        descriptionLabel.text = weather!
        
        //switch that handles types of weather
        switch weather! {
        case "Clouds":
            mainImage.image = UIImage(systemName: "cloud.fill")
            mainImage.tintColor = .systemGray
        case "Drizzle":
            mainImage.image = UIImage(systemName: "cloud.drizzle.fill")
            mainImage.tintColor = .systemBlue
        case "Mist":
            mainImage.image = UIImage(systemName: "cloud.fog.fill")
            mainImage.tintColor = .systemGray
        case "Fog":
            mainImage.image = UIImage(systemName: "cloud.fog.fill")
            mainImage.tintColor = .systemGray
        case "Thunderstorm":
            mainImage.image = UIImage(systemName: "cloud.bolt.rain.fill")
            mainImage.tintColor = .systemGray
        case "Rain":
            mainImage.image = UIImage(systemName: "cloud.rain.fill")
            mainImage.tintColor = .systemGray
        case "Snow":
            mainImage.image = UIImage(systemName: "snow")
            mainImage.tintColor = .systemGray
        case "Clear":
            mainImage.image = UIImage(systemName: "sun.max.fill")
        case "Haze":
            mainImage.image = UIImage(systemName: "sun.haze.fill")
        default:
            mainImage.image = UIImage(systemName: "questionmark")
        }
    }
    
    //MARK: Set forecast weather
    private func setForecastWeather(weekdayLabel: UILabel, imageView: UIImageView, tempLabel: UILabel, weather: String?, description: String?, temp: Int, loopRound: Int) {
        // sets Celsius or Fahrenheit sign depending on the temp unit switch
        var sign = ""
        if temperatureUnit == "Celsius" {
            sign = "C"
        } else {
            sign = "F"
        }
        tempLabel.text = "\(temp)°\(sign)"
        
        //MARK: Generates the text value of the next 6 days
        // code adapted from https://stackoverflow.com/questions/5067785/how-do-i-add-1-day-to-an-nsdate
        var dateComponent = DateComponents()
        dateComponent.day = loopRound+1
        let calendar = Calendar.current
        let incrementedDate = calendar.date(byAdding: dateComponent, to: Date())
        weekdayLabel.text = DateFormatter().weekdaySymbols[Calendar.current.component(.weekday, from: incrementedDate!)-1]
        
        //switch that handles types of weather
        switch weather! {
        case "Clouds":
            imageView.image = UIImage(systemName: "cloud.fill")
            imageView.tintColor = .systemGray
        case "Fog":
            imageView.image = UIImage(systemName: "cloud.fog.fill")
            imageView.tintColor = .systemGray
        case "Rain":
            imageView.image = UIImage(systemName: "cloud.rain.fill")
            imageView.tintColor = .systemBlue
        case "Drizzle":
            imageView.image = UIImage(systemName: "cloud.drizzle.fill")
            imageView.tintColor = .systemBlue
        case "Snow":
            imageView.image = UIImage(systemName: "snow")
            imageView.tintColor = .systemGray
        case "Mist":
            imageView.image = UIImage(systemName: "cloud.fog.fill")
            imageView.tintColor = .systemGray
        case "Thunderstorm":
            imageView.image = UIImage(systemName: "cloud.bolt.rain.fill")
            imageView.tintColor = .systemGray
        case "Clear":
            imageView.image = UIImage(systemName: "sun.max.fill")
            imageView.tintColor = .systemYellow
        default:
            imageView.image = UIImage(systemName: "questionmark")
        }
    }
    
    @IBAction func openSettings(_ sender: Any) {
//        print("Pressed the settings button")
        
    }
    
     //MARK: - Navigation

     //In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         //Get the new view controller using segue.destination.
         //Pass the selected object to the new view controller.
    }
    

}
