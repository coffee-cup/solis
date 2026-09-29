//
//  SunArea.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-08-06.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class SunArea: UIView {
    
    var parentView: UIView!
    var nameLabel: UILabel!
    
    var topConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!
    
    var nameLeftConstraint: NSLayoutConstraint!
    
    var gradientLayer: CAGradientLayer!
    
    var colour: UIColor!
    
    var colours: [CGColor]?
    var locations: [Float]?

    // Rebuilds the colour stops from the current palette after a theme change.
    var colourBuilder: (@MainActor () -> [CGColor])?
    
    
    var firstLoad = true
    
    let NameHorizontalPadding: CGFloat = 20
    
    override init (frame : CGRect) {
        super.init(frame : frame)
    }
    
    convenience init(colour: UIColor) {
        self.init(frame: .zero)
        self.colour = colour
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func createArea(_ parentView: UIView) {
        self.parentView = parentView

        translatesAutoresizingMaskIntoConstraints = false

        parentView.addSubview(self)

        // Area View

        let viewHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": self])
        topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: parentView, attribute: .top, multiplier: 1, constant: 0)
        heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)

        NSLayoutConstraint.activate(viewHorizontalConstraints + [topConstraint, heightConstraint])

        gradientLayer = CAGradientLayer()
        layer.addSublayer(gradientLayer)
        gradientLayer.frame = frame

        if let locations = locations {
            gradientLayer.locations = locations as [NSNumber]?
        } else {
            gradientLayer.locations = [
                0,
                0.2,
                0.8,
                1
            ]
        }

        if let colours = colours {
            gradientLayer.colors = colours
        } else {
            gradientLayer.colors = [
                colour.withAlphaComponent(0.1).cgColor,
                colour.cgColor,
                colour.cgColor,
                colour.withAlphaComponent(0.1).cgColor
            ]
        }

        // Hide view initially
        alpha = 0
    }
    
    func refreshColours() {
        guard let colourBuilder else { return }
        colours = colourBuilder()
        gradientLayer.colors = colours
    }

    func fadeOutView() {
        UIView.animate(withDuration: 0.5) {
            self.alpha = 0
        }
    }
    
    func fadeInView() {
        if firstLoad {
            return
        }
        UIView.animate(withDuration: 0.5) {
            self.alpha = 1
        }
    }
    
    func updateAreaWithPercents(_ minPercent: Float, maxPercent: Float) {
        if !minPercent.isFinite || !maxPercent.isFinite {
            return
        }
        
        if minPercent < 0 || minPercent > 1 || maxPercent < minPercent || maxPercent > 1 {
            return
        }
        
        let top = parentView.frame.height * CGFloat(minPercent)
        let bottom = parentView.frame.height * CGFloat(maxPercent)
        let height = bottom - top
        
        topConstraint.constant = top
        heightConstraint.constant = height
        
        self.gradientLayer.frame = CGRect(x: 0, y: 0, width: parentView.frame.width, height: height)
        UIView.animate(withDuration: 0.5, animations: {
            self.parentView.layoutIfNeeded()
            }, completion: { finished in
            if self.firstLoad {
                self.firstLoad = false
                self.fadeInView()
            }
        })
    }
    
}
