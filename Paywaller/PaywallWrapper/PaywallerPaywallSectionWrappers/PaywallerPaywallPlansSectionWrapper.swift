//
//  PaywallerPaywallPlansSectionWrapper.swift
//  NeonLongOnboardingPlayground
//
//  Created by Mehmet Kaan on 5.12.2023.
//

import Foundation
import NeonSDK
import UIKit

@available(iOS 15.0, *)
extension PaywallerPaywallJSONWrapper {
    public static func createPlansSection(fromDict dict: [String: Any]) -> PaywallerPaywallSectionType? {
        if let typeRaw = dict["type"] as? String,
           let type = planViewTypeFromString(typeRaw),
           let itemsData = dict["items"] as? [[String: Any]] {
            
            let horizontalPadding = dict["horizontalPadding"] as? CGFloat ?? 0
            var plans: [PaywallerPaywallPlan] = []
            for itemData in itemsData {
                
                let tag = itemData["tag"] as? String
                let ctaTextWhenSelected = itemData["ctaTextWhenSelected"] as? String
                let title = itemData["title"] as? String
                
                if let productIdentifier = itemData["productIdentifier"] as? String,
                   let priceTypeRaw = itemData["priceType"] as? String,
                   let priceType = priceTypeFromString(priceTypeRaw),
                   let isDefaultSelected = itemData["isDefaultSelected"] as? Bool {
                    
                    let plan = PaywallerPaywallPlan(productIdentifier: productIdentifier, tag: tag == "" ? nil : tag, title : title == "" ? nil : title, priceType: priceType, isDefaultSelected: isDefaultSelected, ctaTextWhenSelected: ctaTextWhenSelected)
                    plans.append(plan)
                }
            }
            
            return .plans(type: type, items: plans, shouldUsePlaceholders: false, horizontalPadding: horizontalPadding)
        }
        return nil
    }
    
    public static func planViewTypeFromString(_ typeString: String) -> PaywallerPaywallPlanViewType? {
        switch typeString {
        case "horizontal":
            return .horizontal
        case "vertical":
            return .vertical
        default:
            return nil
        }
    }
    
    public static func priceTypeFromString(_ priceTypeString: String) -> PaywallerPaywallPlan.PriceType? {
        switch priceTypeString {
        case "default":
            return .default
        case "perWeek":
            return .perWeek
        case "perMonth":
            return .perMonth
        default:
            return nil
        }
    }
}

@available(iOS 15.0, *)
extension PaywallerPaywallJSONWrapper {
    public static func createPlansJSON(from section: PaywallerPaywallSectionType, index: Int) -> [String: Any]? {
        guard case let .plans(type, items, _, horizontalPadding) = section else {
            return nil // Return nil if the input section is not of type .plans
        }
        
        var plansDict: [String: Any] = [
            "index": index,
            "type": "plans"
        ]
        
        var dataDict: [String: Any] = [:]
        var itemsArray: [[String: Any]] = []
        
        dataDict["type"] = planViewTypeToString(type)
        dataDict["horizontalPadding"] = horizontalPadding
        for item in items {
            var itemDict: [String: Any] = [
                "isDefaultSelected": item.isDefaultSelected,
                "priceType": priceTypeToString(item.priceType),
                "productIdentifier": item.productIdentifier,
                "ctaTextWhenSelected": item.ctaTextWhenSelected ?? "",
                "tag": item.tag ?? "",
                "title": item.title ?? ""
            ]
            itemsArray.append(itemDict)
        }
        
        dataDict["items"] = itemsArray
        plansDict["data"] = dataDict
        
        return plansDict
    }
    
    public static func planViewTypeToString(_ type: PaywallerPaywallPlanViewType) -> String {
        switch type {
        case .horizontal:
            return "horizontal"
        case .vertical:
            return "vertical"
        }
    }
    
    public static func priceTypeToString(_ priceType: PaywallerPaywallPlan.PriceType) -> String {
        switch priceType {
        case .default:
            return "default"
        case .perWeek:
            return "perWeek"
        case .perMonth:
            return "perMonth"
        }
    }
}


/*
 
 
 Example JSON
 
 {
   "data": {
     "items": [
       {
         "isDefaultSelected": true,
         "priceType": "default",
         "productIdentifier": "unlock.faceyoga.annual.3daystrial",
         "tag": ""
       },
       {
         "isDefaultSelected": false,
         "priceType": "default",
         "productIdentifier": "unlock.faceyoga.monthly",
         "tag": ""
       }
     ],
     "type": "vertical"
   },
   "index": 13,
   "type": "plans"
 }
 
 
 */
