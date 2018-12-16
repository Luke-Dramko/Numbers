//
//  File.swift
//  NumbersDevelop
//
//  Created by Luke  Dramko on 11/26/18.
//  Copyright © 2018 Luke Dramko. All rights reserved.
//

import Foundation

infix operator ~
infix operator !~

public class Number: CustomStringConvertible, Comparable {
    internal static var approximations: [String: Double] = ["": 1, "e": 2.71828_18284_59045_23536, "pi": Double.pi, "\\pi": Double.pi, "\u{03C0}": Double.pi]
    
    internal let coefficient: Int;
    internal let constant: String;
    
    //Computed properties
    public var description: String {
        if coefficient == 1 {
            if constant == "" {
                return String(1);
            } else {
                return constant;
            }
        } else {
            return String(coefficient) + constant;
        }
    }
    
    
    //**************** Constructors ****************
    //Public initializers
    
    /**
     A simple constructor that initializes the basic number class with an integer.
 
     Parameter inVal: the input integer.
    */
    public init(_ coefficient: Int) {
        self.coefficient = coefficient;
        constant = "";
    }
    
    /**
     This constructor allows for mathematical constants in addition to integer numbers.
     
     Parameter inVal: The integer coefficient the number represents
     Parameter inCons: A string representing the constants.
     */
    public init(_ constant: String) {
        coefficient = 1;
        self.constant = constant;
    }
    
    public init(_ coefficient: Int, _ constant: String) {
        self.coefficient = coefficient;
        self.constant = constant
    }
    
    //Internal only initializer
    
    /**
     A constructor meant for internal use inside the Numbers package only.  It can initialize the
     class with nil.
     
     This is important if a subclass is delegating to this one and doesn't need to use this class' internal fields.
     */
    internal init() {
        coefficient = 1;
        constant = "";
    }
    
    
    //Parsing functions for initialization
    
    /**
     Parses text into a string of constants.  Throws and exception if there's an invalid character.
     Constants are interpreted as single characters, unless they're escaped with \.  A word escaped
     with \ is a single constant.  \ words are delimited by whitespace.
     
     Valid string: a \lambda \pi\stringConst abc
     Invalid string: a*NG
     
     Parameter text: to parse
     
     */
    internal static func parseConstants(_ text: String) -> [String] {
        var cons = [String]();
        let letters = CharacterSet.letters;
        let whitespace = CharacterSet.whitespaces;
        
        var current: String = "\\";
        var largeConst = false;
        
        for char in text.unicodeScalars {
            if char == "\\" {
                if largeConst {
                    cons.append(current);
                    current = "\\";
                } else {
                    largeConst = true;
                }
                
            } else if letters.contains(char) {
                if (largeConst) {
                    current += String(char);
                } else {
                    cons.append(String(char));
                }
            } else if whitespace.contains(char) {
                if (largeConst) {
                    largeConst = false;
                    cons.append(current);
                    current += "\\";
                }
            } else {
                
            }
        }
        
        return cons;
    }
    
    
    //************** Instance Methods *********
    internal func multiple(coefficient c: Int) -> Number {
        return Number(c, self.constant);
    }
    
    public func approximate() throws -> Double {
        if let c = Number.approximations[self.constant] {
            return c * Double(self.coefficient)
        } else {
            throw ApproximationError.UndefinedConstantError("'\(self.constant)' does not have a defined approximate decimal value."); 
        }
    }
    
    
    //*************** Operator instance methods ****************
    
    /**
     Number + Number
     
     Adds two basic numbers together
    */
    internal func add(_ right: Number) -> Number {
        print("Number + Number")
        
        let left = self;
        if (left ~ right) {
            return Number(left.coefficient + right.coefficient, left.constant);
        } else {
            return Sum(left, right);
        }
    }
    
    /**
     Number + Fraction
     
     Adds a basic number to a fraction, done through the fraction class.
     */
    internal func add(_ right: Fraction) -> Number {
        print("Fraction + Number")
        
        return right.add(self);
    }
    
    /**
     Number - Number
     */
    internal func subtract(_ right: Number) -> Number {
        let left = self;
        if left ~ right {
            return Number(left.coefficient - right.coefficient, left.constant);
        } else {
            return Sum(left, Number(-right.coefficient, right.constant));
        }
    }
    
    /**
     Number * Number
     */
    internal func multiply(_ right: Number) -> Number {
        let left = self;
        
        //This case covers situations like 2 * 4, 2 * 4e, and 2e * 4
        if left.constant == "" || right.constant == "" {
            //Left's constant is the e, a, etc.
            if (left.constant != "") {
                return Number(left.coefficient * right.coefficient, left.constant);
                
                //right's constant is the e, a, etc. or they're both "".
            } else {
                return Number(left.coefficient * right.coefficient, right.constant);
            }
            
            
            //This case covers situations like 4e * e or 3a * 5a
        } else if left ~ right {
            return Exponential(coefficient: left.coefficient * right.coefficient, base: Number(left.constant), exponent: Number(2));
            
            //This case cover situations like 4e * 7b
        } else {
            return Product(coefficient: left.coefficient * right.coefficient, Number(left.constant), Number(right.constant));
        }
    }
    
    /**
     Number / Number
     */
    internal func divide(_ right: Number) -> Number {
        let left = self;
        let g = gcd(left.coefficient, right.coefficient);
        let n: Int = left.coefficient / g; //numerator
        let d: Int = right.coefficient / g; //denominator
        
        //Handles cases such as 5/4, e/e, 1/2, and 6e/7e
        if left ~ right {
            if d == 1 {
                return Number(n);
            } else {
                return Fraction(n, Number(1), Number(d));
            }
            
            //Handles any case in which the numerator and denominator have different symbolic constants,
            //such as 3/a 2t/x, etc.
        } else {
            return Fraction(n, Number(left.constant), Number(d, right.constant))
        }
    }
    
    internal func equals(_ right: Number) -> Bool {
        return self.coefficient == right.coefficient && self.constant == right.constant
    }
    
    internal func lessthan(_ right: Number) -> Bool {
        if (self != right) {
            return self.constant < right.constant;
        } else {
            return self.coefficient < right.coefficient;
        }
    }
}

/**
 Adds together two basic numbers.  Subclasses should have their own add functions.
 */
public func + (left: Number, right: Number) -> Number {
    print("In adding function")
    print("Left is a fraction: \(left is Fraction)")
    print("Right is a fraction: \(right is Fraction)")
    
    return left.add(right);
}

/**
 Adds together two numbers.  The number class is polymorphic, so the right subtract should be called.
 */
public func - (left: Number, right: Number) -> Number {
    return left.subtract(right)
}

public func * (left: Number, right: Number) -> Number {
    return left.multiply(right);
}

public func / (left: Number, right: Number) -> Number {
    return left.divide(right)
}




/**
 Compares two basic numbers by comparing their constants and internal integer coefficients
 Operates on two numbers.
 */
public func == (left: Number, right: Number) -> Bool {
    return left.coefficient == right.coefficient && left.constant == right.constant
}

/**
 Compares Numbers lexicographically.
 Numbers are compared first by constant value, then coefficient value.
 
 Operates on two numbers.
 */
public func < (lhs: Number, rhs: Number) -> Bool {
    return lhs.lessthan(rhs)
}


public func ~ (left: Number, right: Number) -> Bool {
    return left.constant == right.constant;
}

public func !~ (left: Number, right: Number) -> Bool {
    return !(left ~ right);
}
