/// Copyright (c) 2018年 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

// 网格尺寸
let numColumns = 9
let numRows    = 9

class Level {
  
  
  init(filename: String) {
    // 1 此函数可能返回nil - 它返回一个可选项？ - 并guard用于处理这种情况
    guard let levelData = LevelData.loadFrom(file: filename) else { return }
    // 2
    let tilesArray = levelData.tiles
    // 3 使用 enumerated() 遍历 row 数组
    for (row, rowArray) in tilesArray.enumerated() {
      // 4 SpriteKit（0，0）位于屏幕的底部，所以你必须在这里颠倒行的顺序。您从JSON中读取的第一行对应于2D网格的最后一行。
      let tileRow = numRows - row - 1
      // 5 遍历数组 column 数组
      for (column, value) in rowArray.enumerated() {
        if value == 1 {
          tiles[column, tileRow] = Tile()
        }
      }
    }
  }
  
  private var tiles = Array2D<Tile>(columns: numColumns, rows: numRows)
  
  func tileAt(column: Int, row: Int) -> Tile? {
    precondition(column >= 0 && column < numColumns)
    precondition(row >= 0 && row < numRows)
    return tiles[column, row]
  }
  
  private var cookies = Array2D<Cookie>(columns: numColumns, rows: numRows)
  
  func cookie(atColumn column: Int, row: Int) -> Cookie? {
    // precondition 来验证 Row 与 Column 有效性
    precondition(column >= 0 && column < numColumns)
    precondition(row >= 0 && row < numRows)
    return cookies[column, row]
  }
  
  // 设计代码时遇到的主要困难之一是决定不同对象如何相互通信。在这个游戏中，你通常通过传递一组对象来完成这个任务，通常是Set或Array
  func shuffle() -> Set<Cookie> {
    return createInitialCookies()
  }
  
  // 创建 Cookies 数据
  private func createInitialCookies() -> Set<Cookie> {
    // set 随机排列数据 且数据不会重复
    var set: Set<Cookie> = []
    
    // 1
    for row in 0..<numRows {
      for column in 0..<numColumns {
        
        if tiles[column, row] != nil {
          // 2 随机数据
//          let cookieType = CookieType.random()
          
          // 智能填充数据 3个相同的cookie不能在横竖上连续出现
          var cookieType: CookieType
          repeat {
            cookieType = CookieType.random()
          } while (
            column >= 2 &&
            cookies[column - 1, row]?.cookieType == cookieType &&
            cookies[column - 2, row]?.cookieType == cookieType)
            || (row >= 2 &&
              cookies[column, row - 1]?.cookieType == cookieType &&
              cookies[column, row - 2]?.cookieType == cookieType)
          
          
          // 3
          let cookie = Cookie(column: column, row: row, cookieType: cookieType)
          cookies[column, row] = cookie
          
          // 4
          set.insert(cookie)
        }
      }
    }
    return set
  }
  
  
  func performSwap(_ swap: Swap) {
    let columnA = swap.cookieA.column
    let rowA = swap.cookieA.row
    let columnB = swap.cookieB.column
    let rowB = swap.cookieB.row
    
    cookies[columnA, rowA] = swap.cookieB
    swap.cookieB.column = columnA
    swap.cookieB.row = rowA
    
    cookies[columnB, rowB] = swap.cookieA
    swap.cookieA.column = columnB
    swap.cookieA.row = rowB
  }
  
  
}

