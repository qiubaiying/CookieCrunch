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
  var level: Level!
  let tilesLayer = SKNode()
  
  let tileWidth: CGFloat = 32.0
  let tileHeight: CGFloat = 36.0
  
  // 记录首次碰触的 column row
  private var swipeFromColumn: Int?
  private var swipeFromRow: Int?
  
  let gameLayer = SKNode()
  let cookiesLayer = SKNode()
  
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
    gameLayer.addChild(tilesLayer)
    
    cookiesLayer.position = layerPosition
    gameLayer.addChild(cookiesLayer)
    
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
  
  func addTiles() {
    for row in 0..<numRows {
      for column in 0..<numColumns {
        if level.tileAt(column: column, row: row) != nil {
          let tileNode = SKSpriteNode(imageNamed: "Tile")
          tileNode.size = CGSize(width: tileWidth, height: tileHeight)
          tileNode.position = pointFor(column: column, row: row)
          tilesLayer.addChild(tileNode)
        }
      }
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
        trySwap(horizontalDelta: horizontalDelta, verticalDelta: verticalDelta)
        
        // 5 通过swipeFromColumn设回nil，游戏将忽略此滑动动作的其余部分。
        swipeFromColumn = nil
      }
    }
  }
  
  // 为了完整起见，您还应该实现touchesEnded(_:with:)，当用户将手指从屏幕上抬起时会调用
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    swipeFromColumn = nil
    swipeFromRow = nil
  }
  // 滑动被取消 （打进电话等情况）
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchesEnded(touches, with: event)
  }
  
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
    }
  }
  
}


