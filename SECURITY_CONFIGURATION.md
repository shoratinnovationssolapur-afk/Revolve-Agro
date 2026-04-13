# ⚠️ Firebase Credentials & Security Configuration

## Important Security Notice

The Firebase credentials provided:
- **Email:** revolvepartner0@gmail.com
- **Password:** Revolvepartner@123

Should **NOT** be hardcoded in the Flutter app. Use the following secure setup:

---

## 🔐 Secure Email Configuration for Cloud Functions

### Option 1: Gmail with App Password (RECOMMENDED)

#### Step 1: Enable 2-Factor Authentication
1. Go to https://myaccount.google.com/security
2. Enable 2-Factor Authentication
3. Verify with phone

#### Step 2: Create App Password
1. Visit https://myaccount.google.com/apppasswords
2. Select "Mail" and "Windows Computer" (or Linux/Mac)
3. Generate app password (16 characters)
4. Copy and save it securely

#### Step 3: Store in Firebase
```bash
firebase functions:config:set gmail.email="revolvepartner0@gmail.com"
firebase functions:config:set gmail.password="xxxx xxxx xxxx xxxx"
```

#### Step 4: Use in Cloud Functions
```typescript
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: functions.config().gmail.email,
    pass: functions.config().gmail.password,
  },
});
```

---
'
### Option 2: SendGrid (More Reliable)

#### Step 1: Create SendGrid Account
1. Visit https://sendgrid.com
2. Sign up (free tier available)
3. Verify sender email: revolvepartner0@gmail.com

#### Step 2: Get API Key
1. Go to Settings → API Keys
2. Create API Key
3. Copy key

#### Step 3: Store in Firebase
```bash
firebase functions:config:set sendgrid.api_key="SG.xxxxxxxxxxxxx"
```

#### Step 4: Use in Cloud Functions
```typescript
import * as sgMail from "@sendgrid/mail";

sgMail.setApiKey(functions.config().sendgrid.api_key);

await sgMail.send({
  to: data.to,
  from: "noreply@revolveagro.com",
  subject: data.message.subject,
  html: data.message.html,
});
```

---

### Option 3: Mailgun

#### Step 1: Create Mailgun Account
1. Visit https://www.mailgun.com
2. Sign up (free tier available)
3. Verify domain

#### Step 2: Get API Key
1. Go to API Keys
2. Copy your API Key

#### Step 3: Store in Firebase
```bash
firebase functions:config:set mailgun.api_key="key-xxxxx"
firebase functions:config:set mailgun.domain="mail.revolveagro.com"
```

---

## 🔒 Firestore Security Rules

Add these rules to protect your Firestore data:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - only own data readable
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }
    
    // Orders - users read own, admins manage all
    match /orders/{orderId} {
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.userId ||
        request.auth.token.admin == true
      );
      allow create: if request.auth != null;
      allow update, delete: if request.auth.token.admin == true;
    }
    
    // Cart - users manage own
    match /cart/{cartId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
    
    // Products - all users read, admins manage
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.admin == true;
    }
    
    // Emails - admin only
    match /emails/{emailId} {
      allow read, write: if request.auth.token.admin == true;
    }
  }
}
```

---

## 🛠️ Environment Variables Setup

### Firebase Project Setup

1. **Install Firebase CLI**
```bash
npm install -g firebase-tools
firebase login
```

2. **Set Environment Variables**
```bash
# For Gmail
firebase functions:config:set gmail.email="revolvepartner0@gmail.com" \
  gmail.password="xxxx xxxx xxxx xxxx"

# For SendGrid
firebase functions:config:set sendgrid.api_key="SG.xxxxxxx"

# For Mailgun
firebase functions:config:set mailgun.api_key="key-xxxxx" \
  mailgun.domain="mg.revolveagro.com"
