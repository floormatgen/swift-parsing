import Parsing
import XCTest

final class ReduceTests: XCTestCase {
  
  func testReduce() throws {
    var input: Substring = "1,2,3,4,5,"
    let expected = 1 + 2 + 3 + 4 + 5
    
    let parser: some Parser<Substring, Int> = Parse {
      Many {
        Int.parser()
        ","
      } .reduce(0) { $0 + $1 }
    }
    
    XCTAssertEqual(try parser.parse(&input), expected)
  }
  
  func testInoutReduce() throws {
    var input: Substring = "a,b,c,d,e,f,g,"
    let expected = "abcdefg"
    
    let parser: some Parser<Substring, String> = Parse {
      Many {
        CharacterSet.letters
        ","
      } .reduce(into: "") { $0 += $1 }
    }
    
    XCTAssertEqual(try parser.parse(&input), expected)
  }
  
  func testReduceWithComplexInput() throws {
    var input: Substring = "1*3:2*2:3*1:"
    let expected = 10
    
    let parser: some Parser<Substring, Int> = Parse {
      Many {
        Int.parser()
        "*"
        Int.parser()
        ":"
      } .reduce(0) { $0 + ($1.0 * $1.1) }
    }
    
    XCTAssertEqual(try parser.parse(&input), expected)
  }
  
}
