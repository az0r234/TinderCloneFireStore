//
//  ViewController.swift
//  SwipeMatchFirestoreLBTA
//
//  Created by Brian Voong on 10/31/18.
//  Copyright © 2018 Brian Voong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import JGProgressHUD
import FirebaseAuth

class HomeController: UIViewController, SettingsControllerDelegate, LoginControllerDelegate, CardViewDelegate{
    
    let topStackView = TopNavigationStackView()
    let cardsDeckView = UIView()
    let bottomControls = HomeBottomControlsStackView()
    
    var cardViewModels = [CardViewModel]() // empty array
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topStackView.settingsButton.addTarget(self, action: #selector(handleSettings), for: .touchUpInside)
        topStackView.messageButton.addTarget(self, action: #selector(handleMessages), for: .touchUpInside)
        bottomControls.refreshButton.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        bottomControls.likeButton.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        bottomControls.dislikeButton.addTarget(self, action: #selector(handleDislike), for: .touchUpInside)
        
        setupLayout()
        fetchCurrentUser()
    }
    
    @objc fileprivate func handleMessages(){
        let vc = MatchesMessagesController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //you want to kick the user out when they logout
        if Auth.auth().currentUser == nil{
            let registrationController = RegistrationController()
            registrationController.delegate = self
            let navController = UINavigationController(rootViewController: registrationController)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true, completion: nil)
        }
    }
    
    func didFinishLoggingIn() {
        fetchCurrentUser()
    }
    
    fileprivate var user: User?
    fileprivate let hud = JGProgressHUD(style: .dark)
    
    func fetchCurrentUser() {
        hud.textLabel.text = "Loading"
        hud.show(in: view)
        
        cardsDeckView.subviews.forEach({$0.removeFromSuperview()})
        
        Firestore.firestore().fetchCurrentUser { (user, error) in
            if let err = error{
                print("Error fetching user, ",err)
                return
            }
            self.hud.dismiss()
            self.user = user
            self.fetchSwipes()
        }
        
    }
    
    var swipes = [String: Int]()
    
    fileprivate func fetchSwipes(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let query = Firestore.firestore().collection("swipes").document(uid)
        query.getDocument { (snapshot, err) in
            if let err = err{
                print("Failed to fetch swipes",err)
                return
            }
            
            guard let data = snapshot?.data() as? [String: Int] else { return }
            self.swipes = data
            
            self.fetchUsersFromFirestore()
            
        }
        
    }
    
    @objc fileprivate func handleRefresh() {
        cardsDeckView.subviews.forEach{($0.removeFromSuperview())}
        fetchUsersFromFirestore()
    }
    
    
    
    var lastFetchedUser: User?
    
    fileprivate func fetchUsersFromFirestore() {
        
        let minAge = user?.minSeekingAge ?? SettingsController.defaultMinSeekingAge
        let maxAge = user?.maxSeekingAge ?? SettingsController.defaultMaxSeekingAge
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Fetching Users"
        hud.show(in: view)
        
        let query = Firestore.firestore().collection("users").whereField("age", isGreaterThanOrEqualTo: minAge).whereField("age", isLessThanOrEqualTo: maxAge).limit(to: 10)
        
        topCardView = nil
        query.getDocuments { (snapshot, err) in
            if let err = err {
                print("Failed to fetch users:", err)
            }
            hud.dismiss()
            //we are going to set up the nextCardView relationship for all cards somehow
            var previousCardView: CardView?
            
            snapshot?.documents.forEach({ (documentSnapshot) in
                let userDictionary = documentSnapshot.data()
                
                let user = User(dictionary: userDictionary)
                self.users[user.uid ?? ""] = user
                
                let isNotCurrentUser = user.uid != Auth.auth().currentUser?.uid
                //                let hasNotSwipedBefore = self.swipes[user.uid!] == nil
                let hasNotSwipedBefore = true
                if isNotCurrentUser && hasNotSwipedBefore{
                    let cardView = self.setupCardFromUser(user: user)
                    
                    previousCardView?.nextCardView = cardView
                    previousCardView = cardView
                    
                    if self.topCardView == nil{
                        self.topCardView = cardView
                    }
                }
            })
        }
    }
    
    var users = [String: User]()
    
    //linked list
    var topCardView: CardView?
    
    @objc func handleLike(){
        saveSwipeToFireStore(didLike: 1)
        performSwipeAnimation(translation: 700, angle: 15)
    }
    
    @objc func handleDislike(){
        saveSwipeToFireStore(didLike: 0)
        performSwipeAnimation(translation: -700, angle: -15)
    }
    
    fileprivate func saveSwipeToFireStore(didLike: Int){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let cardUID = topCardView?.cardViewModel.uid else {return}
        
        
        let documentData = [cardUID: didLike]
        
        
        Firestore.firestore().collection("swipes").document(uid).getDocument { (snapshot, err) in
            if let err = err {
                print("FAiled to fetch swiped document", err)
                return
            }
            
            if snapshot?.exists == true {
                Firestore.firestore().collection("swipes").document(uid).updateData(documentData) { (err) in
                    if let err = err{
                        print("Failed to save swipe data: ", err)
                        return
                    }
                    
                    print("Successfully updated swipe ...")
                    
                    if didLike == 1 {
                        self.checkIfMatchExists(cardUID: cardUID)
                    }
                }
            }else{
                Firestore.firestore().collection("swipes").document(uid).setData(documentData) { (err) in
                    if let err = err{
                        print("Failed to save swipe data: ", err)
                        return
                    }
                    
                    print("Successfully saved swiped...")
                    
                    if didLike == 1 {
                        self.checkIfMatchExists(cardUID: cardUID)
                    }
                }
            }
        }
    }
    
    fileprivate func checkIfMatchExists(cardUID: String){
        //How to detect match between users
        print("Detecting match")
        
        Firestore.firestore().collection("swipes").document(cardUID).getDocument { (snapshot, err) in
            if let err = err {
                print("Failed to fetch document for card user:", err)
                return
            }
            
            guard let data = snapshot?.data() else { return }
            
            
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            let hasMatched = data[uid] as? Int == 1
            if hasMatched{
                self.presentMatchView(cardUID: cardUID)
                
                guard let cardUser = self.users[cardUID] else { return }
                
                let data = ["name": cardUser.name ?? "", "profileImageUrl": cardUser.imageUrl1 ?? "", "uid": cardUID, "timestamp": Timestamp(date: Date())] as [String : Any]
                
                Firestore.firestore().collection("matches_messages").document(uid).collection("matches").document(cardUID).setData(data) { (err) in
                    if let err = err {
                        print("Failed to save match info ",err)
                    }
                }
                
                
                guard let currentUser = self.user else { return }
                
                let otherMatchData = ["name": currentUser.name ?? "", "profileImageUrl": currentUser.imageUrl1 ?? "", "uid": cardUID, "timestamp": Timestamp(date: Date())] as [String : Any]
                
                Firestore.firestore().collection("matches_messages").document(cardUID).collection("matches").document(uid).setData(otherMatchData) { (err) in
                    if let err = err {
                        print("Failed to save match info ",err)
                    }
                }
                
            }
        }
    }
    
    fileprivate func presentMatchView(cardUID: String){
        let matchView = MatchView()
        matchView.cardUID = cardUID
        matchView.currentUser = self.user
        view.addSubview(matchView)
        matchView.fillSuperview()
    }
    
    fileprivate func performSwipeAnimation(translation: CGFloat, angle: CGFloat){
        
        let duration = 0.5
        
        let translationAnimation = CABasicAnimation(keyPath: "position.x")
        translationAnimation.toValue = translation
        translationAnimation.duration = duration
        translationAnimation.fillMode = .forwards
        translationAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        translationAnimation.isRemovedOnCompletion = false
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = angle * CGFloat.pi / 180
        rotationAnimation.duration = duration
        
        let cardView = topCardView
        topCardView = cardView?.nextCardView
        
        CATransaction.setCompletionBlock {
            cardView?.removeFromSuperview()
            cardView?.subviews.forEach({ (v) in
                v.removeFromSuperview()
            })
        }
        
        cardView?.layer.add(translationAnimation, forKey: "translation")
        cardView?.layer.add(rotationAnimation, forKey: "rotation")
        CATransaction.commit()
    }
    
    func didRemoveCard(cardView: CardView) {
        self.topCardView?.removeFromSuperview()
        self.topCardView = self.topCardView?.nextCardView
        print("test")
    }
    
    
    
    
    fileprivate func setupCardFromUser(user: User) -> CardView {
        let cardView = CardView(frame: .zero)
        cardView.delegate = self
        cardView.cardViewModel = user.toCardViewModel()
        cardsDeckView.addSubview(cardView)
        cardsDeckView.sendSubviewToBack(cardView)
        cardView.fillSuperview()
        return cardView
    }
    
    @objc func handleSettings() {
        let settingsController = SettingsController()
        settingsController.delegate = self
        let navController = UINavigationController(rootViewController: settingsController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    func didTapMoreInfo(cardViewModel: CardViewModel) {
        //        print("Home Controller: ", cardViewModel.attributedString)
        let userDetailController = UserDetailsController()
        userDetailController.cardViewModel = cardViewModel
        userDetailController.modalPresentationStyle = .fullScreen
        present(userDetailController, animated: true, completion: nil)
    }
    
    
    func didSaveSettings() {
        fetchCurrentUser()
    }
    
    
    fileprivate func setupFirestoreUserCards() {
        cardViewModels.forEach { (cardVM) in
            let cardView = CardView(frame: .zero)
            cardView.cardViewModel = cardVM
            cardsDeckView.addSubview(cardView)
            cardView.fillSuperview()
        }
    }
    
    // MARK:- Fileprivate
    
    fileprivate func setupLayout() {
        view.backgroundColor = .white
        cardsDeckView.backgroundColor = .gray
        let overallStackView = UIStackView(arrangedSubviews: [topStackView, cardsDeckView, bottomControls])
        overallStackView.axis = .vertical
        view.addSubview(overallStackView)
        overallStackView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
        overallStackView.isLayoutMarginsRelativeArrangement = true
        overallStackView.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)
        
        overallStackView.bringSubviewToFront(cardsDeckView)
    }
    
}
