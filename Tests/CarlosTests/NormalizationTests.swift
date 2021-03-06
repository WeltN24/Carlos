import Foundation

import Nimble
import Quick

import Carlos
import Combine

struct NormalizedCacheSharedExamplesContext {
  static let CacheToTest = "normalizedCache"
  static let OriginalCache = "originalCache"
}

final class NormalizationSharedExamplesConfiguration: QuickConfiguration {
  override class func configure(_: Configuration) {
    sharedExamples("no-op if the original cache is a BasicCache") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cacheToTest: BasicCache<String, Int>!
      var originalCache: BasicCache<String, Int>!

      beforeEach {
        cacheToTest = sharedExampleContext()[NormalizedCacheSharedExamplesContext.CacheToTest] as? BasicCache<String, Int>
        originalCache = sharedExampleContext()[NormalizedCacheSharedExamplesContext.OriginalCache] as? BasicCache<String, Int>
      }

      it("should have a valid cache to test") {
        expect(cacheToTest).notTo(beNil())
      }

      it("should return the same value for the normalized cache") {
        expect(cacheToTest) === originalCache
      }
    }

    sharedExamples("wrap the original cache into a BasicCache") { (sharedExampleContext: @escaping SharedExampleContext) in
      var cacheToTest: BasicCache<String, Int>!
      var originalCache: CacheLevelFake<String, Int>!
      var cancellable: AnyCancellable?

      beforeEach {
        cacheToTest = sharedExampleContext()[NormalizedCacheSharedExamplesContext.CacheToTest] as? BasicCache<String, Int>
        originalCache = sharedExampleContext()[NormalizedCacheSharedExamplesContext.OriginalCache] as? CacheLevelFake<String, Int>
      }

      afterEach {
        cancellable?.cancel()
        cancellable = nil
      }

      context("when calling get") {
        let key = "key to test"
        var expectedRequest: PassthroughSubject<Int, Error>!

        beforeEach {
          expectedRequest = PassthroughSubject()
          originalCache.getSubject = expectedRequest
          cancellable = cacheToTest.get(key).sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        }

        it("should call the closure") {
          expect(originalCache.numberOfTimesCalledGet) == 1
        }

        it("should pass the right key") {
          expect(originalCache.didGetKey) == key
        }
      }

      context("when calling set") {
        let key = "test key"
        let value = 101

        beforeEach {
          _ = cacheToTest.set(value, forKey: key)
        }

        it("should call the closure") {
          expect(originalCache.numberOfTimesCalledSet) == 1
        }

        it("should pass the right key") {
          expect(originalCache.didSetKey) == key
        }

        it("should pass the right value") {
          expect(originalCache.didSetValue) == value
        }
      }

      context("when calling clear") {
        beforeEach {
          cacheToTest.clear()
        }

        it("should call the closure") {
          expect(originalCache.numberOfTimesCalledClear) == 1
        }
      }

      context("when calling onMemoryWarning") {
        beforeEach {
          cacheToTest.onMemoryWarning()
        }

        it("should call the closure") {
          expect(originalCache.numberOfTimesCalledOnMemoryWarning) == 1
        }
      }
    }
  }
}

final class NormalizationTests: QuickSpec {
  override func spec() {
    var cacheToTest: BasicCache<String, Int>!

    describe("Normalization through the protocol extension") {
      context("when normalizing a BasicCache") {
        var originalCache: BasicCache<String, Int>!
        var keyTransformer: OneWayTransformationBox<String, String>!

        beforeEach {
          keyTransformer = OneWayTransformationBox(transform: { Just($0).setFailureType(to: Error.self).eraseToAnyPublisher() })
          originalCache = CacheLevelFake<String, Int>().transformKeys(keyTransformer)
          cacheToTest = originalCache.normalize()
        }

        itBehavesLike("no-op if the original cache is a BasicCache") {
          [
            NormalizedCacheSharedExamplesContext.OriginalCache: originalCache as Any,
            NormalizedCacheSharedExamplesContext.CacheToTest: cacheToTest as Any
          ]
        }
      }

      context("when normalizing another type of cache") {
        var originalCache: CacheLevelFake<String, Int>!

        beforeEach {
          originalCache = CacheLevelFake()
          cacheToTest = originalCache.normalize()
        }

        itBehavesLike("wrap the original cache into a BasicCache") {
          [
            NormalizedCacheSharedExamplesContext.OriginalCache: originalCache as Any,
            NormalizedCacheSharedExamplesContext.CacheToTest: cacheToTest as Any
          ]
        }
      }
    }
  }
}
