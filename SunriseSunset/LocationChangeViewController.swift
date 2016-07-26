//
//  LocationChangeViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-17.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps

class LocationChangeViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchTextField: UISearchBar!
    @IBOutlet weak var searchTableView: UITableView!
    
    var hideStatusBar = true
    
    lazy var placesClient = GMSPlacesClient()
    lazy var filter = GMSAutocompleteFilter()
    
    var places: [SunPlace] = []
    var placeHistory: [SunPlace] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTextField.delegate = self
        searchTextField.showsCancelButton = true
        
        searchTableView.delegate = self
        searchTableView.dataSource = self
        
        filter.type = .City
        
        if let locationHistory = Location.getLocationHistory() {
            placeHistory = locationHistory
        } else {
            placeHistory = []
        }
        
        Bus.subscribeEvent(.ShowStatusBar, observer: self, selector: #selector(showStatusBar))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        searchTextField.becomeFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        Bus.removeSubscriptions(self)
    }
    
    override func prefersStatusBarHidden() -> Bool {
//        return hideStatusBar
        return false
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Fade
    }
    
    func showStatusBar() {
        hideStatusBar = false
        setNeedsStatusBarAppearanceUpdate()
        view.layoutIfNeeded()
        view.layoutSubviews()
    }
    
    func isSearching() -> Bool {
        if let text = searchTextField.text {
            return !text.isEmpty
        }
        return false
    }
    
    func goBack() {
        searchTextField.resignFirstResponder()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func updateWithSearchResults(results: [GMSAutocompletePrediction]) {
        places = results.map { result in
            return SunPlace(primary: result.attributedPrimaryText.string, secondary: (result.attributedSecondaryText?.string)!, placeID: result.placeID!)
        }
        searchTableView.reloadData()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            placesClient.autocompleteQuery(searchText, bounds: nil, filter: filter) { results, error in
                guard error == nil else {
                    print("Autocomplete error \(error)")
                    return
                }
                
                self.updateWithSearchResults(results!)
            }
        } else {
            searchTableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        goBack()
    }
    
    @IBAction func cancelButtonDidTouch(sender: AnyObject) {
//        goBack()
    }
    
    @IBAction func setButtonDidTouch(sender: AnyObject) {
        goBack()
    }
    
    // Table View
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        goBack()
        
        if indexPath.row == 0 {
            print("Selected current place")
            Location.selectLocation(true, location: nil, name: nil, sunplace: nil)
        } else {
            var sunplace: SunPlace!
            if isSearching() {
                sunplace = places[indexPath.row - 1]
                let placeID = sunplace.placeID
                placesClient.lookUpPlaceID(placeID) { googlePlace, error in
                    guard error == nil else {
                        print("PlaceID lookup error \(error)")
                        return
                    }
                    
                    guard let coordinate = googlePlace?.coordinate else {
                        return
                    }
                    
                    guard let _ = googlePlace?.name else {
                        return
                    }
                    
                    sunplace.location = coordinate
                    Location.selectLocation(false, location: coordinate, name: sunplace.primary, sunplace: sunplace)
                }
            } else {
                sunplace = placeHistory[indexPath.row - 1]
                Location.selectLocation(false, location: sunplace.location, name: sunplace.primary, sunplace: sunplace)
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching() ? places.count + 1 : placeHistory.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if indexPath.row == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("CurrentPlaceCell")
            
            if let locationName = Location.getCurrentLocationName() {
                let locationLabel = cell.viewWithTag(3)! as! UILabel
                locationLabel.text = locationName
            }
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("PlaceCell")!
            
            var sunplace: SunPlace!
            if isSearching() {
                sunplace = places[indexPath.row - 1]
            } else {
                sunplace = placeHistory[indexPath.row - 1]
            }
            
            let cityLabel = cell.viewWithTag(1)! as! UILabel
            let stateCountryLabel = cell.viewWithTag(2)! as! UILabel
            
            cityLabel.text = sunplace.primary
            stateCountryLabel.text = sunplace.secondary
        }
        return cell
    }
    
}
