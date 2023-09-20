
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
		while(uppercaseLetters > 0) {
			password.append(upperChars.take(1))
			upperChars = upperChars.drop(1)
			uppercaseLetters--
		}
		
		while(lowercaseLetters > 0) {
			password.append(lowerChars.take(1))
			lowerChars = lowerChars.drop(1)
			lowercaseLetters--
		}
		
		while(numbers > 0) {
			password.append(numberChars.take(1))
			numberChars = numberChars.drop(1)
			numbers--
		}
		
		while(symbols > 0) {
			password.append(symbolChars.take(1))
			symbolChars = symbolChars.drop(1)
			symbols--
		}
        
        // Shuffle the generated password
        return shuffleString(password.toString())
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
	
}