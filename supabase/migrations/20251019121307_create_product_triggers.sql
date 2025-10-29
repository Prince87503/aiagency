/*
  # Create Product Trigger Events

  1. Changes
    - Create database trigger functions for product operations
    - Add triggers on products table for INSERT, UPDATE, and DELETE operations
    - When a product is added/updated/deleted, check for active API webhooks
    - Send notification to configured webhook URLs
    - Track webhook statistics (total_calls, success_count, failure_count)

  2. New Trigger Events
    - PRODUCT_ADDED: Triggers when a new product is created
    - PRODUCT_UPDATED: Triggers when a product is updated
    - PRODUCT_DELETED: Triggers when a product is deleted

  3. Functionality
    - Triggers both API webhooks and workflow automations based on product operations
    - Passes all product data to webhooks and workflows
    - For updates, includes both NEW and previous values
    - For deletes, includes the deleted product data with deleted_at timestamp
    - Supports multiple webhooks being triggered by the same event
    - Includes 'trigger_event' field in payload for easy event identification

  4. Security
    - Uses existing RLS policies on api_webhooks and workflow_executions tables
    - SECURITY DEFINER ensures triggers have permission to update statistics
*/

-- Create function to trigger workflows when a new product is added
CREATE OR REPLACE FUNCTION trigger_workflows_on_product_add()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  api_webhook_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  trigger_data jsonb;
  request_id bigint;
  webhook_success boolean;
