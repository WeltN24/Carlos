import Foundation

import Nimble
import Quick

import Carlos
import Combine

final class BasicFetcherTests: QuickSpec {
  override func spec() {
    describe("BasicFetcher") {
      var fetcher: BasicFetcher<String, Int>!
      var numberOfTimesCalledGet = 0
      var didGetKey: String?
      var getSubject: PassthroughSubject<Int, Error>!

      var cancellable: AnyCancellable?

      beforeEach {
        numberOfTimesCalledGet = 0
        getSubject = PassthroughSubject()

        fetcher = BasicFetcher<String, Int>(
          getClosure: { key in
            didGetKey = key
            numberOfTimesCalledGet += 1

            return getSubject.eraseToAnyPublisher()
          }
        )
      }

      afterEach {
        cancellable?.cancel()
        cancellable = nil
      }

      context("when calling get") {
        let key = "key to test"
        var succeeded: Int?
        var failed: Error?
        var canceled: Bool!

        beforeEach {
          canceled = false
          failed = nil
          succeeded = nil

          cancellable = fetcher.get(key)
            .handleEvents(receiveCancel: { canceled = true })
            .sink(receiveCompletion: { completion in
              if case let .failure(error) = completion {
                failed = error
              }
            }, receiveValue: { succeeded = $0 })
        }

        it("should call the closure") {
          expect(numberOfTimesCalledGet) == 1
        }

        it("should pass the right key") {
          expect(didGetKey) == key
        }

        context("when the get closure succeeds") {
          let value = 3

          beforeEach {
            getSubject.send(value)
          }

          it("should succeed the future") {
            expect(succeeded) == value
          }
        }

        context("when the get clousure is canceled") {
          beforeEach {
            cancellable?.cancel()
          }

          it("should cancel the future") {
            expect(canceled) == true
          }
        }

        context("when the get closure fails") {
          let error = TestError.anotherError

          beforeEach {
            getSubject.send(completion: .failure(error))
          }

          it("should fail the future") {
            expect(failed as? TestError) == error
          }
        }
      }

      context("when calling set") {
        var succeeded: Bool!

        beforeEach {
          succeeded = false

          _ = fetcher.set(0, forKey: "")
            .sink(receiveCompletion: { _ in
              succeeded = true
            }, receiveValue: {})
        }

        it("should immediately succeed the future") {
          expect(succeeded) == true
        }
      }
    }
  }
}
