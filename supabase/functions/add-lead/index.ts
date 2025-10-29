import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface LeadPayload {
  name: string
  phone: string
  email?: string
  source?: string
  interest?: string
  stage?: string
  pipeline_id?: string
  contact_id?: string
  owner?: string
  address?: string
  company?: string
  notes?: string
  lead_score?: number
  affiliate_id?: string
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    })
  }

  try {
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed. Use POST.' }),
        {
          status: 405,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const payload: LeadPayload = await req.json()

    if (!payload.name || !payload.phone) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields',
          required: ['name', 'phone'],
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    const { data: existingLead, error: checkError } = await supabase
      .from('leads')
      .select('id, phone, lead_id')
      .eq('phone', payload.phone)
      .maybeSingle()

    if (checkError) {
      console.error('Error checking existing lead:', checkError)
      return new Response(
        JSON.stringify({ error: 'Failed to check existing lead', details: checkError.message }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    let leadData
    let operationType

    if (existingLead) {
      let pipelineUuid = null
      if (payload.pipeline_id) {
        const { data: pipeline } = await supabase
          .from('pipelines')
          .select('id')
          .eq('pipeline_id', payload.pipeline_id)
          .maybeSingle()

        pipelineUuid = pipeline?.id || null
      }

      let contactUuid = null
      if (payload.contact_id) {
        const { data: contact } = await supabase
          .from('contacts_master')
          .select('id')
          .eq('contact_id', payload.contact_id)
          .maybeSingle()

        contactUuid = contact?.id || null
      }

      const { data: updatedLead, error: updateError } = await supabase
        .from('leads')
        .update({
          name: payload.name,
          email: payload.email || null,
          source: payload.source || 'Website',
          interest: payload.interest || 'Warm',
          stage: payload.stage || 'New',
          pipeline_id: pipelineUuid,
          contact_id: contactUuid,
          owner: payload.owner || 'Sales Team',
          address: payload.address || null,
          company: payload.company || null,
          notes: payload.notes || null,
          lead_score: payload.lead_score || 50,
          affiliate_id: payload.affiliate_id || null,
          updated_at: new Date().toISOString(),
        })
        .eq('phone', payload.phone)
        .select()
        .single()

      if (updateError) {
        console.error('Error updating lead:', updateError)
        return new Response(
          JSON.stringify({ error: 'Failed to update lead', details: updateError.message }),
          {
            status: 500,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json',
            },
          }
        )
      }

      leadData = updatedLead
      operationType = 'updated'
    } else {
      let pipelineUuid = null
      if (payload.pipeline_id) {
        const { data: pipeline } = await supabase
          .from('pipelines')
          .select('id')
          .eq('pipeline_id', payload.pipeline_id)
          .maybeSingle()

        pipelineUuid = pipeline?.id || null
      }

      if (!pipelineUuid) {
        const { data: defaultPipeline } = await supabase
          .from('pipelines')
          .select('id')
          .eq('entity_type', 'lead')
          .eq('is_default', true)
          .maybeSingle()

        pipelineUuid = defaultPipeline?.id || null
      }

      let contactUuid = null
      if (payload.contact_id) {
        const { data: contact } = await supabase
          .from('contacts_master')
          .select('id')
          .eq('contact_id', payload.contact_id)
          .maybeSingle()

        contactUuid = contact?.id || null
      }

      const { data: newLead, error: insertError } = await supabase
        .from('leads')
        .insert({
          name: payload.name,
          phone: payload.phone,
          email: payload.email || null,
          source: payload.source || 'Website',
          interest: payload.interest || 'Warm',
          stage: payload.stage || 'New',
          pipeline_id: pipelineUuid,
          contact_id: contactUuid,
          owner: payload.owner || 'Sales Team',
          address: payload.address || null,
          company: payload.company || null,
          notes: payload.notes || null,
          lead_score: payload.lead_score || 50,
          affiliate_id: payload.affiliate_id || null,
        })
        .select()
        .single()

      if (insertError) {
        console.error('Error inserting lead:', insertError)
        return new Response(
          JSON.stringify({ error: 'Failed to add lead', details: insertError.message }),
          {
            status: 500,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json',
            },
          }
        )
      }

      leadData = newLead
      operationType = 'created'
    }

    const n8nWebhookUrl = 'https://n8n.srv825961.hstgr.cloud/webhook/b9306df2-26cc-447e-abb4-b2cfe8e1acdd'

    try {
      await fetch(n8nWebhookUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(leadData),
      })
      console.log('Successfully sent lead to n8n webhook')
    } catch (n8nError) {
      console.error('Error sending to n8n webhook:', n8nError)
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Lead ${operationType} successfully`,
        operation: operationType,
        data: leadData,
      }),
      {
        status: operationType === 'created' ? 201 : 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    )
  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    )
  }
})
