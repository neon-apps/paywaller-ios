//
//  NeonLongOnboardingPlan.swift
//  NeonLongOnboardingPlayground
//
//  Created by Tuna Öztürk on 19.11.2023.
//

import Foundation


public class PaywallerPaywallPlan{
    
    public var productIdentifier : String
    public var tag : String?
    public var title : String?
    public var ctaTextWhenSelected : String?
    public var priceType = PriceType.default
    public var isDefaultSelected = Bool()
    public init(productIdentifier: String = String(), tag: String? = nil, title: String? = nil, priceType : PriceType = .default, isDefaultSelected : Bool = false, ctaTextWhenSelected: String? = nil) {
        self.productIdentifier = productIdentifier
        self.tag = tag
        self.title = title
        self.priceType = priceType
        self.isDefaultSelected = isDefaultSelected
        self.ctaTextWhenSelected = ctaTextWhenSelected
    }
    
    public enum PriceType{
        case `default`
        case perWeek
        case perMonth
    }
    public func copy() -> PaywallerPaywallPlan {
        return PaywallerPaywallPlan(productIdentifier: self.productIdentifier, tag: self.tag, title: self.title, priceType: self.priceType, isDefaultSelected: self.isDefaultSelected, ctaTextWhenSelected : self.ctaTextWhenSelected)
      }
      
    
    
}
