//
//  InfiniteScrollView.swift
//  StreetScroller
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/7/14.
//
//
/*
     File: InfiniteScrollView.h
     File: InfiniteScrollView.m
 Abstract: This view tiles UILabel instances to give the effect of infinite scrolling side to side.
  Version: 1.2

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2013 Apple Inc. All Rights Reserved.

 */

import UIKit

@objc(InfiniteScrollView)
class InfiniteScrollView: UIScrollView, UIScrollViewDelegate {
    
    private var visibleLabels: [UILabel] = []
    private let labelContainerView: UIView
    
    
    required init?(coder aDecoder: NSCoder) {
        labelContainerView = UIView()
        super.init(coder: aDecoder)
        self.contentSize = CGSizeMake(5000, self.frame.size.height)
        
        self.labelContainerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height/2)
        self.addSubview(self.labelContainerView)
        
        self.labelContainerView.userInteractionEnabled = false
        
        // hide horizontal scroll indicator so our recentering trick is not revealed
        self.showsHorizontalScrollIndicator = false
    }
    
    
    //MARK: - Layout
    
    // recenter content periodically to achieve impression of infinite scrolling
    private func recenterIfNecessary() {
        let currentOffset = self.contentOffset
        let contentWidth = self.contentSize.width
        let centerOffsetX = (contentWidth - self.bounds.size.width) / 2.0
        let distanceFromCenter = abs(currentOffset.x - centerOffsetX)
        
        if distanceFromCenter > (contentWidth / 4.0) {
            self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y)
            
            // move content by the same amount so it appears to stay still
            for label in self.visibleLabels {
                var center = self.labelContainerView.convertPoint(label.center, toView: self)
                center.x += (centerOffsetX - currentOffset.x)
                label.center = self.convertPoint(center, toView: self.labelContainerView)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.recenterIfNecessary()
        
        // tile content in visible bounds
        let visibleBounds = self.convertRect(self.bounds, toView: self.labelContainerView)
        let minimumVisibleX = CGRectGetMinX(visibleBounds)
        let maximumVisibleX = CGRectGetMaxX(visibleBounds)
        
        self.tileLabelsFromMinX(minimumVisibleX, toMaxX: maximumVisibleX)
    }
    
    
    //MARK: - Label Tiling
    
    private func insertLabel() -> UILabel {
        let label = UILabel(frame: CGRectMake(0, 0, 500, 80))
        label.numberOfLines = 3
        label.text = "1024 Block Street\nShaffer, CA\n95014"
        self.labelContainerView.addSubview(label)
        
        return label
    }
    
    private func placeNewLabelOnRight(rightEdge: CGFloat) -> CGFloat {
        let label = self.insertLabel()
        self.visibleLabels.append(label) // add rightmost label at the end of the array
        
        var frame = label.frame
        frame.origin.x = rightEdge
        frame.origin.y = self.labelContainerView.bounds.size.height - frame.size.height
        label.frame = frame
        
        return CGRectGetMaxX(frame)
    }
    
    private func placeNewLabelOnLeft(leftEdge: CGFloat) -> CGFloat {
        let label = self.insertLabel()
        self.visibleLabels.insert(label, atIndex: 0) // add leftmost label at the beginning of the array
        
        var frame = label.frame
        frame.origin.x = leftEdge - frame.size.width
        frame.origin.y = self.labelContainerView.bounds.size.height - frame.size.height
        label.frame = frame
        
        return CGRectGetMinX(frame)
    }
    
    private func tileLabelsFromMinX(minimumVisibleX: CGFloat, toMaxX maximumVisibleX: CGFloat) {
        // the upcoming tiling logic depends on there already being at least one label in the visibleLabels array, so
        // to kick off the tiling we need to make sure there's at least one label
        if self.visibleLabels.isEmpty {
            self.placeNewLabelOnRight(minimumVisibleX)
        }
        
        // add labels that are missing on right side
        let lastLabel = self.visibleLabels.last!
        var rightEdge = CGRectGetMaxX(lastLabel.frame)
        while rightEdge < maximumVisibleX {
            rightEdge = self.placeNewLabelOnRight(rightEdge)
        }
        
        // add labels that are missing on left side
        let firstLabel = self.visibleLabels[0]
        var leftEdge = CGRectGetMinX(firstLabel.frame)
        while leftEdge > minimumVisibleX {
            leftEdge = self.placeNewLabelOnLeft(leftEdge)
        }
        
        // remove labels that have fallen off right edge
        while let lastLabel = self.visibleLabels.last
            where lastLabel.frame.origin.x > maximumVisibleX {
                lastLabel.removeFromSuperview()
                self.visibleLabels.removeLast()
        }
        
        // remove labels that have fallen off left edge
        while let firstLabel = self.visibleLabels.first
            where CGRectGetMaxX(firstLabel.frame) < minimumVisibleX {
                firstLabel.removeFromSuperview()
                self.visibleLabels.removeFirst()
        }
    }
    
}