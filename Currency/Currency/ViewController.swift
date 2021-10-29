//
//  ViewController.swift
//  Currency
//
//  Created by Дмитрий on 28.10.2021.
//

import UIKit
import SWXMLHash

class ViewController: UIViewController {

    @IBOutlet private var tableWithResults: UITableView!
    @IBOutlet private var notificationTextField: UITextField!
    
    private var currencyDict: [String:Double] = [:]
    private var dateArray: [String] = []
    
    private var timer = Timer()
    
//    private var test: String = "73,."
    
    private let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        if let val = self.test.toDouble() {
//            debugPrint(String(val))
//        } else {
//            debugPrint("Unable to convert")
//        }
        
        tableWithResults.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        if userDefaults.string(forKey: "track") != nil {
            notificationTextField.text = userDefaults.string(forKey: "track")
        } else {
            notificationTextField.text = "70.0"
        }
        
        getXML(completion: { currencyDict in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.currencyDict = currencyDict
                //debugPrint(self.currencyDict)
                //debugPrint(self.dateArray)
                
                var tempArray: [String] = []
                
                for i in self.dateArray {
                    if self.currencyDict[i] != nil {
                        tempArray.append(i)
                    }
                }
                self.dateArray = tempArray
                debugPrint(self.dateArray)
                
                self.tableWithResults.reloadData()
            }
        })

        self.timer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true, block: { _ in
            self.getXML(completion: { currencyDict in
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.currencyDict = currencyDict
                    //debugPrint(self.currencyDict)
                    //debugPrint(self.dateArray)
                    
                    var tempArray: [String] = []
                    
                    for i in self.dateArray {
                        if self.currencyDict[i] != nil {
                            tempArray.append(i)
                        }
                    }
                    self.dateArray = tempArray
                    self.tableWithResults.reloadData()
                  
                    if let todayDollar = currencyDict[self.dateArray.last!] {
                        if let userDollar = self.notificationTextField.text?.toDouble() {
                            if todayDollar > userDollar {
                                self.showCurrencyAlert()
                            }
                        }
                    }

                    }
                    
                })
            })
        
        
        
    }
    
// http://www.cbr.ru/scripts/XML_dynamic.asp?date_req1=02/03/2001&date_req2=14/03/2001&VAL_NM_RQ=R01235
    
    private func getXML(completion: @escaping([String:Double])->()) {
        
        //Getting date
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_GB")
        dateFormatter.setLocalizedDateFormatFromTemplate("dd/MM/yyyy")
        let nowForUrl = dateFormatter.string(from: now)
        let lastMonthDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        let lastMonthForUrl = dateFormatter.string(from: lastMonthDate!)
        
        //debugPrint(lastMonthForUrl)
        
        //Getting XML using URL Request
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "www.cbr.ru"
        urlComponents.path = "/scripts/XML_dynamic.asp"
        urlComponents.queryItems = [
            URLQueryItem(name: "date_req1", value: lastMonthForUrl),
            URLQueryItem(name: "date_req2", value: nowForUrl),
            URLQueryItem(name: "VAL_NM_RQ", value: "R01235")
        ]
        guard let url = urlComponents.url else { return }
        //debugPrint(url)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            let xml = XMLHash.parse(data)
            var currencyDict: [String:Double] = [:]
        
            //debugPrint(xml)
                //let result = try xml["ValCurs"]["Record"].withAttribute("Date", "28.09.2021")["Value"].element?.text
                //debugPrint(result)
                
                for elem in xml["ValCurs"]["Record"].all {
                    let date = elem.element?.attribute(by: "Date")?.text
                    let currency = elem["Value"].element?.text
                    
                    let comps = currency!.components(separatedBy: ",")
                    let leftPart = Double(comps[0])
                    let rightPart = Double(comps[1])!/pow(10.0, 4.0)
                    let currencyNumber = leftPart! + rightPart
                    
                    currencyDict[date!] = currencyNumber
                    
                }
                //debugPrint(currencyDict)
                self.currencyDict = currencyDict
            completion(currencyDict)
                //debugPrint(self.currencyDict)
        }
        task.resume()
        //debugPrint(self.currencyDict)

        
        //Preparing date for table view presentation
        
        let dateFormatterWithDots = DateFormatter()
        dateFormatterWithDots.locale = Locale(identifier: "ru_RU")
        dateFormatterWithDots.setLocalizedDateFormatFromTemplate("dd.MM.yyyy")
