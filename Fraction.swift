//
//  Fraction.swift
//  NumbersDevelop
//
//  Created by Luke  Dramko on 11/26/18.
//  Copyright © 2018 Luke Dramko. All rights reserved.
//

import Foundation

public class Fraction: Number {
    internal let numerator: Number;
    internal let denominator: Number;
    
    
    public override var hashValue: Int {
        return (coefficient * numerator.hashValue) / denominator.hashValue
    }
    
    public override var description: String {
        if numerator.description == "1" {
            return String(coefficient) + "/" + denominator.description
        } else {
            return String(coefficient) + "(" + numerator.description + ")/" + denominator.description;
        }
    };
    
    //Returns a string interpretable with LaTeX typesetting engines.
    public override var LaTeX: String {
        if numerator.description == "1" {
            return "\\frac{\(String(self.coefficient))}{\(denominator.LaTeX)}"
        } else {
            if self.coefficient == 1 {
                return "\\frac{\(numerator.LaTeX)}{\(denominator.LaTeX)}"
            } else {
                return "\\frac{\(String(self.coefficient) + numerator.LaTeX)}{\(denominator.LaTeX)}"
            }
        }
    }
    
    internal init(_ numerator: Number, _ denominator: Number) {
        self.numerator = numerator;
        self.denominator = denominator;
        super.init(); //coefficient defaults to 1.
    }
    
    internal init(_ coefficient: Int, _ numerator: Number, _ denominator: Number) {
        self.numerator = numerator
        self.denominator = denominator
        super.init(coefficient);
    }
    
    //********************* Miscellaneous Helpers ***********************
    
    /**
     Simplifies the Number portion of a Fraction. (the coefficient are reduced in fraction * fraction).
     
     -Parameter fraction: the fraction to be reduced.
     */
    public static func reduce(_ fraction: Fraction) -> Number {
        var nfh = Dictionary<Number, Number>();
        
        let numer = fraction.numerator is Product ? (fraction.numerator as! Product).factors : [fraction.numerator];
        
        //All terms in a Prodduct are unique, and terms are combined with the appropriate exponent.
        //For example, x^5 and x will never both be in the same product; they'll be combined into x^6.
        //Of course, if numer is not a product and simply a single Number in an array packaging, the
        //"duplicate" scenario described above can't occur.
        for factor in numer {
            if let e = factor as? Exponential {
                nfh[e.base] = e.exponent
            } else {
                nfh[factor] = Number.one
            }
        }
        
        let denom = fraction.denominator is Product ? (fraction.denominator as! Product).factors : [fraction.numerator];
        
        for factor in denom {
            if let e = factor as? Exponential {
                if let val = nfh[e.base] {
                    nfh[e.base] = val - e.exponent
                } else {
                    nfh[e.base] = e.exponent.multiple(coefficient: -e.coefficient)
                }
            } else {
                if let val = nfh[factor] {
                    nfh[factor] = val + Number.negative_one;
                } else {
                    nfh[factor] = Number.negative_one
                }
            }
        }
        
        var nt: [Number] = []; //numerator terms
        var dt: [Number] = []; //denominator terms
        
        for (base, exponent) in nfh {
            //Exponent is negative, so the Number is in the denominator
            if (exponent.coefficient < 0) {
                if exponent == Number.negative_one {
                    dt.append(base)
                } else {
                    //We have to flip the sign on the exponent; putting it in the denominator "erases"
                    //the negative.
                    dt.append(Exponential(base: base, exponent: exponent.multiple(coefficient: -exponent.coefficient)))
                }
                
            //Exponent is positive, so Number is in the numerator
            } else if exponent.coefficient > 0 {
                if exponent == Number.one {
                    nt.append(base)
                } else {
                    nt.append(Exponential(base: base, exponent: exponent))
                }
            }
            //Note that exponent.coefficient == 0 is excluded, because anything to the zero power is 1,
            //which is redundant.
        }
        
        let reducedNumer: Number;
        
        if nt.count == 0 {
            reducedNumer = Number.one;
        } else if nt.count == 1 {
            reducedNumer = nt[0]
        } else {
            reducedNumer = Product(coefficient: 1, nt)
        }
        
        if dt.count == 0 {
            return reducedNumer;
        } else if dt.count == 1 {
            return Fraction(fraction.coefficient, reducedNumer, dt[0].multiple(coefficient: fraction.denominator.coefficient))
        } else {
            return Fraction(fraction.coefficient, reducedNumer, Product(coefficient: fraction.denominator.coefficient, dt))
        }
    }
    
