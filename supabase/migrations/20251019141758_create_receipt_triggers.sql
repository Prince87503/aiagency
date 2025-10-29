/*
  # Create Receipt Triggers for API Webhooks
  
  1. Triggers
    - Receipt Created: Fires when a new receipt is inserted
    - Receipt Updated: Fires when a receipt is updated
    - Receipt Deleted: Fires when a receipt is deleted
    
  2. Webhook Events
    - receipt.created
    - receipt.updated
    - receipt.refunded (special event when status changes to 'Refunded')
    - receipt.failed (special event when status changes to 'Failed')
    - receipt.deleted
    
  3. Payload Structure
    - trigger_event: The event type
    - table_name: 'receipts'
    - record_id: The receipt UUID
    - receipt_id: Human-readable receipt ID
    - data: The receipt record data
    - old_data: Previous data (for updates/deletes)
*/

-- Trigger for receipt created
CREATE OR REPLACE FUNCTION notify_receipt_created()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    'receipt.created',
    'receipts',
    NEW.id,
    jsonb_build_object(
      'receipt_id', NEW.receipt_id,
      'invoice_id', NEW.invoice_id,
      'subscription_id', NEW.subscription_id,
      'customer_id', NEW.customer_id,
      'customer_name', NEW.customer_name,
      'customer_email', NEW.customer_email,
      'payment_method', NEW.payment_method,
      'payment_reference', NEW.payment_reference,
      'amount_paid', NEW.amount_paid,
      'currency', NEW.currency,
      'payment_date', NEW.payment_date,
      'description', NEW.description,
      'notes', NEW.notes,
      'status', NEW.status,
      'created_at', NEW.created_at
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS receipt_created_trigger ON receipts;
CREATE TRIGGER receipt_created_trigger
  AFTER INSERT ON receipts
  FOR EACH ROW
  EXECUTE FUNCTION notify_receipt_created();

-- Trigger for receipt updated
CREATE OR REPLACE FUNCTION notify_receipt_updated()
RETURNS TRIGGER AS $$
DECLARE
  event_type text;
BEGIN
  event_type := 'receipt.updated';
  
  IF OLD.status != NEW.status THEN
    IF NEW.status = 'Refunded' THEN
      event_type := 'receipt.refunded';
    ELSIF NEW.status = 'Failed' THEN
      event_type := 'receipt.failed';
    END IF;
  END IF;
  
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    event_type,
    'receipts',
    NEW.id,
    jsonb_build_object(
      'receipt_id', NEW.receipt_id,
      'invoice_id', NEW.invoice_id,
      'subscription_id', NEW.subscription_id,
      'customer_name', NEW.customer_name,
      'customer_email', NEW.customer_email,
      'payment_method', NEW.payment_method,
      'payment_reference', NEW.payment_reference,
      'amount_paid', NEW.amount_paid,
      'status', NEW.status,
      'refund_amount', NEW.refund_amount,
      'refund_date', NEW.refund_date,
      'refund_reason', NEW.refund_reason,
      'updated_at', NEW.updated_at,
      'old_status', OLD.status,
      'old_refund_amount', OLD.refund_amount
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS receipt_updated_trigger ON receipts;
CREATE TRIGGER receipt_updated_trigger
  AFTER UPDATE ON receipts
  FOR EACH ROW
  EXECUTE FUNCTION notify_receipt_updated();

-- Trigger for receipt deleted
CREATE OR REPLACE FUNCTION notify_receipt_deleted()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    'receipt.deleted',
    'receipts',
    OLD.id,
    jsonb_build_object(
      'receipt_id', OLD.receipt_id,
      'customer_name', OLD.customer_name,
      'customer_email', OLD.customer_email,
      'amount_paid', OLD.amount_paid,
      'payment_date', OLD.payment_date,
      'status', OLD.status,
      'deleted_at', NOW()
    )
  );
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS receipt_deleted_trigger ON receipts;
CREATE TRIGGER receipt_deleted_trigger
  AFTER DELETE ON receipts
  FOR EACH ROW
  EXECUTE FUNCTION notify_receipt_deleted();

COMMENT ON FUNCTION notify_receipt_created() IS 'Sends webhook notification when receipt is created';
COMMENT ON FUNCTION notify_receipt_updated() IS 'Sends webhook notification when receipt is updated, including special events for refunded and failed';
COMMENT ON FUNCTION notify_receipt_deleted() IS 'Sends webhook notification when receipt is deleted';
