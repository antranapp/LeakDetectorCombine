//
//  Copyright © UBER. All rights reserved.
//  Copyright © 2019 duyquang91. All rights reserved.
//  Copyright © 2020 An Tran. All rights reserved.
//

import Foundation
import UIKit
import Combine

public struct LeakDefaultExpectationTime {
    public static let deallocation: TimeInterval = 1
    public static let viewDisappear: TimeInterval = 5
}

public enum LeakDetectionStatus {
    case inProgress, didComplete
}

/// The handle for a scheduled leak detection.
public protocol LeakDetectionHandle {
    
    /// Cancel the scheduled detection.
    func cancel()
}

/// An expectation based leak detector, that allows an object's owner to set an expectation that an owned object to be
/// deallocated within a time frame.
///
/// A `Router` that owns an `Interactor` might for example expect its `Interactor` be deallocated when the `Router`
/// itself is deallocated. If the interactor does not deallocate in time, a runtime assert is triggered, along with
/// critical logging.
public class LeakDetector {
    
    /// The singleton instance.
    public static let instance = LeakDetector()
    
    var cancellables = Set<AnyCancellable>()

    /// The status of leak detection.
    ///
    /// The status changes between InProgress and DidComplete as units register for new detections, cancel existing
    /// detections, and existing detections complete.
    public var status: AnyPublisher<LeakDetectionStatus, Never> {
        return $expectationCount
            .map { expectationCount in
                expectationCount > 0 ? LeakDetectionStatus.inProgress : LeakDetectionStatus.didComplete
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Sets up an expectation for the given object to be deallocated within the given time.
    ///
    /// - parameter object: The object to track for deallocation.
    /// - parameter inTime: The time the given object is expected to be deallocated within.
    /// - returns: The handle that can be used to cancel the expectation.
    @discardableResult
    public func expectDeallocate(object: AnyObject, inTime time: TimeInterval = LeakDefaultExpectationTime.deallocation) -> LeakDetectionHandle {
        expectationCount = expectationCount + 1

        let objectDescription = String(describing: object)
        let objectId = String(ObjectIdentifier(object).hashValue) as NSString
        trackingObjects.setObject(object, forKey: objectId)

        let handle = LeakDetectionHandleImpl {
            self.expectationCount = self.expectationCount - 1
        }

        var cancellable: AnyCancellable!
        cancellable = LeakExecutor.execute(withDelay: time) {
            // Retain the handle so we can check for the cancelled status. Also cannot use the cancellable
            // concurrency API since the returned handle must be retained to ensure closure is executed.
            if !handle.cancelled {
                let didDeallocate = (self.trackingObjects.object(forKey: objectId) == nil)
                let message = "<\(objectDescription): \(objectId)> has leaked. Objects are expected to be deallocated at this time: \(self.trackingObjects)"

                if LeakDetector.isEnabled {
                    assert(didDeallocate, message)
                } else if !didDeallocate {
                    print("Leak detection is disabled. This should only be used for debugging purposes.")
                    print("\(message)")
                }
            }

            self.expectationCount = self.expectationCount - 1
        }
        .handleEvents(receiveCompletion: { [weak self] _ in
            cancellable.cancel()
            self?.cancellables.remove(cancellable)
            cancellable = nil
        })
        .sink(receiveValue: { _ in })
        
        cancellables.insert(cancellable)

        return handle
    }

    /// Sets up an expectation for the given view controller to disappear within the given time.
    ///
    /// - parameter viewController: The `UIViewController` expected to disappear.
    /// - parameter inTime: The time the given view controller is expected to disappear.
    /// - returns: The handle that can be used to cancel the expectation.
    @discardableResult
    public func expectViewControllerDisappear(viewController: UIViewController, inTime time: TimeInterval = LeakDefaultExpectationTime.viewDisappear) -> LeakDetectionHandle {
        expectationCount = expectationCount + 1

        let handle = LeakDetectionHandleImpl {
            self.expectationCount = self.expectationCount - 1
        }

        var cancellable: AnyCancellable!
        cancellable = LeakExecutor.execute(withDelay: time) { [weak viewController] in
            // Retain the handle so we can check for the cancelled status. Also cannot use the cancellable
            // concurrency API since the returned handle must be retained to ensure closure is executed.
            if let viewController = viewController, !handle.cancelled {
                let viewDidDisappear = (!viewController.isViewLoaded || viewController.view.window == nil)
                let message = "\(viewController) appearance has leaked. Objects are expected to be deallocated at this time: \(self.trackingObjects)"

                if LeakDetector.isEnabled {
                    assert(viewDidDisappear, message)
                } else if !viewDidDisappear {
                    print("Leak detection is disabled. This should only be used for debugging purposes.")
                    print("\(message)")
                }
            }

            self.expectationCount = self.expectationCount - 1
        }
        .handleEvents(receiveCompletion: { [weak self] _ in
            cancellable.cancel()
            self?.cancellables.remove(cancellable)
            cancellable = nil
        })
        .sink(receiveValue: { _ in })

        cancellables.insert(cancellable)

        return handle
    }

    // MARK: - Internal Interface

    /// Enable leak detector. Default is false.
    ///
    /// We should enable leak detector in Debug mode only.
    public static var isEnabled: Bool = false

    /// Enable leak detector for core components such as RadixViewController, ServiceBasedViewModel, ... Default is false.
    ///
    /// We should enable in Debug mode only.
    public static var isCoreComponentsEnabled = false

    #if DEBUG
    /// Reset the state of Leak Detector, internal for UI test only.
    func reset() {
        trackingObjects.removeAllObjects()
        expectationCount = 0
    }
    #endif

    // MARK: - Private Interface

    private let trackingObjects = NSMapTable<AnyObject, AnyObject>.strongToWeakObjects()
    @Published private var expectationCount: Int = 0

    private init() {}
}

private class LeakDetectionHandleImpl: LeakDetectionHandle {
    var cancelled: Bool {
        return _cancelled
    }

    @Published private var _cancelled: Bool = false
    
    let cancelClosure: (() -> Void)?

    init(cancelClosure: (() -> Void)? = nil) {
        self.cancelClosure = cancelClosure
    }

    func cancel() {
        _cancelled = true
        cancelClosure?()
    }
}
