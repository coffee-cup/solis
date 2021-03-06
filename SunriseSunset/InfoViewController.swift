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
            [NSAttributedString.Key.font: UIFont(name: fontLight, size: 18)!]
        navigationBar.tintColor = UIColor.white
        
        learnMoreButton.addUnderline(UIColor.white)
        learnMoreButton.setTitleColor(UIColor.white, for: UIControl.State())
        
        bottomView.backgroundColor = nauticalColour
        
        textView.contentInset = UIEdgeInsets.zero
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0

        screenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(sideSwipe))
        screenEdgeRecognizer.edges = .left
        view.addGestureRecognizer(screenEdgeRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationBarItem.title = infoTitle
        textView.attributedText = highlightInfoText(infoText)
        photoDescriptionLabel.text = infoPhotoDescription
        imageView.image = infoImage
        
        textView.scrollRangeToVisible(NSMakeRange(0,0))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.scrollRangeToVisible(NSMakeRange(0,0))
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    func highlightInfoText(_ text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "\(text) ") // place space at the end of string so all words get highlighted
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: fontRegular, size: 18)!, range: NSMakeRange(0, attributedString.length))
        
        // highlight both lowercase and capitalized words
        for highlightWord in highlightWords {
            attributedString.attributeRangeFor(highlightWord, attributeName: NSAttributedString.Key.foregroundColor.rawValue, attributeValue: highlightColour, atributeSearchType: .all)
            
            let capitalizedWord = highlightWord.capitalized
            attributedString.attributeRangeFor(capitalizedWord, attributeName: NSAttributedString.Key.foregroundColor.rawValue, attributeValue: highlightColour, atributeSearchType: .all)
        }
        
        return attributedString
    }
    
    func goBack() {
        dismiss(animated: true, completion: nil)
    }
    
    func setInfo(_ info: InfoData) {
        infoTitle = info.title
        infoText = info.text
        infoPhotoDescription = info.photoDescription
        infoImage = info.image
        infoURLString = info.learnMoreURL
    }
    
    @IBAction func learnMoreButtonDidTouch(_ sender: AnyObject) {
        Analytics.openLearnMore(infoTitle)
        UIApplication.shared.open(URL(string: infoURLString)!, options: [:], completionHandler: nil)
    }
    
    @IBAction func backButtonDidTouch(_ sender: AnyObject) {
        goBack()
    }
    
    @objc func sideSwipe() {
        goBack()
    }
}
