//
// Copyright © 2020 An Tran. All rights reserved.
//

import Foundation
import UIKit

class NoLeakNonEscapingViewController: ChildViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // handler is `non escaping`.
        let handler = {
            self.view.tag = 111
        }
        
        callBlock(handler)
    }
    
    func callBlock(_ block: () -> Void) {
        block()
    }
}
