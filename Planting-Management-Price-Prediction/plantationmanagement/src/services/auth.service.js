import { db } from '../config/firebase.js';
import { hashPassword, verifyPassword } from '../utils/password.js';
import { generateToken } from '../utils/jwt.js';

export const signUp = async (userData) => {
    const usersRef = db.collection('users');
    const existingUserSnapshot = await usersRef.where('email', '==', userData.email.toLowerCase()).get();

    if (!existingUserSnapshot.empty) {
        throw new Error('User with this email already exists');
    }

    const hashedPassword = await hashPassword(userData.password);

    // Create new user doc
    const newUserRef = usersRef.doc(); // Auto-generated ID
    const now = new Date();

    const newUser = {
        id: newUserRef.id,
        email: userData.email.toLowerCase(),
        passwordHash: hashedPassword,
        fullName: userData.fullName,
        phoneNumber: userData.phoneNumber,
        createdAt: now,
        updatedAt: now
    };

    await newUserRef.set(newUser);

    const token = generateToken(newUser);

    return {
        userId: newUser.id,
        email: newUser.email,
        fullName: newUser.fullName,
        phoneNumber: newUser.phoneNumber,
        token
    };
};

export const signIn = async (email, password) => {
    const usersRef = db.collection('users');
    const userSnapshot = await usersRef.where('email', '==', email.toLowerCase()).get();

    if (userSnapshot.empty) {
        throw new Error('Invalid email or password');
    }

    // Should only be one user with this email due to check in signUp
    const userDoc = userSnapshot.docs[0];
    const user = userDoc.data();

    const isValid = await verifyPassword(password, user.passwordHash);
    if (!isValid) {
        throw new Error('Invalid email or password');
    }

    // Ensure the ID in the token matches the document ID
    user.id = userDoc.id;

    const token = generateToken(user);

    return {
        userId: user.id,
        email: user.email,
        fullName: user.fullName,
        phoneNumber: user.phoneNumber,
        token
    };
};
