//
// Copyright © 2020 An Tran. All rights reserved.
//

import Foundation
import UIKit

class NoLeakDispatchAsyncViewController1: UIViewController {

    private let queue = DispatchQueue.main

    override func viewDidLoad() {
        super.viewDidLoad()

        queue.async {
            self.view.tag = 111
        }
    }
}

class NoLeakDispatchAsyncViewController2: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.async {
            self.view.tag = 111
        }
    }
}
