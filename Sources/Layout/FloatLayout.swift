//
//  FloatLayout.swift
//  CollectionKit
//
//  Created by Luke Zhao on 2017-08-31.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

public class FloatLayout<Data>: CollectionLayout<Data> {
  var rootLayout: CollectionLayout<Data>
  var floatingFrames: [(offset: Int, element: CGRect)] = []
  var isFloated: (Int, CGRect) -> Bool

  public init(rootLayout: CollectionLayout<Data>, isFloated: @escaping (Int, CGRect) -> Bool = { i, _ in i % 2 == 0 }) {
    self.rootLayout = rootLayout
    self.isFloated = isFloated
    super.init()
  }

  open override var contentSize: CGSize {
    return rootLayout.contentSize
  }

  override public func _layout(collectionSize: CGSize, dataProvider: CollectionDataProvider<Data>, sizeProvider: @escaping (Int, Data, CGSize) -> CGSize) {
    rootLayout._layout(collectionSize: collectionSize, dataProvider: dataProvider, sizeProvider: sizeProvider)
    floatingFrames = rootLayout.frames.enumerated().filter { isFloated($0.offset, $0.element) }
  }

  var activeFrame: CGRect = .zero
  var topFrameIndex: Int = 0
  public override func visibleIndexes(activeFrame: CGRect) -> [Int] {
    self.activeFrame = activeFrame
    let visibleFrame = activeFrame - CGPoint(x: rootLayout.insets.left, y: rootLayout.insets.top)
    topFrameIndex = floatingFrames.binarySearch { $0.element.minY < visibleFrame.minY } - 1
    if let index = floatingFrames.get(topFrameIndex)?.offset, index >= 0 {
      var oldVisible = rootLayout.visibleIndexes(activeFrame: activeFrame)
      if let index = oldVisible.index(of: index) {
        oldVisible.remove(at: index)
      }
      return oldVisible + [index]
    }
    return rootLayout.visibleIndexes(activeFrame: activeFrame)
  }

  public override func frame(at: Int) -> CGRect {
    let superFrame = rootLayout.frame(at: at)
    if superFrame.minY < activeFrame.minY, let index = floatingFrames.get(topFrameIndex)?.offset, index == at {
      let pushedY = topFrameIndex < floatingFrames.count - 1 ? rootLayout.frame(at: floatingFrames[topFrameIndex + 1].offset).minY - superFrame.height : activeFrame.maxY - superFrame.height
      return CGRect(origin: CGPoint(x: superFrame.minX, y: min(activeFrame.minY, pushedY)), size: superFrame.size)
    }
    return superFrame
  }
}
