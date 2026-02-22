import * as authService from '../services/auth.service.js';

export const signUp = async (req, res) => {
    try {
        const { email, password, fullName, phoneNumber } = req.body;

        if (!email || !password || !fullName) {
            return res.status(400).json({ success: false, message: 'Missing required fields' });
        }

        const result = await authService.signUp({ email, password, fullName, phoneNumber });
        res.status(201).json({ success: true, message: 'User registered successfully', data: result });
    } catch (error) {
        if (error.message === 'User with this email already exists') {
            return res.status(400).json({ success: false, message: error.message });
        }
        console.error('Sign up error:', error);
        res.status(500).json({ success: false, message: 'An error occurred while registering the user' });
    }
};

export const signIn = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ success: false, message: 'Missing email or password' });
        }

        const result = await authService.signIn(email, password);
        res.status(200).json({ success: true, message: 'Sign in successful', data: result });
    } catch (error) {
        if (error.message === 'Invalid email or password') {
            return res.status(401).json({ success: false, message: error.message });
        }
        console.error('Sign in error:', error);
        res.status(500).json({ success: false, message: 'An error occurred while signing in' });
    }
};
