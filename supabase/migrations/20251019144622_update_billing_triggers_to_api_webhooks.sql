/*
  # Update Billing Triggers to Use api_webhooks Table (Same as Other Modules)
  
  1. Changes
    - Drop webhook_events table (not needed)
    - Update all billing triggers to use api_webhooks table
    - Send HTTP POST requests to configured webhook URLs
    - Track success/failure statistics
    - Follow the same pattern as leads, affiliates, and other modules
    
  2. Trigger Events
    - ESTIMATE_CREATED, ESTIMATE_UPDATED, ESTIMATE_DELETED
    - INVOICE_CREATED, INVOICE_UPDATED, INVOICE_DELETED, INVOICE_PAID, INVOICE_OVERDUE
    - SUBSCRIPTION_CREATED, SUBSCRIPTION_UPDATED, SUBSCRIPTION_DELETED, SUBSCRIPTION_CANCELLED, SUBSCRIPTION_RENEWED
    - RECEIPT_CREATED, RECEIPT_UPDATED, RECEIPT_DELETED, RECEIPT_REFUNDED
*/

-- Drop webhook_events table (not needed)
DROP TABLE IF EXISTS webhook_events CASCADE;

-- ESTIMATE TRIGGERS
CREATE OR REPLACE FUNCTION trigger_webhooks_on_estimate_create()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'ESTIMATE_CREATED',
    'id', NEW.id,
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
    'updated_at', NEW.updated_at
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'ESTIMATE_CREATED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION trigger_webhooks_on_estimate_update()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'ESTIMATE_UPDATED',
    'id', NEW.id,
    'estimate_id', NEW.estimate_id,
    'customer_name', NEW.customer_name,
    'customer_email', NEW.customer_email,
    'title', NEW.title,
    'total_amount', NEW.total_amount,
    'status', NEW.status,
    'updated_at', NEW.updated_at,
    'previous', jsonb_build_object(
      'status', OLD.status,
      'total_amount', OLD.total_amount
    )
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'ESTIMATE_UPDATED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION trigger_webhooks_on_estimate_delete()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'ESTIMATE_DELETED',
    'id', OLD.id,
    'estimate_id', OLD.estimate_id,
    'customer_name', OLD.customer_name,
    'customer_email', OLD.customer_email,
    'title', OLD.title,
    'total_amount', OLD.total_amount,
    'status', OLD.status,
    'deleted_at', now()
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'ESTIMATE_DELETED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- INVOICE TRIGGERS
CREATE OR REPLACE FUNCTION trigger_webhooks_on_invoice_create()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'INVOICE_CREATED',
    'id', NEW.id,
    'invoice_id', NEW.invoice_id,
    'customer_name', NEW.customer_name,
    'customer_email', NEW.customer_email,
    'title', NEW.title,
    'total_amount', NEW.total_amount,
    'balance_due', NEW.balance_due,
    'status', NEW.status,
    'issue_date', NEW.issue_date,
    'due_date', NEW.due_date,
    'created_at', NEW.created_at
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'INVOICE_CREATED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION trigger_webhooks_on_invoice_update()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
  event_name text;
