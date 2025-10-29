/*
  # Add Billing Workflow Triggers

  Adds trigger definitions for estimates, invoices, subscriptions, and receipts
  to the workflow_triggers table so they appear in the workflow builder UI
  and can be used to trigger automations.

  1. New Workflow Triggers
    - ESTIMATE_CREATED, ESTIMATE_UPDATED, ESTIMATE_DELETED
    - INVOICE_CREATED, INVOICE_UPDATED, INVOICE_DELETED
    - SUBSCRIPTION_CREATED, SUBSCRIPTION_UPDATED, SUBSCRIPTION_DELETED
    - RECEIPT_CREATED, RECEIPT_UPDATED, RECEIPT_DELETED

  2. Event Schemas
    - Each trigger includes detailed event schema with all relevant fields
    - Schemas define what data is available for workflow automations
    - Includes both current and previous values for update events
*/

-- Insert ESTIMATE_CREATED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'estimate_created',
  'Estimate Created',
  'Triggered when a new estimate is created',
  'ESTIMATE_CREATED',
  '[
    {"field": "estimate_id", "type": "text", "description": "Human-readable estimate ID (e.g., EST0001)"},
    {"field": "customer_id", "type": "uuid", "description": "Customer unique identifier"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "customer_phone", "type": "text", "description": "Customer phone"},
    {"field": "title", "type": "text", "description": "Estimate title"},
    {"field": "items", "type": "jsonb", "description": "Line items array"},
    {"field": "subtotal", "type": "numeric", "description": "Subtotal amount"},
    {"field": "discount", "type": "numeric", "description": "Discount amount"},
    {"field": "tax_rate", "type": "numeric", "description": "Tax rate percentage"},
    {"field": "tax_amount", "type": "numeric", "description": "Calculated tax amount"},
    {"field": "total_amount", "type": "numeric", "description": "Total amount"},
    {"field": "notes", "type": "text", "description": "Internal notes"},
    {"field": "status", "type": "text", "description": "Draft, Sent, Accepted, Declined, Expired"},
    {"field": "valid_until", "type": "date", "description": "Estimate validity date"},
    {"field": "created_at", "type": "timestamptz", "description": "When created"},
    {"field": "sent_at", "type": "timestamptz", "description": "When sent to customer"}
  ]'::jsonb,
  'Billing',
  'file-text'
) ON CONFLICT (name) DO NOTHING;

-- Insert ESTIMATE_UPDATED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'estimate_updated',
  'Estimate Updated',
  'Triggered when an estimate is updated',
  'ESTIMATE_UPDATED',
  '[
    {"field": "estimate_id", "type": "text", "description": "Human-readable estimate ID (e.g., EST0001)"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "title", "type": "text", "description": "Estimate title"},
    {"field": "total_amount", "type": "numeric", "description": "Total amount"},
    {"field": "status", "type": "text", "description": "Draft, Sent, Accepted, Declined, Expired"},
    {"field": "updated_at", "type": "timestamptz", "description": "When updated"},
    {"field": "old_status", "type": "text", "description": "Previous status"},
    {"field": "old_total_amount", "type": "numeric", "description": "Previous total amount"}
  ]'::jsonb,
  'Billing',
  'file-text'
) ON CONFLICT (name) DO NOTHING;

-- Insert ESTIMATE_DELETED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'estimate_deleted',
  'Estimate Deleted',
  'Triggered when an estimate is deleted',
  'ESTIMATE_DELETED',
  '[
    {"field": "estimate_id", "type": "text", "description": "Human-readable estimate ID (e.g., EST0001)"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "title", "type": "text", "description": "Estimate title"},
    {"field": "total_amount", "type": "numeric", "description": "Total amount"},
    {"field": "status", "type": "text", "description": "Status at deletion"},
    {"field": "deleted_at", "type": "timestamptz", "description": "When deleted"}
  ]'::jsonb,
  'Billing',
  'file-text'
) ON CONFLICT (name) DO NOTHING;

-- Insert INVOICE_CREATED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'invoice_created',
  'Invoice Created',
  'Triggered when a new invoice is created',
  'INVOICE_CREATED',
  '[
    {"field": "invoice_id", "type": "text", "description": "Human-readable invoice ID (e.g., INV0001)"},
    {"field": "estimate_id", "type": "text", "description": "Related estimate ID (if converted)"},
    {"field": "customer_id", "type": "uuid", "description": "Customer unique identifier"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "title", "type": "text", "description": "Invoice title"},
    {"field": "items", "type": "jsonb", "description": "Line items array"},
    {"field": "total_amount", "type": "numeric", "description": "Total amount"},
    {"field": "paid_amount", "type": "numeric", "description": "Amount paid"},
    {"field": "balance_due", "type": "numeric", "description": "Balance due"},
    {"field": "status", "type": "text", "description": "Draft, Sent, Paid, Overdue, Cancelled"},
    {"field": "payment_method", "type": "text", "description": "Payment method"},
    {"field": "issue_date", "type": "date", "description": "Invoice issue date"},
    {"field": "due_date", "type": "date", "description": "Payment due date"},
    {"field": "created_at", "type": "timestamptz", "description": "When created"}
  ]'::jsonb,
  'Billing',
  'receipt'
) ON CONFLICT (name) DO NOTHING;

