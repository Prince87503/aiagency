/*
  # Create Subscription Triggers for API Webhooks
  
  1. Triggers
    - Subscription Created: Fires when a new subscription is inserted
    - Subscription Updated: Fires when a subscription is updated
    - Subscription Deleted: Fires when a subscription is deleted
    
  2. Webhook Events
    - subscription.created
    - subscription.updated
    - subscription.cancelled (special event when status changes to 'Cancelled')
    - subscription.renewed (special event when next_billing_date is updated and status is Active)
    - subscription.paused (special event when status changes to 'Paused')
    - subscription.expired (special event when status changes to 'Expired')
    - subscription.deleted
    
  3. Payload Structure
    - trigger_event: The event type
    - table_name: 'subscriptions'
    - record_id: The subscription UUID
    - subscription_id: Human-readable subscription ID
    - data: The subscription record data
    - old_data: Previous data (for updates/deletes)
*/

-- Trigger for subscription created
CREATE OR REPLACE FUNCTION notify_subscription_created()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    'subscription.created',
    'subscriptions',
    NEW.id,
    jsonb_build_object(
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
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS subscription_created_trigger ON subscriptions;
CREATE TRIGGER subscription_created_trigger
  AFTER INSERT ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION notify_subscription_created();

-- Trigger for subscription updated
CREATE OR REPLACE FUNCTION notify_subscription_updated()
RETURNS TRIGGER AS $$
DECLARE
  event_type text;
BEGIN
  event_type := 'subscription.updated';
  
  IF OLD.status != NEW.status THEN
    IF NEW.status = 'Cancelled' THEN
      event_type := 'subscription.cancelled';
    ELSIF NEW.status = 'Paused' THEN
      event_type := 'subscription.paused';
    ELSIF NEW.status = 'Expired' THEN
      event_type := 'subscription.expired';
    END IF;
  ELSIF OLD.last_billing_date != NEW.last_billing_date AND NEW.status = 'Active' THEN
    event_type := 'subscription.renewed';
  END IF;
  
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    event_type,
    'subscriptions',
    NEW.id,
    jsonb_build_object(
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
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS subscription_updated_trigger ON subscriptions;
CREATE TRIGGER subscription_updated_trigger
  AFTER UPDATE ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION notify_subscription_updated();

-- Trigger for subscription deleted
CREATE OR REPLACE FUNCTION notify_subscription_deleted()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api_webhooks (
    trigger_event,
    table_name,
    record_id,
    data
  ) VALUES (
    'subscription.deleted',
    'subscriptions',
    OLD.id,
    jsonb_build_object(
      'subscription_id', OLD.subscription_id,
      'customer_name', OLD.customer_name,
      'customer_email', OLD.customer_email,
      'plan_name', OLD.plan_name,
      'amount', OLD.amount,
      'status', OLD.status,
      'deleted_at', NOW()
    )
  );
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS subscription_deleted_trigger ON subscriptions;
CREATE TRIGGER subscription_deleted_trigger
  AFTER DELETE ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION notify_subscription_deleted();

COMMENT ON FUNCTION notify_subscription_created() IS 'Sends webhook notification when subscription is created';
COMMENT ON FUNCTION notify_subscription_updated() IS 'Sends webhook notification when subscription is updated, including special events for status changes and renewals';
COMMENT ON FUNCTION notify_subscription_deleted() IS 'Sends webhook notification when subscription is deleted';
