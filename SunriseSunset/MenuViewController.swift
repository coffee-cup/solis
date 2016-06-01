//
//  MenuViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-31.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    @IBOutlet weak var menuView: UIView!
    var screenWidth: CGFloat!
    
    let SoftAnimationDuration: NSTimeInterval = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        screenWidth = view.frame.width
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
