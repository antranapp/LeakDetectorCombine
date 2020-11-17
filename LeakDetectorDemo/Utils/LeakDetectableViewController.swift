//
//  LeakDetectableViewController.swift
//  LeakDetectorDemo
//
//  Created by An Tran on 16/11/20.
//

import UIKit
import Combine
import LeakDetector

class LeakDetectableViewController: UIViewController {
    
    var leakSubscribtion: AnyCancellable?
    
    func executeLeakDetector(for object: AnyObject) {
        leakSubscribtion = LeakDetector.instance.expectDeallocate(object: object).sink {}
    }

    func executeLeakDetector(for viewController: UIViewController) {
        leakSubscribtion = LeakDetector.instance.expectViewControllerDellocated(viewController: viewController).sink {}
    }
}

class LeakDetectableTableViewController: UITableViewController {
    
    var leakSubscribtion: AnyCancellable?
    
    func executeLeakDetector(for object: AnyObject) {
        leakSubscribtion = LeakDetector.instance.expectDeallocate(object: object).sink {}
    }

    func executeLeakDetector(for viewController: UIViewController) {
        leakSubscribtion = LeakDetector.instance.expectViewControllerDellocated(viewController: viewController).sink {}
    }
}