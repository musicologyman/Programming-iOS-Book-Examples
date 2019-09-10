

import UIKit

func delay(_ delay:Double, closure:@escaping ()->()) {
    let when = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}


class RootViewController: UIViewController, UIPageViewControllerDataSource {
    
    weak var pageViewController : UIPageViewController!
    let pep : [String] = ["Manny", "Moe", "Jack"]
    
    static let currentPepBoyRestorationKey = "currentPep"
    var restorationInfo : [AnyHashable:Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("root viewDidLoad")
        
        let proxy = UIPageControl.appearance()
        proxy.pageIndicatorTintColor = UIColor.red.withAlphaComponent(0.6)
        proxy.currentPageIndicatorTintColor = .red
        proxy.backgroundColor = .yellow
        
        
        let pvc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pvc.dataSource = self
        self.addChild(pvc)
        self.view.addSubview(pvc.view)
        
        let (_,f) = self.view.bounds.divided(atDistance: 150, from: .minYEdge)
        pvc.view.frame = f
        pvc.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        pvc.didMove(toParent: self)
        
        let info = self.restorationInfo
        print("info", info as Any)
        
        var page = Pep(pepBoy: self.pep[0])
        let key = Self.currentPepBoyRestorationKey
        if let boy = info?[key] as? String {
            print("root trying to restore", boy)
            page = Pep(pepBoy:boy)
        }
        
        pvc.setViewControllers([page], direction: .forward, animated: false)
        
        self.pageViewController = pvc
        
        // need time to get into the window before presenting next v.c.
        // but no matter what, must destroy restoration info at the end
        let key2 = PepEditorViewController.editingRestorationKey
        if let editing = info?[key2] as? Bool, editing {
            delay(0.1) {
                self.performSegue(withIdentifier: "editThisPepBoy", sender: self)
                self.restorationInfo = nil
            }
        } else {
            self.restorationInfo = nil
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.userActivity = self.view.window?.windowScene?.userActivity
    }
            
    // called automatically because we share this activity with the scene
    // however, at that point any user info in the old activity has been removed!
    override func updateUserActivityState(_ activity: NSUserActivity) {
        super.updateUserActivityState(activity)
        let page = self.pageViewController.viewControllers![0] as! Pep
        let boy = page.boy
        print("root update user activity state", boy)
        let key = Self.currentPepBoyRestorationKey
        activity.addUserInfoEntries(from: [key:boy])
        print(activity.userInfo as Any)
    }
    
    func pageViewController(_ pvc: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? {
        let boy = (vc as! Pep).boy
        let ix = self.pep.firstIndex(of:boy)! + 1
        if ix >= self.pep.count {
            return nil
        }
        return Pep(pepBoy: self.pep[ix])
    }
    func pageViewController(_ pvc: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? {
        let boy = (vc as! Pep).boy
        let ix = self.pep.firstIndex(of:boy)! - 1
        if ix < 0 {
            return nil
        }
        return Pep(pepBoy: self.pep[ix])
    }
    
    // if these methods are implemented, page indicator appears
    
    func presentationCount(for pvc: UIPageViewController) -> Int {
        return self.pep.count
    }
    func presentationIndex(for pvc: UIPageViewController) -> Int {
        let page = pvc.viewControllers![0] as! Pep
        let boy = page.boy
        return self.pep.firstIndex(of:boy)!
    }
    
    @IBSegueAction func showPep(_ coder: NSCoder) -> PepEditorViewController? {
        let pepvc = PepEditorViewController(coder: coder)
        let page = self.pageViewController.viewControllers![0] as! Pep
        let boy = page.boy
        pepvc?.pepName = boy
        pepvc?.restorationInfo = self.restorationInfo
        return pepvc
    }
    
}
