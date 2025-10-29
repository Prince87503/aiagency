/*
  # Fix lead triggers to use correct api_webhooks column names

  1. Changes
    - Update lead triggers to use webhook_url instead of url
    - Remove references to headers and secret which don't exist

  2. Notes
    - Fixes compatibility with current api_webhooks table schema
*/

-- Drop existing lead triggers
DROP TRIGGER IF EXISTS lead_insert_trigger ON leads;
DROP TRIGGER IF EXISTS lead_update_trigger ON leads;
DROP TRIGGER IF EXISTS lead_delete_trigger ON leads;

-- Drop existing trigger functions
DROP FUNCTION IF EXISTS notify_lead_insert();
DROP FUNCTION IF EXISTS notify_lead_update();
DROP FUNCTION IF EXISTS notify_lead_delete();

-- Recreate lead insert trigger function
CREATE OR REPLACE FUNCTION notify_lead_insert()
RETURNS TRIGGER AS $$
DECLARE
  trigger_data jsonb;
  api_webhook_record RECORD;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'lead.created',
    'id', NEW.id,
    'lead_id', NEW.lead_id,
    'name', NEW.name,
    'email', NEW.email,
    'phone', NEW.phone,
    'source', NEW.source,
    'interest', NEW.interest,
    'stage', NEW.stage,
    'owner', NEW.owner,
    'address', NEW.address,
    'company', NEW.company,
    'notes', NEW.notes,
    'last_contact', NEW.last_contact,
    'lead_score', NEW.lead_score,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at,
    'affiliate_id', NEW.affiliate_id,
    'pipeline_id', NEW.pipeline_id
  );

  FOR api_webhook_record IN
    SELECT webhook_url
    FROM api_webhooks
    WHERE is_active = true
      AND trigger_event = 'lead.created'
  LOOP
    INSERT INTO webhooks (event, payload, url)
    VALUES ('lead.created', trigger_data, api_webhook_record.webhook_url);
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate lead update trigger function
CREATE OR REPLACE FUNCTION notify_lead_update()
RETURNS TRIGGER AS $$
DECLARE
  trigger_data jsonb;
  api_webhook_record RECORD;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'lead.updated',
    'id', NEW.id,
    'lead_id', NEW.lead_id,
    'name', NEW.name,
    'email', NEW.email,
    'phone', NEW.phone,
    'source', NEW.source,
    'interest', NEW.interest,
    'stage', NEW.stage,
    'owner', NEW.owner,
    'address', NEW.address,
    'company', NEW.company,
    'notes', NEW.notes,
    'last_contact', NEW.last_contact,
    'lead_score', NEW.lead_score,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at,
    'affiliate_id', NEW.affiliate_id,
    'pipeline_id', NEW.pipeline_id,
    'previous', jsonb_build_object(
      'stage', OLD.stage,
      'interest', OLD.interest,
      'owner', OLD.owner,
      'notes', OLD.notes,
      'last_contact', OLD.last_contact,
      'lead_score', OLD.lead_score,
      'pipeline_id', OLD.pipeline_id
    )
  );

  FOR api_webhook_record IN
    SELECT webhook_url
    FROM api_webhooks
    WHERE is_active = true
      AND trigger_event = 'lead.updated'
  LOOP
    INSERT INTO webhooks (event, payload, url)
    VALUES ('lead.updated', trigger_data, api_webhook_record.webhook_url);
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate lead delete trigger function
CREATE OR REPLACE FUNCTION notify_lead_delete()
RETURNS TRIGGER AS $$
DECLARE
  trigger_data jsonb;
  api_webhook_record RECORD;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'lead.deleted',
    'id', OLD.id,
    'lead_id', OLD.lead_id,
    'name', OLD.name,
    'email', OLD.email,
    'phone', OLD.phone,
    'source', OLD.source,
    'interest', OLD.interest,
    'stage', OLD.stage,
    'owner', OLD.owner,
    'address', OLD.address,
    'company', OLD.company,
    'notes', OLD.notes,
    'last_contact', OLD.last_contact,
    'lead_score', OLD.lead_score,
    'created_at', OLD.created_at,
    'updated_at', OLD.updated_at,
    'affiliate_id', OLD.affiliate_id,
    'pipeline_id', OLD.pipeline_id
  );

  FOR api_webhook_record IN
    SELECT webhook_url
    FROM api_webhooks
    WHERE is_active = true
      AND trigger_event = 'lead.deleted'
  LOOP
    INSERT INTO webhooks (event, payload, url)
    VALUES ('lead.deleted', trigger_data, api_webhook_record.webhook_url);
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Recreate triggers
CREATE TRIGGER lead_insert_trigger
  AFTER INSERT ON leads
  FOR EACH ROW
  EXECUTE FUNCTION notify_lead_insert();

CREATE TRIGGER lead_update_trigger
  AFTER UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION notify_lead_update();

CREATE TRIGGER lead_delete_trigger
  AFTER DELETE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION notify_lead_delete();
