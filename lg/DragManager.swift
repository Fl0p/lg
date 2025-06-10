//
//  DragManager.swift
//  lg
//
//  Created by Flop But on 10/06/2025.
//

import UIKit

class DragManager {
    
    // MARK: - Properties
    
    private weak var targetView: UIView?
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    /// Enables/disables dragging capability
    var isDragEnabled: Bool = true {
        didSet {
            panGestureRecognizer?.isEnabled = isDragEnabled
        }
    }
    
    /// Whether to constrain movement to parent view bounds
    var constrainToSuperview: Bool = true
    
    // MARK: - Initialization
    
    init(targetView: UIView) {
        self.targetView = targetView
        setupDragging()
    }
    
    deinit {
        removeDragging()
    }
    
    // MARK: - Public Methods
    
    func removeDragging() {
        if let gesture = panGestureRecognizer {
            targetView?.removeGestureRecognizer(gesture)
        }
        panGestureRecognizer = nil
    }
    
    // MARK: - Private Methods
    
    private func setupDragging() {
        guard let targetView = targetView else { return }
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        targetView.addGestureRecognizer(panGestureRecognizer!)
        targetView.isUserInteractionEnabled = true
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let targetView = targetView else { return }
        
        let translation = gesture.translation(in: targetView.superview)
        
        switch gesture.state {
        case .changed:
            targetView.center = CGPoint(x: targetView.center.x + translation.x,
                                      y: targetView.center.y + translation.y)
            gesture.setTranslation(.zero, in: targetView.superview)
            
        case .ended:
            if constrainToSuperview {
                constrainToSuperviewBounds()
            }
            
        default:
            break
        }
    }
    
    private func constrainToSuperviewBounds() {
        guard let targetView = targetView,
              let superview = targetView.superview else { return }
        
        let bounds = superview.bounds
        let viewFrame = targetView.frame
        var newCenter = targetView.center
        
        // Check left and right boundaries
        if viewFrame.minX < bounds.minX {
            newCenter.x = viewFrame.width / 2
        } else if viewFrame.maxX > bounds.maxX {
            newCenter.x = bounds.maxX - viewFrame.width / 2
        }
        
        // Check top and bottom boundaries
        if viewFrame.minY < bounds.minY {
            newCenter.y = viewFrame.height / 2
        } else if viewFrame.maxY > bounds.maxY {
            newCenter.y = bounds.maxY - viewFrame.height / 2
        }
        
        // Animate return to screen boundaries if needed
        if newCenter != targetView.center {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                targetView.center = newCenter
            })
        }
    }
}
