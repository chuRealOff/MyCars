//
//  ViewController.swift
//  MyCars
//
//  Created by Ivan Akulov on 08/02/20.
//  Copyright © 2020 Ivan Akulov. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var car: Car!
    var context: NSManagedObjectContext!
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
    
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            updateSegmentedControl()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getDataFromFile()
        
        
    }
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        updateSegmentedControl()
        segmentedControl.selectedSegmentTintColor = .white
        
        let whiteTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let blackTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        
        UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAttributes, for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAttributes, for: .normal)
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        car.timesDriven += 1
        car.lastStarted = Date()
        
        do {
            if context.hasChanges {
                try context.save()
            }
            insertDataFrom(selectedCar: car )
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func rateItPressed(_ sender: UIButton) {
        let ac = UIAlertController(title: "Rate it", message: "Rate this car please", preferredStyle: .alert)
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            if let text = ac.textFields?.first?.text {
                self.update(rating: (text as NSString).doubleValue)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        ac.addTextField { tf in
            tf.keyboardType = .numberPad
        }
        
        ac.addAction(rateAction)
        ac.addAction(cancelAction)
        present(ac, animated: true)
    }
    
    private func updateSegmentedControl() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        if let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex) {
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark)
        }
        
        do {
            let results = try context.fetch(fetchRequest)
            car = results.first
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func update(rating: Double) {
        car.rating = rating
        
        do {
            if context.hasChanges {
                try context.save()
            }
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            let ac = UIAlertController(title: "Wrong value", message: "Incorrect input", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default)
            
            ac.addAction(action)
            present(ac, animated: true)
            print(error.localizedDescription)
        }
        
    }
    
    private func insertDataFrom(selectedCar car: Car) {
        if let carImageData = car.imageData {
            carImageView.image = UIImage(data: carImageData)
        }
        markLabel.text = car.mark
        modelLabel.text = car.model
        myChoiceImageView.isHidden = !(car.myChoice)
        ratingLabel.text = "Rating: \(car.rating) / 10"
        numberOfTripsLabel.text = "Number of trips: \(car.timesDriven)"
        
        if let carLastStarted = car.lastStarted {
            lastTimeStartedLabel.text = "Last time started: \(dateFormatter.string(from: carLastStarted))"
            
            segmentedControl.backgroundColor = car.tintColor as? UIColor
        }
    }
    
    private func getDataFromFile() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark != nil")
        
        var records = 0
        
        do {
            records = try context.count(for: fetchRequest)
            print("Is data there already?")
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        guard records == 0 else { return }
        
        guard let filePath = Bundle.main.path(forResource: "data", ofType: "plist"),
              let dataArray = NSArray(contentsOfFile: filePath) else { return }
        
        for dictionary in dataArray {
            guard let entity = NSEntityDescription.entity(forEntityName: "Car", in: context) else { return }
            let car = NSManagedObject(entity: entity, insertInto: context) as! Car
            
            
            let carDictionary = dictionary as! [String: AnyObject]
            car.mark = carDictionary["mark"] as? String
            car.model = carDictionary["model"] as? String
            car.rating = carDictionary["rating"] as! Double
            car.lastStarted = carDictionary["lastStarted"] as? Date
            car.timesDriven = carDictionary["timesDriven"] as! Int16
            car.myChoice = carDictionary["myChoice"] as! Bool
            
            guard let imageName = carDictionary["imageName"] as? String else { return }
            let image = UIImage(named: imageName)
            let imageData = image?.pngData()
            car.imageData = imageData
            
            if let colorDictionary = carDictionary["tintColor"] as? [String: Float] {
                car.tintColor = getColor(colorDictionary: colorDictionary)
            }
        }
    }
    
    private func getColor(colorDictionary: [String: Float]) -> UIColor {
        guard let red = colorDictionary["red"],
              let green = colorDictionary["green"],
              let blue = colorDictionary["blue"] else { return UIColor() }
        return UIColor(red: CGFloat(red / 255), green: CGFloat(green / 255), blue: CGFloat(blue / 255), alpha: 1.0)
    }
}

