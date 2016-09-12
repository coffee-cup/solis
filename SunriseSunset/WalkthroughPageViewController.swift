//
//  WalkthroughPageViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-07-31.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class WalkthroughPageViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    lazy var orderedViewControllers: [UIViewController] = [self.viewControllerWithIdentifier("WWelcomeViewController"),
                                                           self.viewControllerWithIdentifier("WDarkViewController"),
                                                           self.viewControllerWithIdentifier("WNotificationsViewController"),
                                                           self.viewControllerWithIdentifier("WWidgetViewController")]
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var skipButton: SpringButton!
    @IBOutlet weak var takeOffButton: SpringButton!
    
    var pageViewController: UIPageViewController!
    
    var currentIndex: Int?
    var pendingIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.delegate = self
        pageViewController.dataSource = self

        if let firstViewController = orderedViewControllers.first {
            pageViewController.setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
        
        view.addSubview(pageViewController.view)
        
        view.bringSubview(toFront: takeOffButton)
        view.bringSubview(toFront: skipButton)
        view.bringSubview(toFront: pageControl)
        pageControl.numberOfPages = orderedViewControllers.count
        pageControl.currentPage = 0
        
        takeOffButton.layer.cornerRadius = 2
        takeOffButton.alpha = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func viewControllerWithIdentifier(_ identifier: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: identifier)
    }
    
    func goToMainView() {
        skipButton.animation = "fadeOut"
        skipButton.duration = 0.1
        skipButton.animate()
        
        Defaults.showWalkthrough = false
        
        performSegue(withIdentifier: "MainSegue", sender: nil)
    }
    
    func fadeTakeOffButton(_ alphaValue: CGFloat) {
        UIView.animate(withDuration: alphaValue == 0 ? 0 : 0.25) {
            self.takeOffButton.alpha = alphaValue
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        pendingIndex = orderedViewControllers.index(of: pendingViewControllers.first!)
        fadeTakeOffButton(0)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            currentIndex = pendingIndex
            if let index = currentIndex {
                pageControl.currentPage = index
            }
        }
        if let index = currentIndex {
            if index + 1 == orderedViewControllers.count {
                fadeTakeOffButton(1)
            } else {
                fadeTakeOffButton(0)
            }
        }
    }
    
    @IBAction func skipButtonDidTouch(_ sender: AnyObject) {
        goToMainView()
    }
    
    @IBAction func takeOffButtonDidTouch(_ sender: AnyObject) {
        goToMainView()
    }
}