    //**************** Instance methods ***************
    internal override func multiple(coefficient c: Int) -> Number {
        return Fraction(c, self.numerator, self.denominator);
    }
    
    public override func approximate() throws -> Double {
        return try (Double(self.coefficient) * numerator.approximate()) / denominator.approximate()
    }
    
    /**
     Returns the reciprocal of this fraction
     */
    public func reciprocal() -> Fraction {
        let c = self.denominator.coefficient;
        /*
         Fractions in this module are represented as
           1x
         c----
           dy
         
         where c and d are integer coefficients and x and y are instances of Number.
         The goal is to get
         
           1y
         d----
           cx
         
         which is the reciprocal of the fraction.
         */
        return Fraction(c, self.denominator.multiple(coefficient: 1), self.numerator.multiple(coefficient: self.coefficient))
    }
    
    //**************** Operator Methods ***************
    
    /**
     Fraction + Fraction
     
     Adds two fractions together, no matter the type instance of the numerator and denominator.
     
     -Parameter right: The right member of the addition
     -Return: The result of the addition
     */
    internal func add(_ right: Fraction) -> Number {
        let left = self;
        
        var denominator = left.denominator;
        var numerator: Number;
        if left.denominator != right.denominator {
            /*
             a    b     ad + bc
             -- + -- = --------
             c    d       cd
             */
            denominator = left.denominator * right.denominator;
            
            /**
             a = left.numerator (though its coefficient is self.coefficient)
             b = right.numerator (though its coefficient is right.coefficient)
             c = left.denominator
             d = right.denominator
             
             numerator = (a*d).multiple(left.coefficient, d.coefficient) + (b*c).multiple(right.coefficient, c.coefficient)
            */
            numerator = (left.numerator * right.denominator).multiple(coefficient: left.coefficient * right.denominator.coefficient) + (left.denominator * right.numerator).multiple(coefficient: right.coefficient * left.denominator.coefficient)
        } else {
            numerator = left.numerator + right.numerator;
        }
        
        //TODO: When the Product and Exponential classes are implemented, put a simplification
        //step here.
        
        let g: Int = gcd(numerator.coefficient, denominator.coefficient);
        
        let numeratorCoeff = numerator.coefficient / g;
        denominator = denominator.multiple(coefficient: denominator.coefficient / g)
        
        //TODO Make recalculating the numerator so many times unecessary.
        if numeratorCoeff == 0 {
            return Number(0)
        } else if denominator == Number(1) {
            return numerator.multiple(coefficient: numeratorCoeff);
        } else {
            return Fraction(numeratorCoeff, numerator.multiple(coefficient: 1), denominator)
        }
    }
    
    /**
    Fraction + Number
     
    This function handles the override of Number's multiply and determines the correct downcasted type of
    the right term if necessary.  Symbolically, this function creates a fraction over one if the right
    side is not a fraction.
     
     -Parameter right: the right term in the sum
     -Retern: The result of the sum.
    */
    internal override func add(_ right: Number) -> Number {
        switch right {
        case is Fraction:
            return self.add(right as! Fraction)
        default:
            return self.add(Fraction(right.coefficient, right.multiple(coefficient: 1), Number(1)))
        }
    }
    
    /**
    Fraction - Number
     
     Subtraction is done through the addition function; the right coefficient is multiplied by negative one
     first.
     
     -Parameter right: the number being subtracted.
     -Return: The result of the subtraction.
    */
    internal override func subtract(_ right: Number) -> Number {
        switch right {
        case is Fraction:
            return self.add((right as! Fraction).multiple(coefficient: -right.coefficient))
        default:
            return self.add(Fraction(-right.coefficient, right.multiple(coefficient: 1), Number(1)))
        }
    }
    
