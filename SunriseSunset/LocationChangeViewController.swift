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
    
    let defaults = Defaults.defaults
    
    var notificationPlaceDirty = false
    var newNotificationSunPlace: SunPlace?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTextField.delegate = self
        searchTextField.showsCancelButton = true
        
        searchTableView.delegate = self
        searchTableView.dataSource = self
        
        filter.type = .city
        
        if let locationHistory = SunLocation.getLocationHistory() {
            placeHistory = locationHistory
        } else {
            placeHistory = []
        }
        
        Bus.subscribeEvent(.showStatusBar, observer: self, selector: #selector(showStatusBar))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchTextField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        Bus.removeSubscriptions(self)
    }
    
    override var prefersStatusBarHidden : Bool {
//        return hideStatusBar
        return false
    }
    
    override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return UIStatusBarAnimation.fade
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
        if notificationPlaceDirty {
            Bus.sendMessage(.changeNotificationPlace, data: nil)
            
            if let newNotificationSunPlace = newNotificationSunPlace {
                Analytics.setNotificationPlace(false, sunPlace: newNotificationSunPlace)
            } else {
                Analytics.setNotificationPlace(true, sunPlace: nil)
            }
        }
        searchTextField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    func updateWithSearchResults(_ results: [GMSAutocompletePrediction]) {
        places = results.map { result in
            return SunPlace(primary: result.attributedPrimaryText.string, secondary: (result.attributedSecondaryText?.string)!, placeID: result.placeID!)
        }
        searchTableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
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
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        goBack()
    }
    
    @IBAction func cancelButtonDidTouch(_ sender: AnyObject) {
//        goBack()
    }
    
    @IBAction func setButtonDidTouch(_ sender: AnyObject) {
        goBack()
    }
    
    // Table View
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        goBack()
        
        if (indexPath as NSIndexPath).row == 0 {
            SunLocation.selectLocation(true, location: nil, name: nil, sunplace: nil)
            Analytics.selectLocation(true, sunPlace: nil)
        } else {
            var sunplace: SunPlace!
            if isSearching() {
                sunplace = places[(indexPath as NSIndexPath).row - 1]
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
                    
                    print("\(sunplace.primary) - \(coordinate)")
                    
                    SunLocation.selectLocation(false, location: coordinate, name: sunplace.primary, sunplace: sunplace)
                    Analytics.selectLocation(false, sunPlace: sunplace)
                }
            } else {
                sunplace = placeHistory[(indexPath as NSIndexPath).row - 1]
                SunLocation.selectLocation(false, location: sunplace.location, name: sunplace.primary, sunplace: sunplace)
                Analytics.selectLocation(false, sunPlace: sunplace)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching() ? places.count + 1 : placeHistory.count + 1
    }
    
    func getNotificationPlaceID() -> String? {
        if let sunPlaceString = defaults.object(forKey: DefaultKey.notificationPlace.description) as? String {
            if sunPlaceString != "" {
                if let sunPlace = SunPlace.sunPlaceFromString(sunPlaceString) {
                    return sunPlace.placeID
                }
            }
        }
        return nil
    }
    
    func setNotificationSunPlace(_ sunPlace: SunPlace?) {
        sunPlace?.isNotification = true
        let sunPlaceString = sunPlace == nil ? "" : sunPlace?.toString
        defaults.set(sunPlaceString, forKey: DefaultKey.notificationPlace.description)
        
        newNotificationSunPlace = sunPlace
    }
    
    func bellButtonDidTouch(_ bellButton: BellButton) {
        if bellButton.useCurrentLocation {
            setNotificationSunPlace(nil)
        } else {
            if let sunPlace = bellButton.sunPlace {
                setNotificationSunPlace(sunPlace)
            }
        }
        notificationPlaceDirty = true
        searchTableView.reloadData()
    }
    
    func setBellButton(_ button: BellButton, sunPlace: SunPlace?) {
        button.setImage(UIImage(named: "bell_grey"), for: UIControlState())
        button.setImage(UIImage(named: "bell_red"), for: .selected)
        button.sunPlace = sunPlace
        
        let placeId: String? = getNotificationPlaceID()
        
        button.isSelected = false
        if let sunPlace = sunPlace {
            // custom notification
            if placeId != nil && placeId! == sunPlace.placeID {
                button.isSelected = true
            }
        } else {
            // current location notification
            if placeId == nil {
                button.isSelected = true
            }
        }
        
        button.addTarget(self, action: #selector(bellButtonDidTouch), for: .touchUpInside)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if (indexPath as NSIndexPath).row == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "CurrentPlaceCell")
            
            if let locationName = SunLocation.getCurrentLocationName() {
                let locationLabel = cell.viewWithTag(3)! as! UILabel
                let bellButton = cell.viewWithTag(4)! as! BellButton
                
                setBellButton(bellButton, sunPlace: nil)
                locationLabel.text = locationName
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell")!
            
            var sunplace: SunPlace!
            if isSearching() {
                sunplace = places[(indexPath as NSIndexPath).row - 1]
            } else {
                sunplace = placeHistory[(indexPath as NSIndexPath).row - 1]
            }
            
            let cityLabel = cell.viewWithTag(1)! as! UILabel
            let stateCountryLabel = cell.viewWithTag(2)! as! UILabel
            let bellButton = cell.viewWithTag(4)! as! BellButton
            
            if !isSearching() {
                setBellButton(bellButton, sunPlace: sunplace)
                bellButton.isHidden = false
            } else {
                bellButton.isHidden = true
            }
            cityLabel.text = sunplace.primary
            stateCountryLabel.text = sunplace.secondary
        }
        return cell
    }
    
}
