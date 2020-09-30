//
//  SwipingPhotosController.swift
//  TinderCloneFireStoreLBTA
//
//  Created by Alok Acharya on 5/4/20.
//  Copyright © 2020 Alok Acharya. All rights reserved.
//

import UIKit

class SwipingPhotosController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate{
    
    var cardViewModel: CardViewModel! {
        didSet{
            print(cardViewModel.attributedString)
            controllers = cardViewModel.imageUrls.map({ (imageUrl) -> UIViewController in
                let photoController = PhotoController(imageURl: imageUrl)
                return photoController
            })
            
            setViewControllers([controllers.first!], direction: .forward, animated: false)
            
            
            setupBarViews()
        }
    }
    
    fileprivate let barsStackView = UIStackView(arrangedSubviews: [])
    fileprivate let deselectedBarColor = UIColor(white: 0, alpha: 0.1)
    
    fileprivate func setupBarViews(){
        cardViewModel.imageUrls.forEach { (_) in
            let barView = UIView()
            barView.backgroundColor = deselectedBarColor
            barView.layer.cornerRadius = 2
            barsStackView.addArrangedSubview(barView)
        }
        barsStackView.arrangedSubviews.first?.backgroundColor = .white
        barsStackView.spacing = 4
        barsStackView.distribution = .fillEqually
        
        view.addSubview(barsStackView)
        
        barsStackView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 8, left: 8, bottom: 0, right: 8), size: .init(width: 0, height: 4))
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let currentPhotoController = viewControllers?.first
        if let index = controllers.firstIndex(where: {$0 == currentPhotoController}){
            barsStackView.arrangedSubviews.forEach({$0.backgroundColor = deselectedBarColor})
            barsStackView.arrangedSubviews[index].backgroundColor = .white
        }
        
    }

    var controllers = [UIViewController]() // Blank array of type uiviewcontroller
  
    
    fileprivate let isCardViewMode: Bool
    
    init(isCardViewMode: Bool = false){
        self.isCardViewMode = isCardViewMode
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        dataSource = self
        
        
        view.backgroundColor = .white
        
        if isCardViewMode {
            disableSwipingAbility()
        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:))))
    }
    
    @objc fileprivate func handleTap(gesture: UIGestureRecognizer){
        let currentController = viewControllers!.first!
        if let index = controllers.firstIndex(of: currentController) {
            barsStackView.arrangedSubviews.forEach({$0.backgroundColor = deselectedBarColor})
            
            if gesture.location(in: self.view).x > view.frame.width/2{
                let nextIndex = min(index + 1, controllers.count - 1)
                let nextController = controllers[nextIndex]
                setViewControllers([nextController], direction: .forward, animated: false)

                barsStackView.arrangedSubviews[nextIndex].backgroundColor = .white
            }else{
                let prevIndex = max(0, index - 1)
                let prevController = controllers[prevIndex]
                setViewControllers([prevController], direction: .forward, animated: false)

                barsStackView.arrangedSubviews[prevIndex].backgroundColor = .white
            }
            
            
        }
    }
    
    fileprivate func disableSwipingAbility(){
        view.subviews.forEach { (v) in
            if let v = v as? UIScrollView {
                v.isScrollEnabled = false
            }
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = self.controllers.firstIndex(where: {$0 == viewController}) ?? 0
        if index == 0 { return nil }
        return controllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = self.controllers.firstIndex(where: {$0 == viewController}) ?? 0
        if index == controllers.count - 1 {return nil}
        return controllers[index + 1]
    }


}

class PhotoController: UIViewController {
    
    let imageView = UIImageView()
    
    //provide an initilizer that takes a url instead
    init(imageURl: String){
        if let url = URL(string: imageURl){
            imageView.sd_setImage(with: url)
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.addSubview(imageView)
        imageView.fillSuperview()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