    /**
     Fraction * Fraction
     
     Multiplies two Fraction objects together, and reduces the fraction as necessary.  Multiplication is
     done as:
    
       a     b     ab
      --- * --- = ----
       c     d     cd

     and is then reduced.
     
     -Parameter right: The right fraction in the product (b/d from above).
     -Return: The result of the multiplication.
     */
    internal func multiply(_ right: Fraction) -> Number {
        let numerator = self.numerator * right.numerator;
        let denominator = self.denominator * right.denominator;
        
        let g = gcd(self.coefficient * right.coefficient,  denominator.coefficient)
        
        //TODO: Reduce common non coefficient factors.
        
        if (denominator ~ Number(1)) && (denominator.coefficient / g) == 1 {
            return numerator;
        } else {
            return Fraction((self.coefficient * right.coefficient) / g, numerator.multiple(coefficient: 1), denominator.multiple(coefficient: denominator.coefficient / g))
        }
    }
    
    /**
     Fraction * Number
     
     This helper function overrides the multiply function from Number.  It downcasts as appropriate and
     routs the actual multiplication operation through Fraction * Fraction.
     
     Non-Fraction numbers are converted to fractions over one before multiplication (x -> x/1).
     
     -Parameter right: the right number in the multiplication.
     */
    internal override func multiply(_ right: Number) -> Number {
        switch right {
        case is Fraction: return self.multiply(right as! Fraction)
        default: return self.multiply(Fraction(right.coefficient, right.multiple(coefficient: 1), Number(1)))
        }
    }
    
    /**
     Fraction / Number
     
     Divides two fractions by multiplying by the reciprocal.
     As division is routed through the multiplication function,  and does the appropriate typecasting,
     so no other overloaded division functions are necessary.
     
     -Parameter right: The number on the right of the division (i.e. self / right).
     -Returns: the result of the division.
     */
    internal override func divide(_ right: Number) -> Number {
        //Division is equivalent to multiplication by the inverse/reciprocal
        switch right {
        case is Fraction:
            return self.multiply((right as! Fraction).reciprocal())
        default:
            return self.multiply(Fraction(Number(1), right));
        }
    }
    
    
    /**
     Compares a Fraction (self) and a Number and determines if they're equal.
     
     -Parameter right: the Number to compare to
     -Return: true if the Numbers are equal and false otherwise.
     */
    internal override func equals(_ right: Number) -> Bool {
        if self.coefficient == 0 && right.coefficient == 0 {
            return true;
        }
        
        if let r = right as? Fraction {
            return self.coefficient == r.coefficient && self.numerator == r.numerator && self.denominator == r.denominator;
        } else {
            //The module only allows Number subclasses to be created through operators or internal parsing
            //functions.  Otherwise, users can create only Numbers.  The internal operator functions and
            //the parsing functions ensure that special cases like x/1, a sum of just x, a product of
            //just x, etc. don't happen.  Otherwise, these special cases whould have to be handled here
            //and in every other overriden equals function.
            return false;
        }
    }
    
    /**
     Determines if two Fractions are like terms or not.  To be like terms, the fractions must be like in
     the numerator and denominator.
     
     5/6 and 2/3 are like terms, but 4a/3 and 2/3 are not, nor are 3/7 and 3/4e
     
     -Parameter right: the Number to compare to
     -Return: true if Fractions are like and false otherwise.
     */
    internal override func like(_ right: Number) -> Bool {
        if self.coefficient == 0 && right.coefficient == 0 {
            return true;
        }
        
        print("In the main body")
        
        if let r = right as? Fraction {
            
            print("Right is a Fraction")
            
            return (self.numerator ~ r.numerator) && (self.denominator ~ r.denominator);
        } else if right is Exponential || right is Sum || right is Product {
            //Values that could be better represented in a more simplified form (like a Sum of just
            //(3) or a Fraction of 5x/1 are represented by that form (3, and 5x, which are Numbers,
            //from the earlier examples).
            return false;
        } else {
            //right is just an instance of Number, not a subclass.
            
            //This if statement handles the special case of like terms where the denominator is
            //a simple integer constant (decimal constants are impossible in this system).
            //This includes cases like
            // 6 - 4/5 (like terms) and 5x + 4x/7 (also like terms).
            if (right ~ self.numerator) && (self.denominator ~ Number(1)) {
                return true;
            } else {
                return false;
            }
        }
    }
    
}
