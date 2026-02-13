# User Authentication System

## Purpose

Handle user registration, login, session management, and logout. This is the foundation for all authenticated features.

## Requirements

- Users can register with email and password
- Users can log in with email and password
- Sessions persist across browser refreshes
- Users can log out (invalidates session)
- Passwords are hashed (never stored in plain text)
- Failed login attempts are rate-limited

## Acceptance Criteria

- [ ] Registration creates user and sends verification email
- [ ] Login with valid credentials returns session token
- [ ] Login with invalid credentials returns 401 (no details about which field)
- [ ] Session token validates on subsequent requests
- [ ] Logout invalidates session server-side
- [ ] 5 failed attempts locks account for 15 minutes
- [ ] Password reset flow works end-to-end

## Edge Cases

- What if user registers with existing email? → Return generic "check your email" (don't reveal if email exists)
- What if session expires mid-request? → Return 401, frontend redirects to login
- What if user has multiple sessions? → All sessions valid until explicit logout
- What if password reset link expires? → Show "link expired" with option to request new one

## API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/auth/register` | Create new user |
| POST | `/api/auth/login` | Authenticate user |
| POST | `/api/auth/logout` | End session |
| POST | `/api/auth/forgot-password` | Request reset email |
| POST | `/api/auth/reset-password` | Set new password |
| GET | `/api/auth/me` | Get current user |

## Dependencies

- Depends on: Email system (for verification and reset emails)
- Depended on by: All authenticated features

## Notes

- Use secure, httpOnly cookies for session tokens
- Consider OAuth providers in future (out of scope for v1)
