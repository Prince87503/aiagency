/*
  # Create Invoice Triggers for API Webhooks
  
  1. Triggers
    - Invoice Created: Fires when a new invoice is inserted
    - Invoice Updated: Fires when an invoice is updated (status changes, payments)
    - Invoice Deleted: Fires when an invoice is deleted
    
  2. Webhook Events
    - invoice.created
    - invoice.updated
    - invoice.deleted
    - invoice.paid (special event when status changes to 'Paid')
    - invoice.overdue (special event when status changes to 'Overdue')
    
  3. Payload Structure
    - trigger_event: The event type
    - table_name: 'invoices'
    - record_id: The invoice UUID
    - invoice_id: Human-readable invoice ID
    - data: The invoice record data
    - old_data: Previous data (for updates/deletes)
*/

-- Trigger for invoice created
CREATE OR REPLACE FUNCTION notify_invoice_created()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    'invoice.created',
    'invoices',
    NEW.id,
    jsonb_build_object(
      'invoice_id', NEW.invoice_id,
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
      'paid_amount', NEW.paid_amount,
      'balance_due', NEW.balance_due,
      'notes', NEW.notes,
      'terms', NEW.terms,
      'status', NEW.status,
      'payment_method', NEW.payment_method,
      'issue_date', NEW.issue_date,
      'due_date', NEW.due_date,
      'paid_date', NEW.paid_date,
      'created_at', NEW.created_at
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS invoice_created_trigger ON invoices;
CREATE TRIGGER invoice_created_trigger
  AFTER INSERT ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION notify_invoice_created();

-- Trigger for invoice updated
CREATE OR REPLACE FUNCTION notify_invoice_updated()
RETURNS TRIGGER AS $$
DECLARE
  event_type text;
BEGIN
  event_type := 'invoice.updated';
  
  IF OLD.status != NEW.status THEN
    IF NEW.status = 'Paid' THEN
      event_type := 'invoice.paid';
    ELSIF NEW.status = 'Overdue' THEN
      event_type := 'invoice.overdue';
    END IF;
  END IF;
  
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    event_type,
    'invoices',
    NEW.id,
    jsonb_build_object(
      'invoice_id', NEW.invoice_id,
      'customer_id', NEW.customer_id,
      'customer_name', NEW.customer_name,
      'customer_email', NEW.customer_email,
      'title', NEW.title,
      'total_amount', NEW.total_amount,
      'paid_amount', NEW.paid_amount,
      'balance_due', NEW.balance_due,
      'status', NEW.status,
      'payment_method', NEW.payment_method,
      'due_date', NEW.due_date,
      'paid_date', NEW.paid_date,
      'updated_at', NEW.updated_at,
      'old_status', OLD.status,
      'old_paid_amount', OLD.paid_amount,
      'old_balance_due', OLD.balance_due
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS invoice_updated_trigger ON invoices;
CREATE TRIGGER invoice_updated_trigger
  AFTER UPDATE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION notify_invoice_updated();

-- Trigger for invoice deleted
CREATE OR REPLACE FUNCTION notify_invoice_deleted()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    'invoice.deleted',
    'invoices',
    OLD.id,
    jsonb_build_object(
      'invoice_id', OLD.invoice_id,
      'customer_name', OLD.customer_name,
      'customer_email', OLD.customer_email,
      'title', OLD.title,
      'total_amount', OLD.total_amount,
      'balance_due', OLD.balance_due,
      'status', OLD.status,
      'deleted_at', NOW()
    )
  );
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS invoice_deleted_trigger ON invoices;
CREATE TRIGGER invoice_deleted_trigger
  AFTER DELETE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION notify_invoice_deleted();

COMMENT ON FUNCTION notify_invoice_created() IS 'Sends webhook notification when invoice is created';
COMMENT ON FUNCTION notify_invoice_updated() IS 'Sends webhook notification when invoice is updated, including special events for paid and overdue';
COMMENT ON FUNCTION notify_invoice_deleted() IS 'Sends webhook notification when invoice is deleted';
