//
//  InfoViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-07-13.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class InfoViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var navigationBarItem: UINavigationItem!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var photoDescriptionLabel: UILabel!
    
    var infoTitle: String = "This is the title"
    var infoText: String = "This is the text"
    var infoPhotoDescription: String = "Photo taken at night"
    var infoURLString: String = "https://blahblah.com"
    var infoImage: UIImage?
    
    var screenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    
    let highlightColour = civilColour
    let highlightWords = [
        "day",
        "civil",
        "nautical",
        "astronomical",
        "night",
        "twilight",
        "dusk",
        "dawn"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: fontLight, size: 18)!]
        navigationBar.tintColor = UIColor.whiteColor()
        
        learnMoreButton.addUnderline(UIColor.whiteColor())
        learnMoreButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        
        bottomView.backgroundColor = nauticalColour
        
        textView.contentInset = UIEdgeInsetsZero
        textView.textContainerInset = UIEdgeInsetsZero
        textView.textContainer.lineFragmentPadding = 0

        screenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(sideSwipe))
        screenEdgeRecognizer.edges = .Left
        view.addGestureRecognizer(screenEdgeRecognizer)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationBarItem.title = infoTitle
        textView.attributedText = highlightInfoText(infoText)
        photoDescriptionLabel.text = infoPhotoDescription
        imageView.image = infoImage
        
        textView.scrollRangeToVisible(NSMakeRange(0,0))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        textView.scrollRangeToVisible(NSMakeRange(0,0))
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    func highlightInfoText(text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "\(text) ") // place space at the end of string so all words get highlighted
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: fontRegular, size: 18)!, range: NSMakeRange(0, attributedString.length))
        
        // highlight both lowercase and capitalized words
        for highlightWord in highlightWords {
            attributedString.attributeRangeFor(highlightWord, attributeName: NSForegroundColorAttributeName, attributeValue: highlightColour, atributeSearchType: .All)
            
            let capitalizedWord = highlightWord.capitalizedString
            attributedString.attributeRangeFor(capitalizedWord, attributeName: NSForegroundColorAttributeName, attributeValue: highlightColour, atributeSearchType: .All)
        }
        
        return attributedString
    }
    
    func goBack() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setInfo(info: InfoData) {
        infoTitle = info.title
        infoText = info.text
        infoPhotoDescription = info.photoDescription
        infoImage = info.image
        infoURLString = info.learnMoreURL
    }
    
    @IBAction func learnMoreButtonDidTouch(sender: AnyObject) {
        Analytics.openLearnMore(infoTitle)
        UIApplication.sharedApplication().openURL(NSURL(string: infoURLString)!)
    }
    
    @IBAction func backButtonDidTouch(sender: AnyObject) {
        goBack()
    }
    
    func sideSwipe() {
        goBack()
    }
}