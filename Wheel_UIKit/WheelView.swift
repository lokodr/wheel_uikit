//
//  WheelView.swift
//  wheel_uikit
//
//  Created by Lynn on 2023-08-16.
//

import Foundation
import UIKit

// MARK: - ScrollableDelegate Protocol

protocol ScrollableDelegate: AnyObject {
    
    func didScroll(toPercentage percentage: CGFloat)
}

// MARK: - Scrollable Protocol

protocol Scrollable {
    
    var delegate: ScrollableDelegate? { get set }
    func scroll(toPercentage percentage: CGFloat)
}

// MARK: - WheelView

class WheelView: UIView {
    
    private let button = UIButton()
    private var buttonLabel: UILabel!
    private var angle: CGFloat = 0
    private let initialAngleDegrees: CGFloat = -90
    weak var delegate: ScrollableDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 240, height: 240))
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    
    func setup() {
        
        angle = Helpers.degreesToRadians(initialAngleDegrees)
        addWheel()
        addButton()
    }
    
    
    func addWheel() {
        
        let ringLayer = CALayer()
        ringLayer.bounds = self.bounds
        ringLayer.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        ringLayer.cornerRadius = self.frame.width / 2
        ringLayer.borderWidth = 24
        ringLayer.borderColor = UIColor.white.cgColor
        self.layer.addSublayer(ringLayer) // Add the ring layer to the view's layer
    }
    
    
    func addButton() {
        
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        button.center = calculateButtonPosition()
        button.layer.cornerRadius = button.frame.width / 2
        button.backgroundColor = Helpers.themeColour
        button.accessibilityLabel = "Rotate wheel to desired position"
        button.accessibilityTraits = .button
        
        // White circle inside button
        let circleLayer = CAShapeLayer()
        let circlePath = UIBezierPath(arcCenter:
                                        CGPoint(x: button.frame.width / 2,
                                                y: button.frame.height / 2),
                                      radius: button.frame.width / 2 - 14,
                                      startAngle: 0,
                                      endAngle: 2 * .pi,
                                      clockwise: true)
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.white.cgColor
        button.layer.addSublayer(circleLayer)
        
        // Label that displays rotation in degrees
        buttonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: button.frame.width, height: button.frame.height))
        buttonLabel.textAlignment = .center
        buttonLabel.textColor = Helpers.themeColour
        buttonLabel.font = UIFont.systemFont(ofSize: 16)
        buttonLabel.text = "0°"
        button.addSubview(buttonLabel)
        
        self.addSubview(button)
        
        //Add gesture handlers
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        button.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        button.addGestureRecognizer(tapGesture)
    }
    
    
    func calculateButtonPosition(_ newAngle: CGFloat? = nil) -> CGPoint {
        
        let angle: CGFloat = newAngle ?? angle
        let centerOfWheel = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let buttonMargin = button.frame.width / 4
        let radius = (frame.width - buttonMargin) / 2
        
        let buttonCenterX = centerOfWheel.x + radius * cos(angle)
        let buttonCenterY = centerOfWheel.y + radius * sin(angle)
        
        return CGPoint(x: buttonCenterX, y: buttonCenterY)
    }
}

// MARK: - Gesture Handlers

extension WheelView {
    
    @objc func handleTapGesture() {
        
        let randomAngle = CGFloat.random(in: 15...180) //generate a random new angle
        let randomAngleRadians = Helpers.degreesToRadians(randomAngle) //convert new angle from degrees to radians
        let fullCircle: CGFloat = 2 * .pi
        let newAngle = (angle + randomAngleRadians).truncatingRemainder(dividingBy: fullCircle) //prevent angle (sum of current angle and new random angle) from exceeding 360 degrees
        
        let centerOfWheel = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let radius = (frame.width - button.frame.width / 4) / 2 // radius from the center of the wheel to the center of the button
        
        let path = UIBezierPath(arcCenter: centerOfWheel, radius: radius, startAngle: angle, endAngle: newAngle, clockwise: true)
        
        //create an animation object
        let animationDuration = 0.004 * randomAngle
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = path.cgPath
        animation.duration = animationDuration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        CATransaction.begin() //begin the animation
        CATransaction.setCompletionBlock { //execute this closure when the animation completes
            self.button.center = self.calculateButtonPosition(newAngle)
            self.button.layer.removeAnimation(forKey: "rotate")
        }
        
        //add animation to button layer
        button.layer.add(animation, forKey: "rotate")
        
        angle = newAngle
        let degrees = (Helpers.radiansToDegrees(angle) + 90).truncatingRemainder(dividingBy: 360)
        buttonLabel.text = "\(Int(degrees))°"
        self.scroll(toPercentage: degrees/360) //call delegate method
        CATransaction.commit() //finalize the animation
    }
    
    
    @objc func handlePanGesture(_ panGesture: UIPanGestureRecognizer) {
        
        let location = panGesture.location(in: self)
        button.center = calculateButtonPosition()
        
        let centerOfWheel = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        angle = atan2(location.y - centerOfWheel.y, location.x - centerOfWheel.x)
        let degrees = (angle * 180 / .pi + 90 + 360).truncatingRemainder(dividingBy: 360)
        buttonLabel.text = "\(Int(degrees))°"
        
        self.scroll(toPercentage: degrees/360)
    }
}


// MARK: - Scrollable Protocol Extension

extension WheelView: Scrollable {
    
    func scroll(toPercentage percentage: CGFloat) {
        
        self.delegate?.didScroll(toPercentage: percentage)
    }
}
