//
//  Copyright © 2020 An Tran. All rights reserved.
//

import UIKit
import LeakDetector
import Combine

class RootViewController: UITableViewController {
    
    @IBAction func backFromLeakingViewController(_ segue: UIStoryboardSegue) {
        LeakDetector.instance.expectViewControllerDellocated(viewController: segue.source)
    }
}

class NotLeakingChildViewController: UIViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func didTapGoBack(_ sender: Any) {
        performSegue(withIdentifier: "goBack", sender: self)
    }
}

class LeakingChildViewController: UIViewController {
        
    var delegate: LeakDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
    
    @IBAction func didTapGoBack(_ sender: Any) {
        performSegue(withIdentifier: "goBack", sender: self)
    }

}

extension LeakingChildViewController: LeakDelegate {
    var viewController: UIViewController {
        self
    }
}