//        let testDate = dateFormatterWithDots.string(from: now)
        
        //debugPrint(testDate)
        
        var tempArray:[String] = []
        
        for i in -30...0 {
            let day =  i
            let previousDate = Calendar.current.date(byAdding: .day, value: day, to: Date())
            let previousDateForArray = dateFormatterWithDots.string(from: previousDate!)
            tempArray.append(previousDateForArray)
        }
        
        
        self.dateArray = tempArray
        //debugPrint(self.dateArray)
        
        //debugPrint(self.currencyDict)
        //debugPrint(self.dateArray.count)
        
        
    }
    
    private func showSuccessAlert() {
        let ac = UIAlertController (
            title: "Успех",
            message: "Новый курс для отслеживания установлен",
            preferredStyle: .alert)
        let action = UIAlertAction(
            title: "Прекрасно",
            style: .default)
        ac.addAction(action)
        self.present(ac,animated: true)
    }
    
    private func showNotSuccessAlert() {
        let ac = UIAlertController (
            title: "Ошибка ввода",
            message: "Необходимо ввести число, а не непонятно что",
            preferredStyle: .alert)
        let action = UIAlertAction(
            title: "Ну ладно, хорошо",
            style: .default)
        ac.addAction(action)
        self.present(ac,animated: true)
    }
    
    private func showCurrencyAlert() {
        let ac = UIAlertController (
            title: "Курс стал выше",
            message: "Курс стал выше",
            preferredStyle: .alert)
        let action = UIAlertAction(
            title: "Отлично",
            style: .default)
        ac.addAction(action)
        self.present(ac,animated: true)
    }

    @IBAction func confirmButtonPressed(_ sender: Any) {
        if let val = notificationTextField.text?.toDouble() {
            userDefaults.set(val, forKey: "track")
            self.showSuccessAlert()
        } else {
            showNotSuccessAlert()
        }
        
    }
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currencyDict.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableWithResults.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = dateArray[indexPath.row] + " : " +  String(self.currencyDict[dateArray[indexPath.row]]!)
 
        return cell
    }
    
}

extension String {
    func toDouble() -> Double? {
        let numberWithDot = self.components(separatedBy: ".")
        let numberWithComma = self.components(separatedBy: ",")
        var comps:[String] = []
        
        if numberWithDot.count > 2 {
            return nil
        } else if numberWithComma.count > 2 {
            return nil
        }
        
        if numberWithDot.count == 0 && numberWithComma.count == 0 {
            return nil
        }
        
        if numberWithDot.count == 1 && numberWithComma.count == 1 {
            comps = numberWithDot
        }
        
        if numberWithDot.count >= 2 && numberWithComma.count >= 2 {
            return nil
        }
        
        if numberWithDot.count == 2 && numberWithComma.count == 1 {
            comps = numberWithDot
        }
        
        if numberWithDot.count == 1 && numberWithComma.count == 2 {
            comps = numberWithComma
        }
        
        debugPrint(comps)
        
        if comps.count == 1 && comps[0] == "" {
            return nil
        }
        
        if comps.count == 2 && (comps[0] == "" || comps[1] == "") {
            return nil
        }
        
        var leftPart = 0.0
        if let l = Double(comps[0]) {
            leftPart = l
        } else {
            return nil
        }
        
        if comps.count == 1 {
            return leftPart
        }
        
        var rightPart = 0.0
        if let r = Int(comps[1]) {
            let power = Double(comps[1].count)
            rightPart = Double(r)/pow(10.0, power)
        } else {
            return nil
        }
        
        return leftPart + rightPart
        
        
    }
}

