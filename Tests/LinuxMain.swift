#if os(Linux)

import XCTest
@testable import StrandTestSuite

XCTMain([
    testCase(StrandTests.allTests)
])

#endif
