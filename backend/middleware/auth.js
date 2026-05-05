import 'dotenv/config'; // Import env file to access environment variables
import jwt from 'jsonwebtoken';

// Security best practice, JWT_SECRET is a secret key used to sign and verify tokens, stored in the .env file
const JWT_SECRET = process.env.JWT_SECRET || 'studyhelper_secret_key';

// This is the middleware function to authenticate tokens, it is used in the routes to protect them
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization']; // Check for authorization header
  const token = authHeader && authHeader.split(' ')[1]; // Extract token from header (split by space and take the second element which is the token)
  if (token == null) return res.sendStatus(401); // If no token, return 401

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403); // If token is invalid, return 403
    req.user = user; // Set user
    next(); // Proceed to the next middleware
  });
};

export default authenticateToken;