BEGIN
  event_name := 'INVOICE_UPDATED';
  
  IF OLD.status != NEW.status THEN
    IF NEW.status = 'Paid' THEN
      event_name := 'INVOICE_PAID';
    ELSIF NEW.status = 'Overdue' THEN
      event_name := 'INVOICE_OVERDUE';
    END IF;
  END IF;

  trigger_data := jsonb_build_object(
    'trigger_event', event_name,
    'id', NEW.id,
    'invoice_id', NEW.invoice_id,
    'customer_name', NEW.customer_name,
    'customer_email', NEW.customer_email,
    'title', NEW.title,
    'total_amount', NEW.total_amount,
    'paid_amount', NEW.paid_amount,
    'balance_due', NEW.balance_due,
    'status', NEW.status,
    'updated_at', NEW.updated_at,
    'previous', jsonb_build_object(
      'status', OLD.status,
      'paid_amount', OLD.paid_amount,
      'balance_due', OLD.balance_due
    )
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event IN ('INVOICE_UPDATED', event_name) AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION trigger_webhooks_on_invoice_delete()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'INVOICE_DELETED',
    'id', OLD.id,
    'invoice_id', OLD.invoice_id,
    'customer_name', OLD.customer_name,
    'customer_email', OLD.customer_email,
    'title', OLD.title,
    'total_amount', OLD.total_amount,
    'status', OLD.status,
    'deleted_at', now()
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'INVOICE_DELETED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- SUBSCRIPTION TRIGGERS
CREATE OR REPLACE FUNCTION trigger_webhooks_on_subscription_create()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'SUBSCRIPTION_CREATED',
    'id', NEW.id,
    'subscription_id', NEW.subscription_id,
    'customer_name', NEW.customer_name,
    'customer_email', NEW.customer_email,
    'plan_name', NEW.plan_name,
    'plan_type', NEW.plan_type,
    'amount', NEW.amount,
    'status', NEW.status,
    'start_date', NEW.start_date,
    'next_billing_date', NEW.next_billing_date,
    'created_at', NEW.created_at
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'SUBSCRIPTION_CREATED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION trigger_webhooks_on_subscription_update()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
  event_name text;
BEGIN
  event_name := 'SUBSCRIPTION_UPDATED';
  
  IF OLD.status != NEW.status THEN
    IF NEW.status = 'Cancelled' THEN
      event_name := 'SUBSCRIPTION_CANCELLED';
    ELSIF NEW.status = 'Paused' THEN
      event_name := 'SUBSCRIPTION_PAUSED';
    ELSIF NEW.status = 'Expired' THEN
      event_name := 'SUBSCRIPTION_EXPIRED';
    END IF;
  ELSIF OLD.last_billing_date != NEW.last_billing_date AND NEW.status = 'Active' THEN
    event_name := 'SUBSCRIPTION_RENEWED';
  END IF;

  trigger_data := jsonb_build_object(
    'trigger_event', event_name,
    'id', NEW.id,
    'subscription_id', NEW.subscription_id,
    'customer_name', NEW.customer_name,
    'customer_email', NEW.customer_email,
    'plan_name', NEW.plan_name,
    'amount', NEW.amount,
    'status', NEW.status,
    'next_billing_date', NEW.next_billing_date,
    'updated_at', NEW.updated_at,
    'previous', jsonb_build_object(
      'status', OLD.status,
      'next_billing_date', OLD.next_billing_date
    )
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event IN ('SUBSCRIPTION_UPDATED', event_name) AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION trigger_webhooks_on_subscription_delete()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'SUBSCRIPTION_DELETED',
    'id', OLD.id,
    'subscription_id', OLD.subscription_id,
    'customer_name', OLD.customer_name,
    'customer_email', OLD.customer_email,
    'plan_name', OLD.plan_name,
    'amount', OLD.amount,
    'status', OLD.status,
    'deleted_at', now()
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'SUBSCRIPTION_DELETED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RECEIPT TRIGGERS
CREATE OR REPLACE FUNCTION trigger_webhooks_on_receipt_create()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'RECEIPT_CREATED',
    'id', NEW.id,
    'receipt_id', NEW.receipt_id,
    'customer_name', NEW.customer_name,
    'customer_email', NEW.customer_email,
    'payment_method', NEW.payment_method,
    'payment_reference', NEW.payment_reference,
    'amount_paid', NEW.amount_paid,
    'payment_date', NEW.payment_date,
    'status', NEW.status,
    'created_at', NEW.created_at
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'RECEIPT_CREATED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION trigger_webhooks_on_receipt_update()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
  event_name text;
BEGIN
  event_name := 'RECEIPT_UPDATED';
  
  IF OLD.status != NEW.status THEN
    IF NEW.status = 'Refunded' THEN
      event_name := 'RECEIPT_REFUNDED';
    ELSIF NEW.status = 'Failed' THEN
      event_name := 'RECEIPT_FAILED';
    END IF;
  END IF;

  trigger_data := jsonb_build_object(
    'trigger_event', event_name,
    'id', NEW.id,
    'receipt_id', NEW.receipt_id,
    'customer_name', NEW.customer_name,
    'customer_email', NEW.customer_email,
    'amount_paid', NEW.amount_paid,
    'status', NEW.status,
    'refund_amount', NEW.refund_amount,
    'updated_at', NEW.updated_at,
    'previous', jsonb_build_object(
      'status', OLD.status
    )
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event IN ('RECEIPT_UPDATED', event_name) AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION trigger_webhooks_on_receipt_delete()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'RECEIPT_DELETED',
    'id', OLD.id,
    'receipt_id', OLD.receipt_id,
    'customer_name', OLD.customer_name,
    'customer_email', OLD.customer_email,
    'amount_paid', OLD.amount_paid,
    'status', OLD.status,
    'deleted_at', now()
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'RECEIPT_DELETED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;
      
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          success_count = COALESCE(success_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
      WHERE id = api_webhook_record.id;
    END;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update trigger definitions
DROP TRIGGER IF EXISTS estimate_created_trigger ON estimates;
CREATE TRIGGER estimate_created_trigger
  AFTER INSERT ON estimates
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_estimate_create();

DROP TRIGGER IF EXISTS estimate_updated_trigger ON estimates;
CREATE TRIGGER estimate_updated_trigger
  AFTER UPDATE ON estimates
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_estimate_update();

DROP TRIGGER IF EXISTS estimate_deleted_trigger ON estimates;
CREATE TRIGGER estimate_deleted_trigger
  AFTER DELETE ON estimates
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_estimate_delete();

DROP TRIGGER IF EXISTS invoice_created_trigger ON invoices;
CREATE TRIGGER invoice_created_trigger
  AFTER INSERT ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_invoice_create();

DROP TRIGGER IF EXISTS invoice_updated_trigger ON invoices;
CREATE TRIGGER invoice_updated_trigger
  AFTER UPDATE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_invoice_update();

DROP TRIGGER IF EXISTS invoice_deleted_trigger ON invoices;
CREATE TRIGGER invoice_deleted_trigger
  AFTER DELETE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_invoice_delete();

DROP TRIGGER IF EXISTS subscription_created_trigger ON subscriptions;
CREATE TRIGGER subscription_created_trigger
  AFTER INSERT ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_subscription_create();

DROP TRIGGER IF EXISTS subscription_updated_trigger ON subscriptions;
CREATE TRIGGER subscription_updated_trigger
  AFTER UPDATE ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_subscription_update();

DROP TRIGGER IF EXISTS subscription_deleted_trigger ON subscriptions;
CREATE TRIGGER subscription_deleted_trigger
  AFTER DELETE ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_subscription_delete();

DROP TRIGGER IF EXISTS receipt_created_trigger ON receipts;
CREATE TRIGGER receipt_created_trigger
  AFTER INSERT ON receipts
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_receipt_create();

DROP TRIGGER IF EXISTS receipt_updated_trigger ON receipts;
CREATE TRIGGER receipt_updated_trigger
  AFTER UPDATE ON receipts
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_receipt_update();

DROP TRIGGER IF EXISTS receipt_deleted_trigger ON receipts;
CREATE TRIGGER receipt_deleted_trigger
  AFTER DELETE ON receipts
  FOR EACH ROW
  EXECUTE FUNCTION trigger_webhooks_on_receipt_delete();

-- Add comments
COMMENT ON FUNCTION trigger_webhooks_on_estimate_create() IS 'Sends HTTP POST to configured API webhooks when estimate is created';
COMMENT ON FUNCTION trigger_webhooks_on_estimate_update() IS 'Sends HTTP POST to configured API webhooks when estimate is updated';
COMMENT ON FUNCTION trigger_webhooks_on_estimate_delete() IS 'Sends HTTP POST to configured API webhooks when estimate is deleted';

COMMENT ON FUNCTION trigger_webhooks_on_invoice_create() IS 'Sends HTTP POST to configured API webhooks when invoice is created';
COMMENT ON FUNCTION trigger_webhooks_on_invoice_update() IS 'Sends HTTP POST to configured API webhooks when invoice is updated';
COMMENT ON FUNCTION trigger_webhooks_on_invoice_delete() IS 'Sends HTTP POST to configured API webhooks when invoice is deleted';

COMMENT ON FUNCTION trigger_webhooks_on_subscription_create() IS 'Sends HTTP POST to configured API webhooks when subscription is created';
COMMENT ON FUNCTION trigger_webhooks_on_subscription_update() IS 'Sends HTTP POST to configured API webhooks when subscription is updated';
COMMENT ON FUNCTION trigger_webhooks_on_subscription_delete() IS 'Sends HTTP POST to configured API webhooks when subscription is deleted';

COMMENT ON FUNCTION trigger_webhooks_on_receipt_create() IS 'Sends HTTP POST to configured API webhooks when receipt is created';
COMMENT ON FUNCTION trigger_webhooks_on_receipt_update() IS 'Sends HTTP POST to configured API webhooks when receipt is updated';
COMMENT ON FUNCTION trigger_webhooks_on_receipt_delete() IS 'Sends HTTP POST to configured API webhooks when receipt is deleted';
