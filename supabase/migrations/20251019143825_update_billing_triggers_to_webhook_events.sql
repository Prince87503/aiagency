/*
  # Update Billing Triggers to Use API Webhooks Pattern

  Updates all estimate, invoice, subscription, and receipt triggers to follow
  the same pattern as other modules (leads, affiliates, etc.) by sending HTTP
  POST requests to configured webhooks in the api_webhooks table.
*/

-- Update Estimate Triggers
CREATE OR REPLACE FUNCTION notify_estimate_created()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'ESTIMATE_CREATED',
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
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_estimate_updated()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'ESTIMATE_UPDATED',
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
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_estimate_deleted()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'ESTIMATE_DELETED',
    'estimate_id', OLD.estimate_id,
    'customer_name', OLD.customer_name,
    'customer_email', OLD.customer_email,
    'title', OLD.title,
    'total_amount', OLD.total_amount,
    'status', OLD.status,
    'deleted_at', NOW()
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
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update Invoice Triggers
CREATE OR REPLACE FUNCTION notify_invoice_created()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'INVOICE_CREATED',
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
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_invoice_updated()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'INVOICE_UPDATED',
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
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'INVOICE_UPDATED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;

      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_invoice_deleted()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'INVOICE_DELETED',
    'invoice_id', OLD.invoice_id,
    'customer_name', OLD.customer_name,
    'customer_email', OLD.customer_email,
    'title', OLD.title,
    'total_amount', OLD.total_amount,
    'balance_due', OLD.balance_due,
    'status', OLD.status,
    'deleted_at', NOW()
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
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update Subscription Triggers
CREATE OR REPLACE FUNCTION notify_subscription_created()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'SUBSCRIPTION_CREATED',
    'subscription_id', NEW.subscription_id,
    'customer_id', NEW.customer_id,
    'customer_name', NEW.customer_name,
    'customer_email', NEW.customer_email,
    'customer_phone', NEW.customer_phone,
    'plan_name', NEW.plan_name,
    'plan_type', NEW.plan_type,
    'amount', NEW.amount,
    'currency', NEW.currency,
    'billing_cycle_day', NEW.billing_cycle_day,
    'status', NEW.status,
    'payment_method', NEW.payment_method,
    'start_date', NEW.start_date,
    'end_date', NEW.end_date,
    'next_billing_date', NEW.next_billing_date,
    'last_billing_date', NEW.last_billing_date,
    'auto_renew', NEW.auto_renew,
    'notes', NEW.notes,
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
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_subscription_updated()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'SUBSCRIPTION_UPDATED',
    'subscription_id', NEW.subscription_id,
    'customer_id', NEW.customer_id,
    'customer_name', NEW.customer_name,
    'customer_email', NEW.customer_email,
    'plan_name', NEW.plan_name,
    'plan_type', NEW.plan_type,
    'amount', NEW.amount,
    'status', NEW.status,
    'payment_method', NEW.payment_method,
    'next_billing_date', NEW.next_billing_date,
    'last_billing_date', NEW.last_billing_date,
    'auto_renew', NEW.auto_renew,
    'updated_at', NEW.updated_at,
    'cancelled_at', NEW.cancelled_at,
    'cancelled_reason', NEW.cancelled_reason,
    'old_status', OLD.status,
    'old_next_billing_date', OLD.next_billing_date,
    'old_last_billing_date', OLD.last_billing_date
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'SUBSCRIPTION_UPDATED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;

      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_subscription_deleted()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'SUBSCRIPTION_DELETED',
    'subscription_id', OLD.subscription_id,
    'customer_name', OLD.customer_name,
    'customer_email', OLD.customer_email,
    'plan_name', OLD.plan_name,
    'amount', OLD.amount,
    'status', OLD.status,
    'deleted_at', NOW()
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
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update Receipt Triggers
CREATE OR REPLACE FUNCTION notify_receipt_created()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'RECEIPT_CREATED',
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
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_receipt_updated()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'RECEIPT_UPDATED',
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
  );

  FOR api_webhook_record IN
    SELECT * FROM api_webhooks
    WHERE trigger_event = 'RECEIPT_UPDATED' AND is_active = true
  LOOP
    BEGIN
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := trigger_data
      ) INTO request_id;

      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_receipt_deleted()
RETURNS TRIGGER AS $$
DECLARE
  api_webhook_record RECORD;
  trigger_data jsonb;
  request_id bigint;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'RECEIPT_DELETED',
    'receipt_id', OLD.receipt_id,
    'customer_name', OLD.customer_name,
    'customer_email', OLD.customer_email,
    'amount_paid', OLD.amount_paid,
    'payment_date', OLD.payment_date,
    'status', OLD.status,
    'deleted_at', NOW()
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
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

    EXCEPTION WHEN OTHERS THEN
      UPDATE api_webhooks
      SET
        total_calls = COALESCE(total_calls, 0) + 1,
        failure_count = COALESCE(failure_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;

      RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments
COMMENT ON FUNCTION notify_estimate_created() IS 'Sends HTTP POST to configured API webhooks when an estimate is created';
COMMENT ON FUNCTION notify_estimate_updated() IS 'Sends HTTP POST to configured API webhooks when an estimate is updated';
COMMENT ON FUNCTION notify_estimate_deleted() IS 'Sends HTTP POST to configured API webhooks when an estimate is deleted';
COMMENT ON FUNCTION notify_invoice_created() IS 'Sends HTTP POST to configured API webhooks when an invoice is created';
COMMENT ON FUNCTION notify_invoice_updated() IS 'Sends HTTP POST to configured API webhooks when an invoice is updated';
COMMENT ON FUNCTION notify_invoice_deleted() IS 'Sends HTTP POST to configured API webhooks when an invoice is deleted';
COMMENT ON FUNCTION notify_subscription_created() IS 'Sends HTTP POST to configured API webhooks when a subscription is created';
COMMENT ON FUNCTION notify_subscription_updated() IS 'Sends HTTP POST to configured API webhooks when a subscription is updated';
COMMENT ON FUNCTION notify_subscription_deleted() IS 'Sends HTTP POST to configured API webhooks when a subscription is deleted';
COMMENT ON FUNCTION notify_receipt_created() IS 'Sends HTTP POST to configured API webhooks when a receipt is created';
COMMENT ON FUNCTION notify_receipt_updated() IS 'Sends HTTP POST to configured API webhooks when a receipt is updated';
COMMENT ON FUNCTION notify_receipt_deleted() IS 'Sends HTTP POST to configured API webhooks when a receipt is deleted';