-- Insert INVOICE_UPDATED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'invoice_updated',
  'Invoice Updated',
  'Triggered when an invoice is updated (status change, payment received)',
  'INVOICE_UPDATED',
  '[
    {"field": "invoice_id", "type": "text", "description": "Human-readable invoice ID (e.g., INV0001)"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "title", "type": "text", "description": "Invoice title"},
    {"field": "total_amount", "type": "numeric", "description": "Total amount"},
    {"field": "paid_amount", "type": "numeric", "description": "Amount paid"},
    {"field": "balance_due", "type": "numeric", "description": "Balance due"},
    {"field": "status", "type": "text", "description": "Draft, Sent, Paid, Overdue, Cancelled"},
    {"field": "payment_method", "type": "text", "description": "Payment method"},
    {"field": "due_date", "type": "date", "description": "Payment due date"},
    {"field": "paid_date", "type": "date", "description": "Date payment received"},
    {"field": "updated_at", "type": "timestamptz", "description": "When updated"},
    {"field": "old_status", "type": "text", "description": "Previous status"},
    {"field": "old_paid_amount", "type": "numeric", "description": "Previous paid amount"},
    {"field": "old_balance_due", "type": "numeric", "description": "Previous balance due"}
  ]'::jsonb,
  'Billing',
  'receipt'
) ON CONFLICT (name) DO NOTHING;

-- Insert INVOICE_DELETED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'invoice_deleted',
  'Invoice Deleted',
  'Triggered when an invoice is deleted',
  'INVOICE_DELETED',
  '[
    {"field": "invoice_id", "type": "text", "description": "Human-readable invoice ID (e.g., INV0001)"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "title", "type": "text", "description": "Invoice title"},
    {"field": "total_amount", "type": "numeric", "description": "Total amount"},
    {"field": "balance_due", "type": "numeric", "description": "Balance due at deletion"},
    {"field": "status", "type": "text", "description": "Status at deletion"},
    {"field": "deleted_at", "type": "timestamptz", "description": "When deleted"}
  ]'::jsonb,
  'Billing',
  'receipt'
) ON CONFLICT (name) DO NOTHING;

-- Insert SUBSCRIPTION_CREATED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'subscription_created',
  'Subscription Created',
  'Triggered when a new subscription is created',
  'SUBSCRIPTION_CREATED',
  '[
    {"field": "subscription_id", "type": "text", "description": "Human-readable subscription ID (e.g., SUB0001)"},
    {"field": "customer_id", "type": "uuid", "description": "Customer unique identifier"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "plan_name", "type": "text", "description": "Subscription plan name"},
    {"field": "plan_type", "type": "text", "description": "Monthly, Quarterly, Yearly, Lifetime"},
    {"field": "amount", "type": "numeric", "description": "Subscription amount"},
    {"field": "currency", "type": "text", "description": "Currency code"},
    {"field": "billing_cycle_day", "type": "integer", "description": "Day of month for billing (1-31)"},
    {"field": "status", "type": "text", "description": "Active, Paused, Cancelled, Expired"},
    {"field": "payment_method", "type": "text", "description": "Payment method"},
    {"field": "start_date", "type": "date", "description": "Subscription start date"},
    {"field": "end_date", "type": "date", "description": "Subscription end date"},
    {"field": "next_billing_date", "type": "date", "description": "Next billing date"},
    {"field": "auto_renew", "type": "boolean", "description": "Auto-renewal enabled"},
    {"field": "created_at", "type": "timestamptz", "description": "When created"}
  ]'::jsonb,
  'Billing',
  'repeat'
) ON CONFLICT (name) DO NOTHING;

-- Insert SUBSCRIPTION_UPDATED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'subscription_updated',
  'Subscription Updated',
  'Triggered when a subscription is updated (status change, renewal, cancellation)',
  'SUBSCRIPTION_UPDATED',
  '[
    {"field": "subscription_id", "type": "text", "description": "Human-readable subscription ID (e.g., SUB0001)"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "plan_name", "type": "text", "description": "Subscription plan name"},
    {"field": "amount", "type": "numeric", "description": "Subscription amount"},
    {"field": "status", "type": "text", "description": "Active, Paused, Cancelled, Expired"},
    {"field": "payment_method", "type": "text", "description": "Payment method"},
    {"field": "next_billing_date", "type": "date", "description": "Next billing date"},
    {"field": "auto_renew", "type": "boolean", "description": "Auto-renewal enabled"},
    {"field": "updated_at", "type": "timestamptz", "description": "When updated"},
    {"field": "cancelled_at", "type": "timestamptz", "description": "When cancelled (if applicable)"},
    {"field": "cancelled_reason", "type": "text", "description": "Cancellation reason"},
    {"field": "old_status", "type": "text", "description": "Previous status"},
    {"field": "old_next_billing_date", "type": "date", "description": "Previous next billing date"}
  ]'::jsonb,
  'Billing',
  'repeat'
) ON CONFLICT (name) DO NOTHING;

