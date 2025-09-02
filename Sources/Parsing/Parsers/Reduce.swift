// TODO: Is there a way for us to allow throwing closures here?
// The Parser protocol is marked as rethrows...

extension Parser where Self.Output: Sequence {
  
  /// Returns a ``Parser`` that reduces the output of a parser into a new ``Parser``
  ///
  /// This method is similar to `Sequence.reduce(_:_:)` in the Swift standard library.
  ///
  /// ```swift
  /// let parser: some Parser<Substring, Int> = Parse {
  ///   Many {
  ///    Int.parser()
  ///    ","
  ///   } .reduce(0) { $0 + $1 }
  /// }
  ///
  /// let input: Substring = "1,2,3,4,5,"
  /// let expected = 15
  ///
  /// let result = parser.parse(&input) // 15
  /// ```
  ///
  /// - Parameter initialResult: The value to use as an initial accumulating value
  /// - Parameter nextPartialResult: The closure to combine elements with the initial result
  /// - Returns: A reduce parser
  public func reduce<NewOutput>(
    _ initialResult: NewOutput,
    _ nextPartialResult: @Sendable @escaping (_ partialResult: NewOutput, _ element: Self.Output.Element) -> NewOutput
  ) -> Parsers.Reduce<Self, NewOutput> {
    .init(upstream: self, initialResult: initialResult, nextPartialResult: nextPartialResult)
  }
  
  /// Returns a ``Parser`` that reduces the output of a parser into new ``Parser``
  ///
  /// This method is similar to `Sequence.reduce(into:_:)` in the Swift standard library.
  ///
  /// ```swift
  /// let parser: some Parser<Substring, Int> = Parse {
  ///   Many {
  ///    Int.parser()
  ///    ","
  ///   } .reduce(0) { $0 += $1 }
  /// }
  ///
  /// let input: Substring = "1,2,3,4,5,"
  /// let expected = 15
  ///
  /// let result = parser.parse(&input) // 15
  /// ```
  ///
  /// - Parameter initialResult: The value to use as an initial accumulating value
  /// - Parameter updateAccumulatingResult: The closure to combine elements with the initial result
  /// - Returns: A reduce parser
  public func reduce<NewOutput>(
    into initialResult: NewOutput,
    _ updateAccumulatingResult: @Sendable @escaping (_ partialResult: inout NewOutput, _ element: Self.Output.Element) -> Void
  ) -> Parsers.InoutReduce<Self, NewOutput> {
    .init(upstream: self, initialResult: initialResult, updateAccumulatingResult: updateAccumulatingResult)
  }
  
}


extension Parsers {
  
  public struct Reduce<Upstream: Parser, NewOutput>: Parser
  where Upstream.Output: Sequence {
    public typealias Element = Upstream.Output.Element
    
    public let upstream: Upstream
    public let initialResult: NewOutput
    public let nextPartialResult: @Sendable (NewOutput, Element) -> NewOutput
    
    @inlinable
    public init(
      upstream: Upstream,
      initialResult: NewOutput,
      nextPartialResult: @Sendable @escaping (NewOutput, Element) -> NewOutput
    ) {
      self.upstream = upstream
      self.initialResult = initialResult
      self.nextPartialResult = nextPartialResult
    }
    
    @inlinable
    @inline(__always)
    public func parse(_ input: inout Upstream.Input) rethrows -> NewOutput {
      try self.upstream.parse(&input).reduce(self.initialResult, self.nextPartialResult)
    }
    
  }
  
  public struct InoutReduce<Upstream: Parser, NewOutput>: Parser
  where Upstream.Output: Sequence {
    public typealias Element = Upstream.Output.Element
    
    public let upstream: Upstream
    public let initialResult: NewOutput
    public let updateAccumulatingResult: @Sendable (inout NewOutput, Element) -> Void
    
    @inlinable
    public init(
      upstream: Upstream,
      initialResult: NewOutput,
      updateAccumulatingResult: @Sendable @escaping (inout NewOutput, Element) -> Void
    ) {
      self.upstream = upstream
      self.initialResult = initialResult
      self.updateAccumulatingResult = updateAccumulatingResult
    }
    
    @inlinable
    @inline(__always)
    public func parse(_ input: inout Upstream.Input) throws -> NewOutput {
      try self.upstream.parse(&input).reduce(into: self.initialResult, self.updateAccumulatingResult)
    }
    
  }
  
}

extension Parsers.Reduce: Sendable where Upstream: Sendable, NewOutput: Sendable { }
extension Parsers.InoutReduce: Sendable where Upstream: Sendable, NewOutput: Sendable { }
