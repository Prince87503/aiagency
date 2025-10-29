/*
  # Create Estimate Triggers for API Webhooks
  
  1. Triggers
    - Estimate Created: Fires when a new estimate is inserted
    - Estimate Updated: Fires when an estimate is updated
    - Estimate Deleted: Fires when an estimate is deleted
    
  2. Webhook Events
    - estimate.created
    - estimate.updated
    - estimate.deleted
    
  3. Payload Structure
    - trigger_event: The event type
    - table_name: 'estimates'
    - record_id: The estimate UUID
    - estimate_id: Human-readable estimate ID
    - data: The estimate record data
    - old_data: Previous data (for updates/deletes)
*/

-- Trigger for estimate created
CREATE OR REPLACE FUNCTION notify_estimate_created()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    'estimate.created',
    'estimates',
    NEW.id,
    jsonb_build_object(
      'estimate_id', NEW.estimate_id,
      'customer_id', NEW.customer_id,
      'customer_name', NEW.customer_name,
      'customer_email', NEW.customer_email,
      'customer_phone', NEW.customer_phone,
      'title', NEW.title,
      'items', NEW.items,
      'subtotal', NEW.subtotal,
      'discount', NEW.discount,
      'tax_rate', NEW.tax_rate,
      'tax_amount', NEW.tax_amount,
      'total_amount', NEW.total_amount,
      'notes', NEW.notes,
      'status', NEW.status,
      'valid_until', NEW.valid_until,
      'created_at', NEW.created_at,
      'updated_at', NEW.updated_at,
      'sent_at', NEW.sent_at,
      'responded_at', NEW.responded_at
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS estimate_created_trigger ON estimates;
CREATE TRIGGER estimate_created_trigger
  AFTER INSERT ON estimates
  FOR EACH ROW
  EXECUTE FUNCTION notify_estimate_created();

-- Trigger for estimate updated
CREATE OR REPLACE FUNCTION notify_estimate_updated()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    'estimate.updated',
    'estimates',
    NEW.id,
    jsonb_build_object(
      'estimate_id', NEW.estimate_id,
      'customer_id', NEW.customer_id,
      'customer_name', NEW.customer_name,
      'customer_email', NEW.customer_email,
      'customer_phone', NEW.customer_phone,
      'title', NEW.title,
      'items', NEW.items,
      'subtotal', NEW.subtotal,
      'discount', NEW.discount,
      'tax_rate', NEW.tax_rate,
      'tax_amount', NEW.tax_amount,
      'total_amount', NEW.total_amount,
      'notes', NEW.notes,
      'status', NEW.status,
      'valid_until', NEW.valid_until,
      'created_at', NEW.created_at,
      'updated_at', NEW.updated_at,
      'sent_at', NEW.sent_at,
      'responded_at', NEW.responded_at,
      'old_status', OLD.status,
      'old_total_amount', OLD.total_amount
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS estimate_updated_trigger ON estimates;
CREATE TRIGGER estimate_updated_trigger
  AFTER UPDATE ON estimates
  FOR EACH ROW
  EXECUTE FUNCTION notify_estimate_updated();

-- Trigger for estimate deleted
CREATE OR REPLACE FUNCTION notify_estimate_deleted()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    'estimate.deleted',
    'estimates',
    OLD.id,
    jsonb_build_object(
      'estimate_id', OLD.estimate_id,
      'customer_name', OLD.customer_name,
      'customer_email', OLD.customer_email,
      'title', OLD.title,
      'total_amount', OLD.total_amount,
      'status', OLD.status,
      'deleted_at', NOW()
    )
  );
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS estimate_deleted_trigger ON estimates;
CREATE TRIGGER estimate_deleted_trigger
  AFTER DELETE ON estimates
  FOR EACH ROW
  EXECUTE FUNCTION notify_estimate_deleted();

COMMENT ON FUNCTION notify_estimate_created() IS 'Sends webhook notification when estimate is created';
COMMENT ON FUNCTION notify_estimate_updated() IS 'Sends webhook notification when estimate is updated';
COMMENT ON FUNCTION notify_estimate_deleted() IS 'Sends webhook notification when estimate is deleted';
