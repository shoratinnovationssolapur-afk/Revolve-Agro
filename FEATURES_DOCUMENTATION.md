# RevolveAgro Order Management - Feature Documentation

## 🎯 Overview

This document details all the new order management features added to the RevolveAgro app. These enhancements provide admins with powerful tools to manage orders and users with detailed order tracking information.

---

## ✨ New Features

### 1. Admin Rejection Reason
**Purpose:** Provide feedback to customers when rejecting orders

#### How it Works:
- Admin clicks "Reject" on a pending order
- A dialog appears requesting a rejection reason
- Admin enters the reason
- Order moves to "Rejected" tab with reason stored
- User sees the rejection reason in their order history

#### Files:
- `lib/screens/admin_orders_page.dart` - Rejection dialog UI
- Data stored in Firestore: `rejectionReason` field

#### Example Flow:
```
Admin Action: Click Reject → Enter "Out of stock" → Order rejected
User View: Order shows "Out of stock" as rejection reason
```

---

### 2. Email Notifications
**Purpose:** Automatically notify users when orders are approved or rejected

#### How it Works:
- When admin approves/rejects order, email is queued to Firestore
- Cloud Function triggers and sends email via Gmail/SendGrid
- User receives formatted HTML email with order details
- Email status is tracked in Firestore

#### Setup Required:
1. Follow Cloud Functions setup in `SETUP_GUIDE.md`
2. Deploy Cloud Functions with email service
3. Add credentials to Firebase environment variables

#### Email Triggers:
- **Approval Email:** Sent when order status changes to "approved"
- **Rejection Email:** Sent when order status changes to "rejected" with reason

#### Files:
- `lib/services/email_service.dart` - Email queuing service
- `cloud_functions_template.ts` - Cloud Functions code

---

### 3. Timeline View
**Purpose:** Show complete order status history with timestamps

#### How it Works:
- User clicks order in "Order History"
- Click "Order Timeline" to expand timeline
- See all status changes (pending → approved/rejected)
- Each status shows timestamp and rejection reason (if applicable)
- Timeline is collapsible for clean UI

#### Data Structure:
```json
{
  "statusHistory": [
    {
      "status": "pending",
      "timestamp": "2024-04-06T10:30:00Z"
    },
    {
      "status": "rejected",
      "timestamp": "2024-04-06T11:00:00Z",
      "reason": "Out of stock"
    }
  ]
}
```

#### Files:
- `lib/screens/order_history_page.dart` - Timeline UI
- `lib/screens/admin_orders_page.dart` - Admin timeline display

---

### 4. Order Tracking Status
**Purpose:** Track delivery status from processing to delivery

#### How it Works:
- Admin updates tracking status when order is approved
- Available statuses:
  - **Processing:** Order is being processed
  - **Shipped:** Order has been dispatched
  - **Delivered:** Order reached customer
- Admin can add tracking number and delivery notes
- User sees tracking badge in order history

#### Admin Flow:
1. Open approved order
2. Click "Update Tracking Status" (future enhancement)
3. Select status, add tracking number (optional)
4. User sees real-time delivery status

#### User View:
- Approved orders show tracking status badge
- Can see "Shipped" or "Delivered" status
- Optional tracking number display

#### Data Fields:
```json
{
  "trackingStatus": "processing|shipped|delivered|none",
  "trackingNumber": "ABC123456789",
  "trackingNotes": "Delivery scheduled for Apr 7",
  "trackingUpdatedAt": "2024-04-06T12:00:00Z"
}
```

#### Files:
- `lib/services/order_tracking_service.dart` - Tracking service
- `lib/screens/admin_tracking_status_dialog.dart` - Status update dialog
- `lib/screens/order_history_page.dart` - User tracking display

---

### 5. Bulk Actions
**Purpose:** Approve or reject multiple orders at once

#### How it Works:
- Admin selects multiple pending orders using checkboxes
- Bulk action toolbar appears at top
- Choose "Approve All" or "Reject All"
- All selected orders update with single database transaction
- Email notifications sent to all users
- Clear selection when done

#### Admin Flow:
1. Check orders to select (checkboxes appear on pending orders)
2. Bulk toolbar shows count of selected orders
3. Click "Approve All" or "Reject All"
4. Confirm action in dialog
5. Orders update, emails sent, selection clears

#### Features:
- **Progress Feedback:** Shows count of selected orders
- **Batch Operation:** All updates happen together
- **Email Notifications:** Each user gets notified
- **Error Handling:** Shows success/failure count
- **Clear Selection:** Easy way to deselect all

#### Files:
- `lib/screens/admin_orders_page.dart` - Bulk actions UI
- `lib/services/admin_order_management_service.dart` - Bulk operations service

---

## 🏗️ Architecture

### Database Schema Updates

**Orders Collection:**
```firestore
orders/{orderId}
├── status: "pending|approved|rejected"
├── rejectionReason: string (optional)
├── trackingStatus: "none|processing|shipped|delivered"
├── statusHistory: [
│   ├── status: string
│   ├── timestamp: Timestamp
│   └── reason: string (optional)
├── trackingNumber: string (optional)
├── trackingNotes: string (optional)
├── trackingUpdatedAt: Timestamp (optional)
└── ... (existing fields)
```

**Emails Collection (for Cloud Functions):**
```firestore
emails/{emailId}
├── to: string
├── message: {
│   ├── subject: string
│   └── text: string
├── status: "approved|rejected"
├── createdAt: Timestamp
├── processed: boolean
├── sentAt: Timestamp (optional)
├── error: string (optional)
└── failureCount: number (optional)
```