BEGIN
  -- Build trigger data with trigger_event
  trigger_data := jsonb_build_object(
    'trigger_event', 'PRODUCT_ADDED',
    'id', NEW.id,
    'product_id', NEW.product_id,
    'product_name', NEW.product_name,
    'product_type', NEW.product_type,
    'description', NEW.description,
    'pricing_model', NEW.pricing_model,
    'course_price', NEW.course_price,
    'onboarding_fee', NEW.onboarding_fee,
    'retainer_fee', NEW.retainer_fee,
    'currency', NEW.currency,
    'features', NEW.features,
    'duration', NEW.duration,
    'is_active', NEW.is_active,
    'category', NEW.category,
    'thumbnail_url', NEW.thumbnail_url,
    'sales_page_url', NEW.sales_page_url,
    'total_sales', NEW.total_sales,
    'total_revenue', NEW.total_revenue,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'PRODUCT_ADDED'
      AND is_active = true
  LOOP
    BEGIN
      webhook_success := false;
      
      -- Make HTTP POST request using pg_net
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json'
        ),
        body := trigger_data
      ) INTO request_id;
      
      webhook_success := true;
      
      -- Update success statistics
      UPDATE api_webhooks
      SET 
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;
      
    EXCEPTION
      WHEN OTHERS THEN
        -- Update failure statistics
        UPDATE api_webhooks
        SET 
          total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
        WHERE id = api_webhook_record.id;
        
        RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  -- Process Workflow Automations
  FOR automation_record IN
    SELECT 
      a.id,
      a.workflow_nodes
    FROM automations a
    WHERE a.status = 'Active'
      AND a.workflow_nodes IS NOT NULL
      AND jsonb_array_length(a.workflow_nodes) > 0
  LOOP
    -- Get the first node (trigger node)
    trigger_node := automation_record.workflow_nodes->0;
    
    -- Check if this is a PRODUCT_ADDED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'PRODUCT_ADDED' THEN
      
      -- Create a workflow execution record
      INSERT INTO workflow_executions (
        automation_id,
        trigger_type,
        trigger_data,
        status,
        total_steps,
        started_at
      ) VALUES (
        automation_record.id,
        'PRODUCT_ADDED',
        trigger_data,
        'pending',
        jsonb_array_length(automation_record.workflow_nodes) - 1,
        now()
      ) RETURNING id INTO execution_id;

      -- Signal that a workflow needs to be executed
      PERFORM pg_notify(
        'workflow_execution',
        json_build_object(
          'execution_id', execution_id,
          'automation_id', automation_record.id,
          'trigger_type', 'PRODUCT_ADDED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to trigger workflows when a product is updated
CREATE OR REPLACE FUNCTION trigger_workflows_on_product_update()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  api_webhook_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  trigger_data jsonb;
  request_id bigint;
  webhook_success boolean;
BEGIN
  -- Build trigger data with trigger_event and previous values
  trigger_data := jsonb_build_object(
    'trigger_event', 'PRODUCT_UPDATED',
    'id', NEW.id,
    'product_id', NEW.product_id,
    'product_name', NEW.product_name,
    'product_type', NEW.product_type,
    'description', NEW.description,
    'pricing_model', NEW.pricing_model,
    'course_price', NEW.course_price,
    'onboarding_fee', NEW.onboarding_fee,
    'retainer_fee', NEW.retainer_fee,
    'currency', NEW.currency,
    'features', NEW.features,
    'duration', NEW.duration,
    'is_active', NEW.is_active,
    'category', NEW.category,
    'thumbnail_url', NEW.thumbnail_url,
    'sales_page_url', NEW.sales_page_url,
    'total_sales', NEW.total_sales,
    'total_revenue', NEW.total_revenue,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at,
    'previous', jsonb_build_object(
      'product_name', OLD.product_name,
      'product_type', OLD.product_type,
      'pricing_model', OLD.pricing_model,
      'course_price', OLD.course_price,
      'onboarding_fee', OLD.onboarding_fee,
      'retainer_fee', OLD.retainer_fee,
      'is_active', OLD.is_active,
      'category', OLD.category
    )
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'PRODUCT_UPDATED'
      AND is_active = true
  LOOP
    BEGIN
      webhook_success := false;
      
      -- Make HTTP POST request using pg_net
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json'
        ),
        body := trigger_data
      ) INTO request_id;
      
      webhook_success := true;
      
      -- Update success statistics
      UPDATE api_webhooks
      SET 
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;
      
    EXCEPTION
      WHEN OTHERS THEN
        -- Update failure statistics
        UPDATE api_webhooks
        SET 
          total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
        WHERE id = api_webhook_record.id;
        
        RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  -- Process Workflow Automations
  FOR automation_record IN
    SELECT 
      a.id,
      a.workflow_nodes
    FROM automations a
    WHERE a.status = 'Active'
      AND a.workflow_nodes IS NOT NULL
      AND jsonb_array_length(a.workflow_nodes) > 0
  LOOP
    -- Get the first node (trigger node)
    trigger_node := automation_record.workflow_nodes->0;
    
    -- Check if this is a PRODUCT_UPDATED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'PRODUCT_UPDATED' THEN
      
      -- Create a workflow execution record
      INSERT INTO workflow_executions (
        automation_id,
        trigger_type,
        trigger_data,
        status,
        total_steps,
        started_at
      ) VALUES (
        automation_record.id,
        'PRODUCT_UPDATED',
        trigger_data,
        'pending',
        jsonb_array_length(automation_record.workflow_nodes) - 1,
        now()
      ) RETURNING id INTO execution_id;

      -- Signal that a workflow needs to be executed
      PERFORM pg_notify(
        'workflow_execution',
        json_build_object(
          'execution_id', execution_id,
          'automation_id', automation_record.id,
          'trigger_type', 'PRODUCT_UPDATED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to trigger workflows when a product is deleted
CREATE OR REPLACE FUNCTION trigger_workflows_on_product_delete()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  api_webhook_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  trigger_data jsonb;
  request_id bigint;
  webhook_success boolean;
BEGIN
  -- Build trigger data with trigger_event
  trigger_data := jsonb_build_object(
    'trigger_event', 'PRODUCT_DELETED',
    'id', OLD.id,
    'product_id', OLD.product_id,
    'product_name', OLD.product_name,
    'product_type', OLD.product_type,
    'description', OLD.description,
    'pricing_model', OLD.pricing_model,
    'course_price', OLD.course_price,
    'onboarding_fee', OLD.onboarding_fee,
    'retainer_fee', OLD.retainer_fee,
    'currency', OLD.currency,
    'features', OLD.features,
    'duration', OLD.duration,
    'is_active', OLD.is_active,
    'category', OLD.category,
    'thumbnail_url', OLD.thumbnail_url,
    'sales_page_url', OLD.sales_page_url,
    'total_sales', OLD.total_sales,
    'total_revenue', OLD.total_revenue,
    'created_at', OLD.created_at,
    'updated_at', OLD.updated_at,
    'deleted_at', now()
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'PRODUCT_DELETED'
      AND is_active = true
  LOOP
    BEGIN
      webhook_success := false;
      
      -- Make HTTP POST request using pg_net
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json'
        ),
        body := trigger_data
      ) INTO request_id;
      
      webhook_success := true;
      
      -- Update success statistics
      UPDATE api_webhooks
      SET 
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;
      
    EXCEPTION
      WHEN OTHERS THEN
        -- Update failure statistics
        UPDATE api_webhooks
        SET 
          total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
        WHERE id = api_webhook_record.id;
        
        RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  -- Process Workflow Automations
  FOR automation_record IN
    SELECT 
      a.id,
      a.workflow_nodes
    FROM automations a
    WHERE a.status = 'Active'
      AND a.workflow_nodes IS NOT NULL
      AND jsonb_array_length(a.workflow_nodes) > 0
  LOOP
    -- Get the first node (trigger node)
    trigger_node := automation_record.workflow_nodes->0;
    
    -- Check if this is a PRODUCT_DELETED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'PRODUCT_DELETED' THEN
      
      -- Create a workflow execution record
      INSERT INTO workflow_executions (
        automation_id,
        trigger_type,
        trigger_data,
        status,
        total_steps,
        started_at
      ) VALUES (
        automation_record.id,
        'PRODUCT_DELETED',
        trigger_data,
        'pending',
        jsonb_array_length(automation_record.workflow_nodes) - 1,
        now()
      ) RETURNING id INTO execution_id;

      -- Signal that a workflow needs to be executed
      PERFORM pg_notify(
        'workflow_execution',
        json_build_object(
          'execution_id', execution_id,
          'automation_id', automation_record.id,
          'trigger_type', 'PRODUCT_DELETED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on products table for inserts
DROP TRIGGER IF EXISTS trigger_workflows_on_product_add ON products;
CREATE TRIGGER trigger_workflows_on_product_add
  AFTER INSERT ON products
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_product_add();

-- Create trigger on products table for updates
DROP TRIGGER IF EXISTS trigger_workflows_on_product_update ON products;
CREATE TRIGGER trigger_workflows_on_product_update
  AFTER UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_product_update();

-- Create trigger on products table for deletes
DROP TRIGGER IF EXISTS trigger_workflows_on_product_delete ON products;
CREATE TRIGGER trigger_workflows_on_product_delete
  AFTER DELETE ON products
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_product_delete();

-- Add comments
COMMENT ON FUNCTION trigger_workflows_on_product_add() IS 'Triggers both API webhooks and workflow automations when a new product is added. Includes trigger_event in payload.';
COMMENT ON FUNCTION trigger_workflows_on_product_update() IS 'Triggers both API webhooks and workflow automations when a product is updated. Includes trigger_event in payload.';
COMMENT ON FUNCTION trigger_workflows_on_product_delete() IS 'Triggers both API webhooks and workflow automations when a product is deleted. Includes trigger_event in payload.';