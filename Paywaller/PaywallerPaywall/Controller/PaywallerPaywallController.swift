//
//  PaywallerPaywallController.swift
//  NeonLongOnboardingPlayground
//
//  Created by Tuna Öztürk on 19.11.2023.
//

import Foundation
import UIKit
import Adapty
import NeonSDK

@available(iOS 15.0, *)
public class PaywallerPaywallController : UIViewController{
    let scrollView = UIScrollView()
    let mainStack = UIStackView()
    let contentView = UIView()
    let label = UILabel()
    let gradientLayer = CAGradientLayer()
    let paywallBackgroundView = UIView()
    let legalView = NeonLegalView()
    let continueButton = NeonBouncingButton()
    let planManager = PaywallerPaywallPlanManager()
    public var paywallManager = PaywallerPaywallManager()
    public override func viewDidLoad() {
        super.viewDidLoad()
       
      
        configureUI()
        addSections()
        setDelegates()
        packageFetched()
        configureNotifications()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        logPaywallView()
    }
    public override func viewDidLayoutSubviews() {
        if let lastSubview = mainStack.subviews.last{
            scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: lastSubview.frame.maxY + 150)
            contentView.frame.size = scrollView.contentSize
        }
        
        updateGradientLayerFrame(gradientLayer: gradientLayer, paywallBackgroundView: paywallBackgroundView)
        }
       
    func configureUI(){
        view.backgroundColor = paywallManager.constants.backgroundColor
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
      
        
        
        scrollView.addSubview(contentView)
        
        contentView.addSubview(mainStack)
        mainStack.spacing = 0
        mainStack.axis = .vertical
        mainStack.distribution = .equalSpacing
        mainStack.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(paywallManager.constants.horizontalPadding)
      
        }

       
        view.addSubview(continueButton)
        continueButton.layer.cornerRadius = paywallManager.constants.cornerRadius
        continueButton.backgroundColor = paywallManager.constants.mainColor
        continueButton.titleLabel?.font = Font.custom(size: 16, fontWeight: .SemiBold)
        continueButton.addTarget(self, action: #selector(continueButtonClicked), for: .touchUpInside)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.setTitleColor(paywallManager.constants.ctaButtonTextColor, for: .normal)
        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(paywallManager.constants.horizontalPadding + paywallManager.constants.ctaButtonHorizontalPadding)
            make.height.equalTo(60)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
        }
        
     
        
        
        view.addSubview(paywallBackgroundView)
        view.bringSubviewToFront(continueButton)
        paywallBackgroundView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(continueButton.snp.top).offset(-50)
        }
        addGradientToPaywallBackground()
        
        
        if !paywallManager.constants.isPaymentSheetActive{
            configureLegalView()
            continueButton.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(paywallManager.constants.horizontalPadding + paywallManager.constants.ctaButtonHorizontalPadding)
                make.height.equalTo(60)
                make.bottom.equalTo(view.safeAreaLayoutGuide).inset(40)
            }
        }
     
        
        
    }
    
    
    func configureLegalView(){
        
        
        legalView.restoreButtonClicked = { [self] in
            PaywallerPaywallPurchaseManager.restore(paywallManager: paywallManager, controller: self){ [self] in
                
                for section in mainStack.subviews{
                    if let planSection = section as? PaywallerPaywallVideoPlayerView{
                        planSection.deinitPlayer()
                    }
                }
                
                paywallManager.delegate?.restored(from: self)
            } completionFailure: {
                
            }
        }
        if let termsURL = paywallManager.constants.termsURL, let privacyURL = paywallManager.constants.privacyURL{
            legalView.termsURL = termsURL
            legalView.privacyURL = privacyURL
        }else{
            legalView.configureLegalController(onVC: self, backgroundColor: paywallManager.constants.backgroundColor, headerColor: paywallManager.constants.mainColor, titleColor: paywallManager.constants.ctaButtonTextColor, textColor: paywallManager.constants.primaryTextColor)
        }
        legalView.textColor = paywallManager.constants.primaryTextColor
        view.addSubview(legalView)
        legalView.snp.makeConstraints { make in
            make.top.equalTo(continueButton.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(paywallManager.constants.horizontalPadding)
            make.height.equalTo(70)
        }
    }
    func addGradientToPaywallBackground() {
       
        gradientLayer.colors = [paywallManager.constants.backgroundColor.withAlphaComponent(0).cgColor, paywallManager.constants.backgroundColor.cgColor]
        gradientLayer.locations = [0, 0.5]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        paywallBackgroundView.layer.insertSublayer(gradientLayer, at: 0)
      
    }


    @objc func continueButtonClicked(){
        
        vibrate(style: .heavy)
        if paywallManager.constants.isPaymentSheetActive{
            let paymentSheetController = PaywallerPaywallPaymentSheetController()
            paymentSheetController.paywallManager = paywallManager
            self.present(paymentSheetController, animated: true, completion: nil)
        }else{
            PaywallerPaywallPurchaseManager.subscribe(paywallManager: paywallManager) { [self] in
                
                for section in mainStack.subviews{
                    if let planSection = section as? PaywallerPaywallVideoPlayerView{
                        planSection.deinitPlayer()
                    }
                }
                
                paywallManager.delegate?.purchased(from: self, identifier:  paywallManager.constants.selectedPlan.productIdentifier)
            }
        }
       
    }
    func updateGradientLayerFrame(gradientLayer: CAGradientLayer, paywallBackgroundView: UIView) {
        gradientLayer.frame = paywallBackgroundView.bounds
    }
    func addSections(){

        let btnCross = UIButton()
        
        let closeButtonAppearanceDuration = paywallManager.constants.closeButtonDelay
        if closeButtonAppearanceDuration != 0{
            btnCross.isHidden = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(closeButtonAppearanceDuration) , execute: {
            btnCross.isHidden = false
        })
        
        
        
        btnCross.tintColor = paywallManager.constants.primaryTextColor
        btnCross.setImage(NeonSymbols.xmark, for: .normal)
        btnCross.addTarget(self, action: #selector(btnCrossClicked), for: .touchUpInside)
        scrollView.addSubview(btnCross)
        btnCross.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.width.height.equalTo(50)
            make.left.equalToSuperview().offset(20)
        }
       
        
        for section in paywallManager.sections{
            switch section.type {
            case .custom(let view):
                mainStack.addArrangedSubview(view)
                break
            default :
                mainStack.addArrangedSubview(section.view)
                break
            }
        }
        
        

    }
    
    @objc func btnCrossClicked(){
        
        for section in mainStack.subviews{
            if let planSection = section as? PaywallerPaywallVideoPlayerView{
                planSection.deinitPlayer()
            }
        }
        
        paywallManager.delegate?.dismissed(from: self)
    }
    
    func setDelegates(){
          AdaptyManager.delegate = self
          RevenueCatManager.delegate = self
    }
    
    func configureNotifications(){
        NeonNotificationCenter.observe(id: "plan_selected") {
            self.setPlanViews()
            self.fetchSelectedPlanDetails()
        }
    }
    
    func logPaywallView(){
        let provider = paywallManager.constants.provider
        
        switch provider {
        case .adapty(let placementID):
            if let paywall = AdaptyManager.getPaywall(placementID: placementID){
                Adapty.logShowPaywall(paywall)
            }
            break
        default :
            break
        }
    }
    func fetchSelectedPlanDetails(){
        if let product = planManager.fetchProduct(for: paywallManager.constants.selectedPlan){
            let ctaTextWhenSelected = paywallManager.constants.selectedPlan.ctaTextWhenSelected
                
                planManager.getIntroductoryPeriod(product: product, completion: { duration, price in
                    if let duration, duration != 0{
                        if let price{
                            
                            if ctaTextWhenSelected != nil && ctaTextWhenSelected != "" {
                                var ctaText = ctaTextWhenSelected ?? ""
                                ctaText = ctaText.replacingOccurrences(of: "{price}", with: "\(price)")
                                ctaText = ctaText.replacingOccurrences(of: "{introductory_duration}", with: "\(duration)")
                                continueButton.setTitle(ctaText, for: .normal)
                            }else{
                                continueButton.setTitle("Subscribe for \(price) for first \(duration) days", for: .normal)
                            }
                            
                            
                        }else{
                            
                            if ctaTextWhenSelected != nil && ctaTextWhenSelected != "" {
                                var ctaText = ctaTextWhenSelected ?? ""
                                ctaText = ctaText.replacingOccurrences(of: "{introductory_duration}", with: "\(duration)")
                                continueButton.setTitle(ctaText, for: .normal)
                            }else{
                                continueButton.setTitle("Start my \(duration)-day free trial", for: .normal)
                            }
                            
                            
                        }
                    }else{
                        
                        if ctaTextWhenSelected != nil && ctaTextWhenSelected != "" {
                            var ctaText = ctaTextWhenSelected ?? ""
                            continueButton.setTitle(ctaText, for: .normal)
                        }else{
                            continueButton.setTitle("Continue", for: .normal)
                        }
                        
                    }
                })
    
            
        }
      
    }
    func setPlanViews(){
        for section in mainStack.subviews{
            if let planView = section as? PaywallerPaywallPlansView{
                planView.select(plan: paywallManager.constants.selectedPlan)
            }
        }
  
    }
}
@available(iOS 15.0, *)
extension PaywallerPaywallController :  RevenueCatManagerDelegate, AdaptyManagerDelegate{
    public func packageFetched() {
        for section in mainStack.subviews{
            if let planSection = section as? PaywallerPaywallPlansView{
                planSection.packageFetched()
                fetchSelectedPlanDetails()
            }
        }
    }
}






