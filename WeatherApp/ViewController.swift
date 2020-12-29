import UIKit                                                           //https://docs.swift.org/swift-book/LanguageGuide/Closures.html

class ViewController: UIViewController, UITableViewDataSource {                   // rename it future

    @IBOutlet weak var userInputTextField: UITextField!
    @IBOutlet weak var weatherTableView: UITableView!
    private var weather = [WeatherDay]()                   //only people in this file can access
    private let session = URLSession.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        weatherTableView.dataSource = self
        weatherTableView.tableFooterView = UIView()
    }
    @IBAction func onSearchButtonTapped(_ sender: Any) {
        guard let input = userInputTextField.text, !input.isEmpty else { return }    //can be improved
        let formattedCityName = input.replacingOccurrences(of: " ", with: "+")       //can be improved
        weather = []
        fetchAndReloadWeatherData(cityName: formattedCityName)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weather.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DayWeatherTableViewCell") else { return UITableViewCell() }
        let weatherday = weather[indexPath.row]
        cell.textLabel?.text = weatherday.day + "       " + weatherday.description
        cell.imageView?.image = UIImage(named: weatherday.icon)
        return cell
    }
}

extension ViewController {                      //networking
    
    func fetchAndReloadWeatherData(cityName: String) {
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/forecast?q=\(cityName)&appid=7cc68c52bb817c2525fce8bf1db0c787") else { return }
        session.dataTask(with: url) { (data, response, err) in
            if let data = data, err == nil {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else { return }
                    let list = json["list"] as? [[String: Any]]
                    list?.forEach { day in
                        let anyDayWeather = day["weather"] as? [[String: Any]]
                        let anyDayDesc = anyDayWeather?.first?["description"] as? String
                        let anyDayIconString = anyDayWeather?.first?["icon"] as? String
                        if let rdate = day["dt_txt"] as? String{
                            let dateArray = rdate.components(separatedBy: " ")
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            let date = dateFormatter.date(from:dateArray[0])!
                            let f = DateFormatter()
                            let formattedString = f.weekdaySymbols[Calendar.current.component(.weekday, from: date)-1]
                            if formattedString != self.weather.last?.day {
                                self.weather.append(WeatherDay(description: anyDayDesc ?? "", day: formattedString, icon: anyDayIconString ?? ""))
                            }
                        }
                    }
                    DispatchQueue.main.async{                                   //https://www.hackingwithswift.com/read/9/4/back-to-the-main-thread-dispatchqueuemain
                        self.weatherTableView.reloadData()
                    }
                } catch {
                    print ("JSONSerialization failed")
                }
            } else {
                print (err)
            }
        }.resume()
    }
}