```

3. **View Current Config**
```bash
firebase functions:config:get
```

4. **Access in Cloud Functions**
```typescript
const emailPassword = functions.config().gmail.password;
const apiKey = functions.config().sendgrid.api_key;
```

---

## 🚀 Deployment Checklist

- [ ] Firebase project created and configured
- [ ] Billing enabled on Firebase project
- [ ] Email service credentials obtained (SendGrid/Mailgun/Gmail)
- [ ] Environment variables set in Firebase
- [ ] Cloud Functions code updated with config
- [ ] Firestore security rules updated
- [ ] Admin custom claims set for users who are admins
- [ ] Composite indexes created
- [ ] Local testing completed
- [ ] Production deployment verified

---

## 📝 Setting Admin Custom Claims

To make a user admin, run this Cloud Function or use Firebase Admin SDK:

```typescript
// Cloud Function to set admin claims
export const makeUserAdmin = functions.https.onRequest(
  async (request, response) => {
    const { uid } = request.body;
    
    try {
      await admin.auth().setCustomUserClaims(uid, { admin: true });
      response.send(`User ${uid} is now admin`);
    } catch (error) {
      response.status(500).send(error.message);
    }
  }
);
```

Or use Firebase CLI:
```bash
firebase functions:shell
> const admin = require('firebase-admin');
> admin.auth().setCustomUserClaims('user-uid', { admin: true })
```

---

## ⚠️ Do NOT

❌ Hardcode email credentials in Flutter code
❌ Commit credentials to git repository
❌ Use regular password for email (use App Password)
❌ Share Firebase project key publicly
❌ Allow unauthenticated Firestore access
❌ Store sensitive data in custom claims

## ✅ DO

✅ Use Firebase Environment Variables for credentials
✅ Use Cloud Functions for email sending
✅ Implement proper Firestore security rules
✅ Regular backup of Firestore data
✅ Monitor Cloud Function logs
✅ Test email sending before production
✅ Use separate Firebase projects for dev/prod

---

## 🔍 Verification Steps

### 1. Test Email Sending
```bash
# Add test document to "emails" collection
firebase firestore:import test-email.json

# Check Cloud Function logs
firebase functions:log
```

### 2. Test Firestore Rules
```bash
# Use Firebase Emulator Suite
firebase emulators:start

# Run security rules tests
firebase test:firestore /path/to/tests.spec.ts
```

### 3. Test Admin Claims
```dart
// In Flutter code
final user = FirebaseAuth.instance.currentUser;
final claims = user?.getIdTokenResult().claims;
print(claims?['admin']); // Should print true for admins
```

---

## 📞 Troubleshooting

### Email Not Sending
1. Check Cloud Function logs: `firebase functions:log`
2. Verify credentials in Firebase config
3. Check email is from verified sender
4. Check Gmail app password is correct (16 chars, not full password)

### Permission Denied Errors
1. Check Firestore rules are correct
2. Verify user is authenticated
3. Check custom claims are set for admin users
4. Test with Firebase Emulator

### Rate Limiting
- Gmail free tier: ~100 emails/day
- SendGrid free: 100 emails/day
- Mailgun free: 10,000 emails/day
- Upgrade plan if needed

---

## 📚 Useful Links

- [Firebase Cloud Functions Setup](https://firebase.google.com/docs/functions/get-started)
- [Nodemailer Configuration](https://nodemailer.com/smtp/)
- [SendGrid Integration](https://sendgrid.com/docs/)
- [Mailgun Integration](https://www.mailgun.com/docs/)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Custom Claims in Firebase](https://firebase.google.com/docs/auth/admin/custom-claims)

---

## ✨ Summary

1. **Never hardcode credentials** - Use environment variables
2. **Use Gmail App Password** - Not regular password
3. **Set proper Firestore rules** - Restrict access appropriately
4. **Deploy Cloud Functions** - For secure email sending
5. **Test thoroughly** - Before going to production
6. **Monitor logs** - Check Firebase console regularly

Your Firebase project is now securely configured! 🎉

