/**
 * GameScene.swift
 * CookieCrunch
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import SpriteKit
import GameplayKit


class GameScene: SKScene {
  // Sound FX
  let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
  let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
  let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
  let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
  let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
  
  // 使用闭包传回消息
  // 这个变量的类型是((Swap) -> Void)?。因为->你可以告诉这是一个闭包或函数。这个闭包或函数将一个Swap对象作为其参数并且不返回任何东西。
  var swipeHandler: ((Swap) -> Void)?
  
  var level: Level!
  
  let tileWidth: CGFloat = 32.0
  let tileHeight: CGFloat = 36.0
  
  // 记录首次碰触的 column row
  private var swipeFromColumn: Int?
  private var swipeFromRow: Int?
  
  // 游戏图层 & cookies 图层
  let gameLayer = SKNode()
  let cookiesLayer = SKNode()
  
  // 图层
  let tilesLayer = SKNode()
  let cropLayer = SKCropNode()
  let maskLayer = SKNode()
  
  // 高亮图层
  private var selectionSprite = SKSpriteNode()
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder) is not used in this app")
  }
  
  override init(size: CGSize) {
    super.init(size: size)
    
    anchorPoint = CGPoint(x: 0.5, y: 0.5)
    
    let background = SKSpriteNode(imageNamed: "Background")
    background.size = size
    addChild(background)
    
    addChild(gameLayer)
  
    let layerPosition = CGPoint(
      x: -tileWidth * CGFloat(numColumns) / 2,
      y: -tileHeight * CGFloat(numRows) / 2)
    
    tilesLayer.position = layerPosition
    maskLayer.position = layerPosition
    cropLayer.maskNode = maskLayer
    gameLayer.addChild(tilesLayer)
    gameLayer.addChild(cropLayer)
    
    cookiesLayer.position = layerPosition
    cropLayer.addChild(cookiesLayer)
    
  }
  
  func addTiles() {
    // 1
    for row in 0..<numRows {
      for column in 0..<numColumns {
        if level.tileAt(column: column, row: row) != nil {
          let tileNode = SKSpriteNode(imageNamed: "MaskTile")
          tileNode.size = CGSize(width: tileWidth, height: tileHeight)
          tileNode.position = pointFor(column: column, row: row)
          maskLayer.addChild(tileNode)
        }
      }
    }
    
    // 2
    for row in 0...numRows {
      for column in 0...numColumns {
        let topLeft     = (column > 0) && (row < numRows)
          && level.tileAt(column: column - 1, row: row) != nil
        let bottomLeft  = (column > 0) && (row > 0)
          && level.tileAt(column: column - 1, row: row - 1) != nil
        let topRight    = (column < numColumns) && (row < numRows)
          && level.tileAt(column: column, row: row) != nil
        let bottomRight = (column < numColumns) && (row > 0)
          && level.tileAt(column: column, row: row - 1) != nil
        
        var value = topLeft.hashValue
        value = value | topRight.hashValue << 1
        value = value | bottomLeft.hashValue << 2
        value = value | bottomRight.hashValue << 3
        
        // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
        if value != 0 && value != 6 && value != 9 {
          let name = String(format: "Tile_%ld", value)
          let tileNode = SKSpriteNode(imageNamed: name)
          tileNode.size = CGSize(width: tileWidth, height: tileHeight)
          var point = pointFor(column: column, row: row)
          point.x -= tileWidth / 2
          point.y -= tileHeight / 2
          tileNode.position = point
          tilesLayer.addChild(tileNode)
        }
      }
    }
  }
  
  func addSprites(for cookies: Set<Cookie>) {
    for cookie in cookies {
      let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
      sprite.size = CGSize(width: tileWidth, height: tileHeight)
      sprite.position = pointFor(column: cookie.column, row: cookie.row)
      cookiesLayer.addChild(sprite)
      cookie.sprite = sprite
    }
  }
  
  private func pointFor(column: Int, row: Int) -> CGPoint {
    return CGPoint(
      x: CGFloat(column) * tileWidth + tileWidth / 2,
      y: CGFloat(row) * tileHeight + tileHeight / 2)
  }
  
  // 转换点坐标
  private func convertPoint(_ point: CGPoint) -> (success: Bool, column: Int, row: Int) {
    if point.x >= 0 && point.x < CGFloat(numColumns) * tileWidth &&
      point.y >= 0 && point.y < CGFloat(numRows) * tileHeight {
      return (true, Int(point.x / tileWidth), Int(point.y / tileHeight))
    } else {
      return (false, 0, 0)  // invalid location
    }
  }
  
  // 记录点选的位置
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 1
    guard let touch = touches.first else { return }
    let location = touch.location(in: cookiesLayer)
    // 2
    let (success, column, row) = convertPoint(location)
    if success {
      // 3
      if let cookie = level.cookie(atColumn: column, row: row) {
        // 4
        swipeFromColumn = column
        swipeFromRow = row
        
        showSelectionIndicator(of: cookie)
        
      }
      
    }
  }
  
  // 获取点选方向
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 1 判断是否有点选 cookie
    guard swipeFromColumn != nil else { return }
    
    // 2 动作过滤
    guard let touch = touches.first else { return }
    let location = touch.location(in: cookiesLayer)
    
    let (success, column, row) = convertPoint(location)
    if success {
      
      // 3 在这里，该方法通过简单地比较新的列和行号码与之前的号码来计算玩家的轻扫方向。请注意，您不允许对角滑动。由于您正在使用else if语句，因此只有一个horizontalDelta或verticalDelta将被设置
      var horizontalDelta = 0, verticalDelta = 0
      if column < swipeFromColumn! {          // swipe left
        horizontalDelta = -1
      } else if column > swipeFromColumn! {   // swipe right
        horizontalDelta = 1
      } else if row < swipeFromRow! {         // swipe down
        verticalDelta = -1
      } else if row > swipeFromRow! {         // swipe up
        verticalDelta = 1
      }
      
      // 4 trySwap(horizontalDelta:verticalDelta:) 只有当玩家从旧方块上跳出时才会被叫到。
      if horizontalDelta != 0 || verticalDelta != 0 {
        // 尝试交换
        trySwap(horizontalDelta: horizontalDelta, verticalDelta: verticalDelta)
        
        hideSelectionIndicator()
        
        // 5 通过swipeFromColumn设回nil，游戏将忽略此滑动动作的其余部分。
        swipeFromColumn = nil
      }
    }
  }
  
  // 为了完整起见，您还应该实现touchesEnded(_:with:)，当用户将手指从屏幕上抬起时会调用
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    swipeFromColumn = nil
    swipeFromRow = nil
    if selectionSprite.parent != nil && swipeFromColumn != nil {
      hideSelectionIndicator()
    }
  }
  // 滑动被取消 （打进电话等情况）
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchesEnded(touches, with: event)
  }
  
  // 判断有效的交换
  private func trySwap(horizontalDelta: Int, verticalDelta: Int) {
    // 1
    let toColumn = swipeFromColumn! + horizontalDelta
    let toRow = swipeFromRow! + verticalDelta
    // 2
    guard toColumn >= 0 && toColumn < numColumns else { return }
    guard toRow >= 0 && toRow < numRows else { return }
    // 3
    if let toCookie = level.cookie(atColumn: toColumn, row: toRow),
      let fromCookie = level.cookie(atColumn: swipeFromColumn!, row: swipeFromRow!) {
      // 4
      print("*** swapping \(fromCookie) with \(toCookie)")
      
      // 5 交换cookie
      // swipeHandler 可能为 nil ，使用可选绑定来解包
      if let handler = swipeHandler {
        let swap = Swap(cookieA: fromCookie, cookieB: toCookie)
        handler(swap)
      }
    }
  }
  
  // 交换动画
  func animate(_ swap: Swap, completion: @escaping () -> Void) {
    let spriteA = swap.cookieA.sprite!
    let spriteB = swap.cookieB.sprite!
    
    spriteA.zPosition = 100
    spriteB.zPosition = 90
    
    let duration: TimeInterval = 0.3
    
    let moveA = SKAction.move(to: spriteB.position, duration: duration)
    moveA.timingMode = .easeOut
    spriteA.run(moveA, completion: completion)
    
    let moveB = SKAction.move(to: spriteA.position, duration: duration)
    moveB.timingMode = .easeOut
    spriteB.run(moveB)
    
    run(swapSound)
  }
  
  // 显示高亮精灵
  func showSelectionIndicator(of cookie: Cookie) {
    if selectionSprite.parent != nil {
      selectionSprite.removeFromParent()
    }
    
    if let sprite = cookie.sprite {
      let texture = SKTexture(imageNamed: cookie.cookieType.highlightedSpriteName)
      selectionSprite.size = CGSize(width: tileWidth, height: tileHeight)
      selectionSprite.run(SKAction.setTexture(texture))
      
      sprite.addChild(selectionSprite)
      selectionSprite.alpha = 1.0
    }
  }
  
  // 隐藏高亮精灵
  func hideSelectionIndicator() {
    selectionSprite.run(SKAction.sequence([
      SKAction.fadeOut(withDuration: 0.3),
      SKAction.removeFromParent()]))
  }
  
  func animateInvalidSwap(_ swap: Swap, completion: @escaping () -> Void) {
    let spriteA = swap.cookieA.sprite!
    let spriteB = swap.cookieB.sprite!
    
    spriteA.zPosition = 100
    spriteB.zPosition = 90
    
    let duration: TimeInterval = 0.2
    
    let moveA = SKAction.move(to: spriteB.position, duration: duration)
    moveA.timingMode = .easeOut
    
    let moveB = SKAction.move(to: spriteA.position, duration: duration)
    moveB.timingMode = .easeOut
    
    spriteA.run(SKAction.sequence([moveA, moveB]), completion: completion)
    spriteB.run(SKAction.sequence([moveB, moveA]))
    
    run(invalidSwapSound)
  }
  
}


