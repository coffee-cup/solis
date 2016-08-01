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
    
    lazy var orderedViewControllers: [UIViewController] = [self.viewControllerWithIdentifier("WDarkViewController"),
                                                           self.viewControllerWithIdentifier("WNotificationsViewController")]
    
    var pageViewController: UIPageViewController!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var currentIndex: Int?
    var pendingIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        pageViewController.delegate = self
        pageViewController.dataSource = self

        if let firstViewController = orderedViewControllers.first {
            pageViewController.setViewControllers([firstViewController],
                               direction: .Forward,
                               animated: true,
                               completion: nil)
        }
        
        view.addSubview(pageViewController.view)
        
        view.bringSubviewToFront(pageControl)
        pageControl.numberOfPages = orderedViewControllers.count
        pageControl.currentPage = 0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func viewControllerWithIdentifier(identifier: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewControllerWithIdentifier(identifier)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
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
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        pendingIndex = orderedViewControllers.indexOf(pendingViewControllers.first!)
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            currentIndex = pendingIndex
            if let index = currentIndex {
                pageControl.currentPage = index
            }
        }
    }
}