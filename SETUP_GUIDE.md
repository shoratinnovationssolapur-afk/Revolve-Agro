## RevolveAgro Order Management - Setup Guide

### Features Added

This guide covers the setup for the new order management enhancement features:

1. **Admin Rejection Reason** - Admins can add rejection messages when denying orders
2. **Email Notifications** - Users receive emails when orders are approved/rejected
3. **Timeline View** - Order status history with timestamps
4. **Order Tracking** - Track delivery status (processing, shipped, delivered)
5. **Bulk Actions** - Approve/reject multiple orders simultaneously

---

## Database Schema Updates

The orders collection now includes these new fields:

```json
{
  "status": "pending|approved|rejected",
  "rejectionReason": "string (optional)",
  "trackingStatus": "none|processing|shipped|delivered",
  "statusHistory": [
    {
      "status": "pending|approved|rejected",
      "timestamp": "Timestamp",
      "reason": "string (optional)"
    }
  ],
  "trackingNumber": "string (optional)",
  "trackingNotes": "string (optional)",
  "trackingUpdatedAt": "Timestamp (optional)"
}
```

---

## Email Notifications Setup

### Option 1: Using Firebase Cloud Functions (RECOMMENDED)

#### Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
firebase init functions
```

#### Step 2: Create Cloud Function
Create a file `functions/src/sendOrderEmail.ts`:

```typescript
import * as functions from "firebase-functions";
import * as nodemailer from "nodemailer";
import * as admin from "firebase-admin";

admin.initializeApp();

// Configure your email service
// Using Gmail (enable "Less secure app access" or use App Password)
// Or use your own SMTP server
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.ADMIN_EMAIL || "revolvepartner0@gmail.com",
    pass: process.env.ADMIN_PASSWORD || "Revolvepartner@123", // Use App Password
  },
});

export const sendOrderEmail = functions.firestore
  .document("emails/{emailId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    
    try {
      await transporter.sendMail({
        from: "revolvepartner0@gmail.com",
        to: data.to,
        subject: data.message.subject,
        text: data.message.text,
        html: generateEmailHTML(data),
      });

      // Mark email as processed
      await snap.ref.update({
        processed: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error("Error sending email:", error);
      await snap.ref.update({
        processed: false,
        error: error.message,
      });
    }
  });

function generateEmailHTML(data: any): string {
  return `
    <html>
      <body style="font-family: Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto;">
          <h2>Revolve Agro Order Notification</h2>
          <p>${data.message.text}</p>
          <p>Thank you for using Revolve Agro!</p>
        </div>
      </body>
    </html>
  `;
}
```

#### Step 3: Deploy Function
```bash
firebase deploy --only functions
```

#### Step 4: Set Environment Variables
```bash
firebase functions:config:set admin.email="revolvepartner0@gmail.com"
firebase functions:config:set admin.password="Revolvepartner@123"
firebase deploy --only functions
```

---

### Option 2: Using Third-Party Email Service (SendGrid, Mailgun)

If you prefer using SendGrid or Mailgun, create a Cloud Function:

```typescript
import * as functions from "firebase-functions";
import * as sgMail from "@sendgrid/mail";

sgMail.setApiKey(process.env.SENDGRID_API_KEY || "your-api-key");

export const sendOrderEmailSendGrid = functions.firestore
  .document("emails/{emailId}")
  .onCreate(async (snap) => {
    const data = snap.data();

    try {
      await sgMail.send({
        to: data.to,
        from: "orders@revolveagro.com",
        subject: data.message.subject,
        text: data.message.text,
        html: data.message.html,
      });

      await snap.ref.update({
        processed: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error("Error:", error);
    }
  });
```

---

## Order Tracking Implementation

### Admin Dashboard Updates

Admins can update tracking status from the approved orders view:

1. Click on an approved order card
2. Click "Update Tracking Status"
3. Select status and enter tracking number (optional)
4. User will see the delivery status in their order history

### Firestore Triggers (Optional)

```typescript
export const onOrderApproved = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    // When status changes to approved
    if (before.status !== "approved" && after.status === "approved") {
      // Send approval email
      await admin.firestore().collection("emails").add({
        to: after.userEmail,
        message: {
          subject: `Order #${change.after.id} Approved`,
          text: `Your order has been approved!`,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
```

---

## Firestore Security Rules

Update your Firestore rules to protect email documents:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /orders/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    match /emails/{document=**} {
      allow read, write: if request.auth.token.admin == true;
    }
  }
}
```

---

## Frontend Integration

All features are already integrated in:

- **Admin Orders Page** (`lib/screens/admin_orders_page.dart`)
  - Rejection reason dialog
  - Bulk selection and actions
  - Timeline view
  - Tracking status display

- **Order History Page** (`lib/screens/order_history_page.dart`)
  - Rejection reason display
  - Timeline (expandable)
  - Tracking status display

- **Email Service** (`lib/services/email_service.dart`)
  - Queues emails to Firestore
  - Supports approval/rejection notifications

---

## Testing the Features

### Test Rejection Reason:
1. Admin selects a pending order
2. Clicks "Reject" button
3. Enters rejection reason
4. Order moves to "Rejected" tab
5. User sees reason in order history

### Test Bulk Actions:
1. Check multiple order checkboxes
2. Click "Approve All" or "Reject All"
3. All selected orders update simultaneously

### Test Timeline:
1. Expand "Order Timeline" in user order history
2. See each status change with timestamp
3. View rejection reasons if applicable

### Test Tracking Status:
1. Admin approves an order
2. Admin updates tracking status to "shipped"
3. User sees "Shipped" badge in order history

---

## Important Notes

1. **Email Credentials**: Store credentials in Firebase Environment Variables, not in code
2. **App Passwords**: For Gmail, use 16-character App Passwords (not regular password)
3. **Rate Limiting**: Gmail allows ~100 emails/day for free tier
4. **Firestore Indexes**: Ensure composite indexes are created for queries
5. **Testing**: Use Firebase Emulator for local testing

---

## Troubleshooting

### Emails Not Sending:
- Check Cloud Functions logs: `firebase functions:log`
- Verify email service credentials
- Check Firestore "emails" collection for errors

### Timeline Not Showing:
- Ensure orders have `statusHistory` field
- Data Migration: Update existing orders with status history

### Bulk Actions Not Working:
- Check browser console for errors
- Verify Firestore write permissions
- Check batch size (max 500 operations)

---

## Future Enhancements

- SMS notifications for order status
- Push notifications
- Order rating/review system
- Automated reminders for pending orders
- Email templates with order details
- Admin dashboard analytics

