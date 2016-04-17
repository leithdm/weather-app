//
//  CityWeatherViewController.swift
//  TheWeatherApp
//
//  Created by Darren Leith on 16/04/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//

import UIKit

class CityWeatherViewController: UIViewController {
	
	//MARK: properties
	
	var city: City!
	
	//MARK:	outlets
	
	@IBOutlet weak var cityName: UILabel!
	@IBOutlet weak var weatherDescription: UILabel!
	@IBOutlet weak var mainTempValue: UILabel!
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var tableView: UITableView!
	
	
	// MARK: life cycle methods
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// Lay out the collection view so that cells take up 1/4 of the width
		let width = CGRectGetWidth(view.frame) / 4
		let layout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
		layout.itemSize = CGSize(width: width, height: width) //want them to be square
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		cityName.text = city.name
		city.forecast.removeAll()
		
		let parameters = ["q": city.name]
		
		APIWeatherOnline.sharedInstance().taskForResource(parameters) { [unowned self] jsonResult, error in
			
			
			guard error == nil else {
				print("Error searching for cities: \(error!.localizedDescription)")
				return
			}
			
			guard let data = jsonResult["data"] as? NSDictionary else {
				print("Cannot find key 'data' in \(jsonResult)")
				return
			}
			
			guard let current_condition = data["current_condition"] as? [[String:AnyObject]] else {
				print("Cannot find key 'current_condition' in \(data)")
				return
			}
			
			//weather for main display
			for current in current_condition {
				
				//todays temperature in C
				guard let temp_C = current["temp_C"] as? String else {
					print("Cannot find key 'temp_C' in \(current_condition)")
					return
				}
				
				self.performUIUpdatesOnMain({
					self.mainTempValue.text = "\(temp_C)º"
				})
				
				//todays short weather description
				guard let weatherDesc = current["weatherDesc"] as? [[String:AnyObject]] else {
					print("Cannot find key 'weatherDesc' in \(current_condition)")
					return
				}
				
				for description in weatherDesc {
					guard let weatherDescValue = description["value"] as? String else {
						print("Cannot find key 'weatherDesc' in \(weatherDesc)")
						return
				 }
					self.performUIUpdatesOnMain({
						self.weatherDescription.text = weatherDescValue
					})
				}
				
				
				//date, minTemp, maxTemp for each day requested in forecast
				
				guard let weather = data["weather"] as? [[String: AnyObject]] else {
					print("Cannot find key 'weather' in \(data)")
					return
				}
				
				
				for eachDay in weather {
					
					let day = Day()
					
					guard let date = eachDay["date"] as? String else {
						print("Cannot find key 'date' in \(weather)")
						return
					}
					
					guard let maxTempC = eachDay["maxtempC"] as? String else {
						print("Cannot find key 'maxTempC' in \(weather)")
						return
					}
					
					guard let minTempC = eachDay["mintempC"] as? String else {
						print("Cannot find key 'minTempC' in \(weather)")
						return
					}
					
					guard let hourly = eachDay["hourly"] as? [[String: AnyObject]] else {
						print("Cannot find key 'hourly' in \(weather)")
						return
					}
					
					for hour in hourly {
						guard let tempC = hour["tempC"] as? String else {
							print("Cannot find key 'tempC' in \(hourly)")
							return
						}
						day.maxTemp_hours.append(tempC)
						
						/*
						for icon in hour {
						guard let weatherIconUrl = icon["weatherIconUrl"] as? [[String: AnyObject]] else {
						print("Cannot find key 'hourly' in \(weather)")
						return
						}
						}
						*/
						
					}
					
					day.date = date
					day.maxTempC = maxTempC
					day.minTempC = minTempC
					
					self.city.forecast.append(day)
//					self.tempForecast.append(day)
					
					self.performUIUpdatesOnMain({
						self.collectionView.reloadData()
						
						self.tableView.reloadData()
					})
				}
			}
		}
	}
	
	
	// MARK: helper methods
	
	func performUIUpdatesOnMain(updates: () -> Void) {
		dispatch_async(dispatch_get_main_queue()) {
			updates()
		}
	}
	
	func alertViewForError(error: NSError) {
		//
	}
}


//MARK: collection view extension

extension CityWeatherViewController: UICollectionViewDataSource, UICollectionViewDelegate {
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 8
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TodaysForecastCell", forIndexPath: indexPath) as! TodaysForecastCell
		
		if let day = city.forecast.first {
			let maxTempHours = day.maxTemp_hours
			cell.temperature.text = "\(maxTempHours[indexPath.row])º"
			cell.hour.text = day.times[indexPath.row]
		}
		return cell
	}

}

//MARK: table view extension

extension CityWeatherViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
	
		let day = city.forecast[indexPath.row]
		let cell = tableView.dequeueReusableCellWithIdentifier("TableViewCell", forIndexPath: indexPath)
		
		let dayOfWeek = cell.viewWithTag(1001) as! UILabel
		let maxTemp = cell.viewWithTag(1003) as! UILabel
		let minTemp = cell.viewWithTag(1004) as! UILabel
		
		dayOfWeek.text = day.date
		maxTemp.text = day.maxTempC
		minTemp.text = day.minTempC
	
		return cell
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return city.forecast.count
	}

}
