import { createClient } from 'npm:@supabase/supabase-js@2.58.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface WorkflowNode {
  id: string
  type: 'trigger' | 'action'
  name: string
  properties: Record<string, any>
}

interface WebhookConfig {
  webhook_url: string
  query_params: Array<{ key: string; value: string }>
  headers: Array<{ key: string; value: string }>
  body: Array<{ key: string; value: string }>
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { execution_id } = await req.json()

    if (!execution_id) {
      throw new Error('execution_id is required')
    }

    // Get the execution record
    const { data: execution, error: execError } = await supabase
      .from('workflow_executions')
      .select('*')
      .eq('id', execution_id)
      .single()

    if (execError || !execution) {
      throw new Error('Execution not found')
    }

    // Update status to running
    await supabase
      .from('workflow_executions')
      .update({ status: 'running' })
      .eq('id', execution_id)

    // Get the automation/workflow
    const { data: automation, error: autoError } = await supabase
      .from('automations')
      .select('*')
      .eq('id', execution.automation_id)
      .single()

    if (autoError || !automation) {
      throw new Error('Automation not found')
    }

    const nodes: WorkflowNode[] = automation.workflow_nodes || []
    const triggerData = execution.trigger_data
    let stepsCompleted = 0

    // Execute each action node
    for (let i = 1; i < nodes.length; i++) {
      const node = nodes[i]
      
      if (node.type === 'action') {
        try {
          await executeAction(node, triggerData)
          stepsCompleted++
          
          // Update progress
          await supabase
            .from('workflow_executions')
            .update({ steps_completed: stepsCompleted })
            .eq('id', execution_id)
        } catch (actionError) {
          console.error('Action execution error:', actionError)
          throw actionError
        }
      }
    }

    // Mark as completed
    await supabase
      .from('workflow_executions')
      .update({
        status: 'completed',
        steps_completed: stepsCompleted,
        completed_at: new Date().toISOString()
      })
      .eq('id', execution_id)

    // Update automation stats
    await supabase
      .from('automations')
      .update({
        total_runs: (automation.total_runs || 0) + 1,
        last_run: new Date().toISOString()
      })
      .eq('id', automation.id)

    return new Response(
      JSON.stringify({ success: true, execution_id, steps_completed: stepsCompleted }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Workflow execution error:', error)
    
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

async function executeAction(node: WorkflowNode, triggerData: Record<string, any>) {
  const { properties } = node
  
  if (properties.action_type === 'webhook') {
    await executeWebhookAction(properties.webhook_config, triggerData)
  }
}

async function executeWebhookAction(config: WebhookConfig, triggerData: Record<string, any>) {
  if (!config || !config.webhook_url) {
    throw new Error('Webhook URL not configured')
  }

  // Build URL with query parameters
  let url = config.webhook_url
  if (config.query_params && config.query_params.length > 0) {
    const params = new URLSearchParams()
    config.query_params.forEach(param => {
      if (param.key && param.value) {
        const value = replacePlaceholders(param.value, triggerData)
        params.append(param.key, value)
      }
    })
    url += '?' + params.toString()
  }

  // Build headers
  const headers: Record<string, string> = {}
  if (config.headers && config.headers.length > 0) {
    config.headers.forEach(header => {
      if (header.key && header.value) {
        headers[header.key] = replacePlaceholders(header.value, triggerData)
      }
    })
  }

  // Build body
  const body: Record<string, any> = {}
  if (config.body && config.body.length > 0) {
    config.body.forEach(param => {
      if (param.key) {
        body[param.key] = replacePlaceholders(param.value || '', triggerData)
      }
    })
  }

  // Make the webhook request
  const response = await fetch(url, {
    method: 'POST',
    headers: headers,
    body: JSON.stringify(body)
  })

  if (!response.ok) {
    throw new Error(`Webhook request failed: ${response.status} ${response.statusText}`)
  }

  return await response.text()
}

function replacePlaceholders(template: string, data: Record<string, any>): string {
  return template.replace(/\{\{(\w+)\}\}/g, (match, key) => {
    return data[key] !== undefined ? String(data[key]) : match
  })
}
