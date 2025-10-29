/*
  # Fix workflow triggers to use stage instead of status

  1. Changes
    - Update workflow trigger functions to reference stage column instead of status
    - This fixes the LEAD_UPDATED and LEAD_DELETED workflow triggers

  2. Notes
    - Required after renaming status to stage in leads table
*/

-- Drop existing workflow triggers for leads
DROP TRIGGER IF EXISTS trigger_workflows_on_lead_insert ON leads;
DROP TRIGGER IF EXISTS trigger_workflows_on_lead_update ON leads;
DROP TRIGGER IF EXISTS trigger_workflows_on_lead_delete ON leads;
DROP TRIGGER IF EXISTS trigger_workflows_on_new_lead ON leads;
DROP TRIGGER IF EXISTS trigger_workflows_on_updated_lead ON leads;
DROP TRIGGER IF EXISTS trigger_workflows_on_deleted_lead ON leads;

-- Drop existing workflow trigger functions with CASCADE
DROP FUNCTION IF EXISTS trigger_workflows_on_lead_insert() CASCADE;
DROP FUNCTION IF EXISTS trigger_workflows_on_lead_update() CASCADE;
DROP FUNCTION IF EXISTS trigger_workflows_on_lead_delete() CASCADE;

-- Recreate workflow trigger function for lead insert
CREATE OR REPLACE FUNCTION trigger_workflows_on_lead_insert()
RETURNS TRIGGER AS $$
DECLARE
  trigger_data jsonb;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'LEAD_CREATED',
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

  INSERT INTO workflow_executions (trigger_type, trigger_data)
  VALUES ('LEAD_CREATED', trigger_data);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate workflow trigger function for lead update
CREATE OR REPLACE FUNCTION trigger_workflows_on_lead_update()
RETURNS TRIGGER AS $$
DECLARE
  trigger_data jsonb;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'LEAD_UPDATED',
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

  INSERT INTO workflow_executions (trigger_type, trigger_data)
  VALUES ('LEAD_UPDATED', trigger_data);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate workflow trigger function for lead delete
CREATE OR REPLACE FUNCTION trigger_workflows_on_lead_delete()
RETURNS TRIGGER AS $$
DECLARE
  trigger_data jsonb;
BEGIN
  trigger_data := jsonb_build_object(
    'trigger_event', 'LEAD_DELETED',
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

  INSERT INTO workflow_executions (trigger_type, trigger_data)
  VALUES ('LEAD_DELETED', trigger_data);

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Recreate triggers
CREATE TRIGGER trigger_workflows_on_lead_insert
  AFTER INSERT ON leads
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_lead_insert();

CREATE TRIGGER trigger_workflows_on_lead_update
  AFTER UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_lead_update();

CREATE TRIGGER trigger_workflows_on_lead_delete
  AFTER DELETE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_lead_delete();