-- Insert SUBSCRIPTION_DELETED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'subscription_deleted',
  'Subscription Deleted',
  'Triggered when a subscription is deleted from the system',
  'SUBSCRIPTION_DELETED',
  '[
    {"field": "subscription_id", "type": "text", "description": "Human-readable subscription ID (e.g., SUB0001)"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "plan_name", "type": "text", "description": "Subscription plan name"},
    {"field": "amount", "type": "numeric", "description": "Subscription amount"},
    {"field": "status", "type": "text", "description": "Status at deletion"},
    {"field": "deleted_at", "type": "timestamptz", "description": "When deleted"}
  ]'::jsonb,
  'Billing',
  'repeat'
) ON CONFLICT (name) DO NOTHING;

-- Insert RECEIPT_CREATED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'receipt_created',
  'Receipt Created',
  'Triggered when a new payment receipt is created',
  'RECEIPT_CREATED',
  '[
    {"field": "receipt_id", "type": "text", "description": "Human-readable receipt ID (e.g., REC0001)"},
    {"field": "invoice_id", "type": "text", "description": "Related invoice ID (if applicable)"},
    {"field": "subscription_id", "type": "text", "description": "Related subscription ID (if applicable)"},
    {"field": "customer_id", "type": "uuid", "description": "Customer unique identifier"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "payment_method", "type": "text", "description": "Payment method"},
    {"field": "payment_reference", "type": "text", "description": "Payment reference/transaction ID"},
    {"field": "amount_paid", "type": "numeric", "description": "Amount paid"},
    {"field": "currency", "type": "text", "description": "Currency code"},
    {"field": "payment_date", "type": "date", "description": "Payment date"},
    {"field": "description", "type": "text", "description": "Payment description"},
    {"field": "status", "type": "text", "description": "Completed, Pending, Failed, Refunded"},
    {"field": "created_at", "type": "timestamptz", "description": "When created"}
  ]'::jsonb,
  'Billing',
  'credit-card'
) ON CONFLICT (name) DO NOTHING;

-- Insert RECEIPT_UPDATED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'receipt_updated',
  'Receipt Updated',
  'Triggered when a receipt is updated (status change, refund processed)',
  'RECEIPT_UPDATED',
  '[
    {"field": "receipt_id", "type": "text", "description": "Human-readable receipt ID (e.g., REC0001)"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "payment_method", "type": "text", "description": "Payment method"},
    {"field": "payment_reference", "type": "text", "description": "Payment reference/transaction ID"},
    {"field": "amount_paid", "type": "numeric", "description": "Amount paid"},
    {"field": "status", "type": "text", "description": "Completed, Pending, Failed, Refunded"},
    {"field": "refund_amount", "type": "numeric", "description": "Refund amount (if applicable)"},
    {"field": "refund_date", "type": "date", "description": "Refund date"},
    {"field": "refund_reason", "type": "text", "description": "Refund reason"},
    {"field": "updated_at", "type": "timestamptz", "description": "When updated"},
    {"field": "old_status", "type": "text", "description": "Previous status"},
    {"field": "old_refund_amount", "type": "numeric", "description": "Previous refund amount"}
  ]'::jsonb,
  'Billing',
  'credit-card'
) ON CONFLICT (name) DO NOTHING;

-- Insert RECEIPT_DELETED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'receipt_deleted',
  'Receipt Deleted',
  'Triggered when a receipt is deleted from the system',
  'RECEIPT_DELETED',
  '[
    {"field": "receipt_id", "type": "text", "description": "Human-readable receipt ID (e.g., REC0001)"},
    {"field": "customer_name", "type": "text", "description": "Customer name"},
    {"field": "customer_email", "type": "text", "description": "Customer email"},
    {"field": "amount_paid", "type": "numeric", "description": "Amount paid"},
    {"field": "payment_date", "type": "date", "description": "Payment date"},
    {"field": "status", "type": "text", "description": "Status at deletion"},
    {"field": "deleted_at", "type": "timestamptz", "description": "When deleted"}
  ]'::jsonb,
  'Billing',
  'credit-card'
) ON CONFLICT (name) DO NOTHING;

-- Add comments
COMMENT ON COLUMN workflow_triggers.name IS 'Unique trigger name used in code and database triggers';
COMMENT ON COLUMN workflow_triggers.event_name IS 'Event name used in api_webhooks and workflow automations';
