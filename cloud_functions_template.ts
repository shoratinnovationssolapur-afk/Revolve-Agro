/** 
 * Firestore Cloud Function for sending order notification emails
 * Place this in your Firebase Cloud Functions (functions/src/sendOrderEmail.ts)
 * 
 * Setup:
 * 1. npm install nodemailer in functions directory
 * 2. Set environment variables with firebase functions:config:set
 * 3. Deploy with firebase deploy --only functions
 */

import * as functions from "firebase-functions";
import * as nodemailer from "nodemailer";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// Gmail configuration
// Important: Use App Passwords (not regular password) for Gmail
// Enable Less Secure App Access: https://myaccount.google.com/lesssecureapps
// Or better: Use App Password: https://myaccount.google.com/apppasswords

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "revolvepartner0@gmail.com",
    pass: "Revolvepartner@123", // Consider using environment variable
  },
});

/**
 * Cloud Function triggers when an email document is created in Firestore
 * Email documents should have: to, message {subject, text}, status, createdAt
 */
export const sendOrderEmail = functions.firestore
  .document("emails/{emailId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const emailId = snap.ref.id;

    const mailOptions = {
      from: '"Revolve Agro" <revolvepartner0@gmail.com>',
      to: data.to,
      subject: data.message.subject,
      html: generateEmailHTML(data),
    };

    try {
      // Send email
      await transporter.sendMail(mailOptions);

      // Mark as processed in Firestore
      await snap.ref.update({
        processed: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "sent",
      });

      console.log(`Email sent successfully to ${data.to}`);
    } catch (error) {
      console.error(`Error sending email to ${data.to}:`, error);

      // Update with error details
      await snap.ref.update({
        processed: false,
        error: error instanceof Error ? error.message : String(error),
        failureCount: admin.firestore.FieldValue.increment(1),
        lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

/**
 * Retry failed emails (runs daily)
 */
export const retryFailedEmails = functions.pubsub
  .schedule("every 1 hour")
  .onRun(async (context) => {
    try {
      const failedEmails = await db
        .collection("emails")
        .where("processed", "==", false)
        .where("failureCount", "<", 3)
        .limit(10)
        .get();

      for (const doc of failedEmails.docs) {
        const data = doc.data();

        const mailOptions = {
          from: '"Revolve Agro" <revolvepartner0@gmail.com>',
          to: data.to,
          subject: data.message.subject,
          html: generateEmailHTML(data),
        };

        try {
          await transporter.sendMail(mailOptions);
          await doc.ref.update({
            processed: true,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (error) {
          await doc.ref.update({
            failureCount: admin.firestore.FieldValue.increment(1),
            lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      console.log(`Retry job completed. Processed ${failedEmails.docs.length} failed emails.`);
    } catch (error) {
      console.error("Retry job failed:", error);
    }
  });

/**
 * Generate HTML email template
 */
function generateEmailHTML(data: any): string {
  const text = data.message.text || "";
  const status = data.status || "unknown";

  const statusColor =
    status === "approved"
      ? "#4CAF50"
      : status === "rejected"
      ? "#f44336"
      : "#ff9800";

  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
          }
          .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f7f3e8;
          }
          .header {
            background-color: #2f6a3e;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 8px 8px 0 0;
          }
          .content {
            background-color: white;
            padding: 30px;
            border-bottom: 1px solid #e0e0e0;
          }
          .status-badge {
            background-color: ${statusColor};
            color: white;
            padding: 10px 20px;
            border-radius: 20px;
            display: inline-block;
            font-weight: bold;
            margin: 10px 0;
          }
          .footer {
            background-color: #f7f3e8;
            padding: 20px;
            text-align: center;
            border-radius: 0 0 8px 8px;
            font-size: 12px;
            color: #666;
          }
          .button {
            background-color: #2f6a3e;
            color: white;
            padding: 12px 30px;
            text-decoration: none;
            border-radius: 5px;
            display: inline-block;
            margin: 20px 0;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Revolve Agro Order Management</h1>
          </div>
          <div class="content">
            <p>Dear Customer,</p>
            <p>${text}</p>
            <div class="status-badge">${status.toUpperCase()}</div>
            <p>
              If you have any questions about your order, please don't hesitate
              to contact us.
            </p>
            <a href="https://revolveagro.com" class="button">View Your Order</a>
          </div>
          <div class="footer">
            <p>&copy; 2024 Revolve Agro. All rights reserved.</p>
            <p>
              This is an automated email. Please don't reply to this email.
            </p>
          </div>
        </div>
      </body>
    </html>
  `;
}

/**
 * Optional: HTTP function to manually send emails (for testing)
 */
export const sendEmailManually = functions.https.onRequest(
  async (request, response) => {
    const { to, subject, text, status } = request.body;

    if (!to || !subject || !text) {
      return response.status(400).send("Missing required fields");
    }

    try {
      // Store in Firestore for Cloud Function to process
      await db.collection("emails").add({
        to,
        message: { subject, text },
        status,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        processed: false,
      });

      response.send("Email queued successfully");
    } catch (error) {
      response.status(500).send("Error: " + String(error));
    }
  }
);
