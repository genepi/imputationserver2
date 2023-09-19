
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.RandomStringUtils

class PasswordCreator {

    static String createPassword() {
        createPassword(5, 5, 2, 2, 3)
    }


static String createPassword(int uppercaseLetters, int lowercaseLetters, int numbers, int symbols, int duplicates) {
        StringBuilder password = new StringBuilder()
        
        // Define character sets
        String upperChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        String lowerChars = "abcdefghijklmnopqrstuvwxyz"
        String numberChars = "0123456789"
        String symbolChars = '!@#%&*()_+[]{};:.<>?-='
        
        // Shuffle character sets
        upperChars = shuffleString(upperChars)
        lowerChars = shuffleString(lowerChars)
        numberChars = shuffleString(numberChars)
        symbolChars = shuffleString(symbolChars)
        
        // Create password
        while (password.length() < (uppercaseLetters + lowercaseLetters + numbers + symbols)) {
            if (uppercaseLetters > 0 && upperChars.length() > 0) {
                password.append(upperChars.take(1))
                upperChars = upperChars.drop(1)
                uppercaseLetters--
            }
            
            if (lowercaseLetters > 0 && lowerChars.length() > 0) {
                password.append(lowerChars.take(1))
                lowerChars = lowerChars.drop(1)
                lowercaseLetters--
            }
            
            if (numbers > 0 && numberChars.length() > 0) {
                password.append(numberChars.take(1))
                numberChars = numberChars.drop(1)
                numbers--
            }
            
            if (symbols > 0 && symbolChars.length() > 0) {
                password.append(symbolChars.take(1))
                symbolChars = symbolChars.drop(1)
                symbols--
            }
        }
        
        // Shuffle the generated password
        String shuffledPassword = shuffleString(password.toString())
        
        // Check for duplicates
        if (hasDuplicates(shuffledPassword, duplicates)) {
            return createPassword(uppercaseLetters, lowercaseLetters, numbers, symbols, duplicates)
        }
        
        return shuffledPassword
    }

    private static String shuffleString(String input) {
        char[] chars = input.toCharArray()
        for (int i = chars.length - 1; i > 0; i--) {
            int j = (int) (Math.random() * (i + 1))
            char temp = chars[i]
            chars[i] = chars[j]
            chars[j] = temp
        }
        return new String(chars)
    }

    private static boolean hasDuplicates(String input, int duplicates) {
        Set<Character> charSet = new HashSet<>()
        for (char c : input.toCharArray()) {
            if (!charSet.add(c)) {
                duplicates--
                if (duplicates == 0) {
                    return true
                }
            }
        }
        return false
    }
	
}