### Service Architecture

```
Services/
├── email_service.dart
│   ├── sendOrderApprovalEmail()
│   ├── sendOrderRejectionEmail()
│   └── _sendEmail()
├── order_tracking_service.dart
│   ├── updateTrackingStatus()
│   ├── getTrackingDetails()
│   └── getTrackingHistory()
└── admin_order_management_service.dart
    ├── bulkApproveOrders()
    ├── bulkRejectOrders()
    ├── getPendingOrdersCount()
    ├── getOrdersByDateRange()
    └── getOrderStatistics()
```

---

## 🔧 Implementation Details

### Feature Files

#### Screens:
- `lib/screens/admin_orders_page.dart` - Enhanced admin panel
- `lib/screens/order_history_page.dart` - Enhanced user order history
- `lib/screens/admin_tracking_status_dialog.dart` - Tracking status UI
- `lib/screens/payment_page.dart` - Updated to initialize status history

#### Services:
- `lib/services/email_service.dart` - Email notification service
- `lib/services/order_tracking_service.dart` - Tracking management
- `lib/services/admin_order_management_service.dart` - Bulk operations

#### Configuration:
- `SETUP_GUIDE.md` - Complete setup instructions
- `cloud_functions_template.ts` - Cloud Functions code template

### Key Methods

#### Admin Order Update:
```dart
_showRejectDialog(context, orderId, orderData)
  → Shows reason dialog
  → Calls _updateOrderStatus() with reason

_updateOrderStatus(context, orderId, status, orderData)
  → Updates Firestore with status
  → Adds to statusHistory
  → Sends email notification
  → Shows feedback
```

#### Bulk Actions:
```dart
_bulkApproveOrders()
  → Gets selected order IDs
  → Updates all in batch
  → Sends emails in parallel
  → Clears selection

_bulkRejectOrders()
  → Similar to approve but with reason dialog
  → Uses single reason for all orders
```

---

## 📱 User Interface Changes

### Admin Orders Page
- ✅ Checkboxes for bulk selection (pending orders only)
- ✅ Bulk action toolbar (shows when orders selected)
- ✅ Rejection reason input dialog
- ✅ Timeline view in order cards
- ✅ Tracking status badge display
- ✅ Email confirmation in snackbars

### Order History Page (User)
- ✅ Rejection reason display (prominent red box)
- ✅ Tracking status badge (blue box)
- ✅ Expandable timeline with all status changes
- ✅ Status messages with icons
- ✅ Formatted timestamps

---

## 🚀 Getting Started

### Quick Setup Checklist

1. **Database Schema** ✓ (Already in code)
   - New fields are backward compatible
   - Existing orders will work fine

2. **Email Notifications** (Required for feature to work)
   - [ ] Follow `SETUP_GUIDE.md` for Cloud Functions
   - [ ] Deploy email Cloud Function
   - [ ] Test email sending

3. **Firestore Indexes** (Required)
   - [ ] Create composite indexes (see SETUP_GUIDE.md)
   - [ ] Or wait for Firebase to prompt

4. **Test Features**
   - [ ] Reject an order with reason
   - [ ] Check user sees rejection reason
   - [ ] Select multiple orders
   - [ ] Bulk approve/reject
   - [ ] Update tracking status
   - [ ] Verify timeline shows updates

---

## 📊 Statistics & Metrics

### Available Statistics (via AdminOrderManagementService)
```dart
getOrderStatistics() returns:
{
  'pending': int,
  'approved': int,
  'rejected': int,
  'total': int
}
```

### Order Trends
- Query orders by date range
- Filter by status
- Get stream updates

---

## 🔒 Security Considerations

### Email Security
- Credentials stored in Firebase Environment Variables (not in code)
- Use App Passwords for Gmail (not regular password)
- Firestore rules restrict email collection access

### Data Protection
- Only admin users can modify order status
- Email addresses from verified Firebase accounts
- Status history is immutable (append-only)

### Firestore Rules Example:
```
match /orders/{document=**} {
  allow read: if request.auth != null;
  allow write: if request.auth.token.admin == true;
}

match /emails/{document=**} {
  allow read, write: if request.auth.token.admin == true;
}
```

---

## 🐛 Troubleshooting

### Email Not Sending
Check:
- [ ] Cloud Function deployed
- [ ] Gmail credentials correct
- [ ] "emails" collection exists in Firestore
- [ ] Check Cloud Function logs: `firebase functions:log`

### Bulk Actions Not Working
Check:
- [ ] Firestore write permissions
- [ ] No batch size limit exceeded (max 500)
- [ ] Orders actually exist in database

### Timeline Not Showing
Check:
- [ ] Existing orders have `statusHistory` field
- [ ] Run migration: Update all orders with empty `statusHistory: []`

### Tracking Status Not Updating
Check:
- [ ] Order status is "approved" first
- [ ] Service method called with valid status
- [ ] Check Firestore document directly

---

## 📈 Future Enhancements

1. **SMS Notifications** - Send status updates via SMS
2. **Push Notifications** - In-app order status alerts
3. **Email Templates** - Customizable HTML templates
4. **Automated Reminders** - Reminder emails for pending orders
5. **Admin Dashboard** - Order statistics and charts
6. **Review System** - Order ratings/reviews after delivery
7. **Return Management** - Process returns and refunds
8. **Inventory Integration** - Auto-approve based on stock

---

## 📞 Support

For issues or questions:
1. Check the `SETUP_GUIDE.md`
2. Review error messages in Firebase Console
3. Check Cloud Function logs
4. Verify Firestore schema matches documentation

