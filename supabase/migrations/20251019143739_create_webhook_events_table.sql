/*
  # Drop Webhook Events Table (Not Needed)

  This migration was originally created to store webhook events in a separate table,
  but we've decided to follow the same pattern as other modules (leads, affiliates, etc.)
  by using the api_webhooks table and sending HTTP POST requests directly to configured
  webhook URLs.

  This migration now drops the webhook_events table if it exists.
*/

-- Drop the webhook_events table if it exists
DROP TABLE IF EXISTS webhook_events CASCADE;

-- The billing triggers now follow the same pattern as other modules:
-- They read from api_webhooks table and send HTTP POST requests to configured webhook URLs.
