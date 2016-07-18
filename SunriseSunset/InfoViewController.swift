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
    
    var infoTitle: String = "This is the title"
    var infoText: String = "This is the text"
    var infoURLString: String = "https://blahblah.com"
    var infoImage: UIImage?
    
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationBarItem.title = infoTitle
        textView.text = infoText
        imageView.image = infoImage
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    func goBack() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setInfo(info: InfoData) {
        infoTitle = info.title
        infoText = info.text
        infoImage = info.image
        infoURLString = info.learnMoreURL
    }
    
    @IBAction func backButtonDidTouch(sender: AnyObject) {
        goBack()
    }
}