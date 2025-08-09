import * as Firebase from "firebase/auth";

// We'll modify the bridge to export the config
import { Persistence } from './DB/exports.js';

const emailInput = document.getElementById('email') as HTMLInputElement;
const passwordInput = document.getElementById('password') as HTMLInputElement;
const loginBtn = document.getElementById('loginBtn') as HTMLButtonElement;
const signupBtn = document.getElementById('signupBtn') as HTMLButtonElement;
const errorMessage = document.getElementById('error-message') as HTMLParagraphElement;

loginBtn.onclick = async () => {
    errorMessage.textContent = '';
    try {
        await Firebase.signInWithEmailAndPassword(
            Persistence.auth,
            emailInput.value,
            passwordInput.value
        );
    } catch (error) {
        errorMessage.textContent = "Login failed. Please check your credentials.";
        console.error("Login Error:", error);
    }
};

signupBtn.onclick = async () => {
    errorMessage.textContent = '';
    try {
        await Firebase.createUserWithEmailAndPassword(
            Persistence.auth,
            emailInput.value,
            passwordInput.value
        );
    } catch (error) {
        errorMessage.textContent = "Sign up failed. Please try again.";
        console.error("Signup Error:", error);
    }
};

Firebase.onAuthStateChanged(Persistence.auth, (user: Firebase.User | null) => {
    if (user) {
        console.log("User authenticated, redirecting to main app...");
        window.location.href = '/index.html';
    }
    // If user is null, do nothing and let them use the form.
});
