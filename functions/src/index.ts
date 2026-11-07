import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

// Set your n8n Webhook URL here (or use defineSecret/environment variables in production)
const N8N_WEBHOOK_URL = "https://YOUR_N8N_INSTANCE.com/webhook/emma-whatsapp-webhook";

/**
 * 1. Triggered when a participant submits a new drive registration
 */
export const onDriveSubmissionCreated = onDocumentCreated(
  "drive_submissions/{submissionId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();

    const payload = {
      event: "registration_success",
      submissionId: event.params.submissionId,
      participantName: data.participantName || "Participant",
      phone: data.participantPhone,
      driveTitle: data.driveTitle || "Emma Recycling Drive",
    };

    try {
      logger.info(`Sending registration event to n8n for ${payload.phone}`);

      const response = await fetch(N8N_WEBHOOK_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      logger.info(`n8n response status: ${response.status}`);
    } catch (error) {
      logger.error("Failed to send webhook to n8n:", error);
    }
  }
);

/**
 * 2. Triggered when the manufacturer verifies and updates the item weight
 */
export const onDriveSubmissionUpdated = onDocumentUpdated(
  "drive_submissions/{submissionId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    // Only trigger when status changes to 'verified' and weight is logged
    const isNowVerified = beforeData.status !== "verified" && afterData.status === "verified";

    if (isNowVerified) {
      const payload = {
        event: "submission_verified",
        submissionId: event.params.submissionId,
        participantName: afterData.participantName || "Participant",
        phone: afterData.participantPhone,
        driveTitle: afterData.driveTitle || "Emma Recycling Drive",
        weightKg: afterData.weightKg,
      };

      try {
        logger.info(`Sending verified weight event to n8n for ${payload.phone}`);

        const response = await fetch(N8N_WEBHOOK_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        logger.info(`n8n response status: ${response.status}`);
      } catch (error) {
        logger.error("Failed to send verification webhook to n8n:", error);
      }
    }
  }
);
