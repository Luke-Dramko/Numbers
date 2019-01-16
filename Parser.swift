//
//  Parser.swift
//  NumbersDevelop
//
//  Created by Luke  Dramko on 1/15/19.
//  Copyright © 2019 Luke Dramko. All rights reserved.
//

import Foundation

public func simplify(_ exp: String) throws -> Number {
    let tokenizer = try ExpressionTokenizer(exp)
    
    return Number.one //placeholder
}


//*********** Token identifying functions ***************
fileprivate func symbol(_ tokenizer: ExpressionTokenizer) -> Number? {
    var t = tokenizer;
    if let token = t.peek(), case .symbol(let constant) = token {
        t.pop(); //Unused call is fine here, the result of peek and pop are the same, and so we don't need
                 //to do anything else with it.
        return Number(constant);
    } else {
        return nil;
    }
}

fileprivate func integer(_ tokenizer: ExpressionTokenizer) -> Number? {
    var t = tokenizer;
    if let token = t.peek(), case .integer(let constant) = token {
        return Number(constant)
    } else {
        return nil
    }
}