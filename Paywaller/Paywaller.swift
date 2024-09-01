//
//  Paywaller.swift
//  Paywaller Example
//
//  Created by Tuna Öztürk on 16.01.2024.
//

import Foundation
import UIKit
import NeonSDK

@available(iOS 15.0, *)
public class Paywaller{
    
    private static var apiKey = String()
    private static var provider = PaywallerAppProviderConfiguration.none
    private static var remoteConfigs = [String : [String:Any]]()
    public static func getRemoteConfigValue(placement : String, key: String) -> Any?{
        if let remoteConfig = remoteConfigs[placement] , let configValue = remoteConfig[key]{
            return configValue
        }
        return nil
    }
    public static func configure(apiKey : String, provider : PaywallerAppProviderConfiguration){
        self.apiKey = apiKey
        self.provider = provider
        configureProvider(provider: provider, completion: {
            
        })
        Font.configureFonts(font: .SFProDisplay)
        PaywallerConstants.apiKey = apiKey
    }
    private static func configure(provider : PaywallerPaywallProviderConfiguration, on controller : UIViewController, with delegate : PaywallerDelegate?){
        Font.configureFonts(font: .SFProDisplay)
        PaywallerConstants.apiKey = self.apiKey
        DispatchQueue.main.async {
            LottieManager.showFullScreenLottie(animation: .loadingCircle2, color: .white)
        }
        configureProvider(provider: self.provider, completion: {
            DispatchQueue.main.async {
                LottieManager.removeFullScreenLottie()
                if !PaywallerConstants.paywalls.isEmpty{
                    presentPaywall(with: provider, from: controller, delegate: delegate)
                }
            }
        })
        
    }
    
    public static func presentPaywall(with provider : PaywallerPaywallProviderConfiguration, from controller : UIViewController, delegate : PaywallerDelegate? = nil){
        
        if PaywallerConstants.paywalls.isEmpty{
            configure(provider : provider, on: controller, with: delegate)
            return
        }
        switch provider {
        case .adapty(let selectedPlacementID):
            for paywall in PaywallerConstants.paywalls{
                switch paywall.provider {
                case .adapty(let paywallPlacementID):
                    Neon.paywallPresented()
                    if selectedPlacementID == paywallPlacementID{
                        paywall.manager.delegate = delegate ?? (controller as? any PaywallerDelegate)
                        paywall.manager.present(from: controller)
                    }
                    break
                case .revenuecat:
                    break
                case .none:
                    break
                }
            }
        case .revenuecat:
            break
        case .none:
            break
        }
    }
    
    internal static func configureProvider(provider : PaywallerAppProviderConfiguration, completion : @escaping () -> ()){
        switch provider {
        case .adapty(let apiKey, let placementIDs, let accessLevel, let customerUserId):
            AdaptyManager.configure(withAPIKey: apiKey, placementIDs: placementIDs, accessLevel: accessLevel, customerUserId : customerUserId) {
                fetchPaywalls(for: placementIDs, completion: {
                    completion()
                })
            }
            break
        case .revenuecat:
            break
        case .none:
            break
        }
    }
    
    internal static func fetchPaywalls(for placementIDs : [String], completion : @escaping () -> ()){
        var fetchedPaywallCount = 0
        for placementID in placementIDs {
            fetchPaywall(for: placementID, completion: {
                fetchedPaywallCount += 1
                if fetchedPaywallCount == placementIDs.count{
                    completion()
                }
            })
        }
    }
    
    internal static func fetchPaywall(for placementID : String, completion : @escaping () -> ()){
        let adaptyPaywall = AdaptyManager.getPaywall(placementID: placementID)
        guard let remoteConfig = adaptyPaywall?.remoteConfig?.dictionary as? [String : Any] else {
            completion()
            return
        }
        remoteConfigs[placementID] = remoteConfig
        guard let paywallID = remoteConfig["paywall_id"] as? String else {
            completion()
            return
        }
        
        APIManager.shared.getPaywall(id: paywallID, completion: { result in
            switch result {
            case .success(let dictionary):
                if let json = dictionary["json"] as? [String : Any]{
                    DispatchQueue.main.async {
                        let provider = PaywallerPaywallProviderConfiguration.adapty(placementID: placementID)
                        let sectionTypes = PaywallerPaywallJSONWrapper.createSections(from: json)
                        let constants = PaywallerPaywallJSONWrapper.createConstants(from: json)
                        constants.provider = provider
                        
                        let manager = PaywallerPaywallManager()
                        manager.constants = constants
                        
                        for sectionType in sectionTypes {
                            manager.sections.append(PaywallerPaywallSection(type: sectionType, manager: manager))
                        }
                        PaywallerConstants.paywalls.append(PaywallerPaywall(manager: manager, provider: provider))
                    }
                    
                }
            case .failure(let failure):
                print(failure)
            }
            
            completion()
        })
    }
    
}
