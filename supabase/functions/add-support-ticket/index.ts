import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface SupportTicketPayload {
  contact_id: string
  subject: string
  description: string
  priority?: string
  status?: string
  category?: string
  assigned_to?: string
  response_time?: string
  satisfaction?: number
  tags?: string[]
  attachment_1_url?: string
  attachment_1_name?: string
  attachment_2_url?: string
  attachment_2_name?: string
  attachment_3_url?: string
  attachment_3_name?: string
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

    const payload: SupportTicketPayload = await req.json()

    if (!payload.contact_id || !payload.subject || !payload.description) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields',
          required: ['contact_id', 'subject', 'description'],
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

    if (payload.priority) {
      const validPriorities = ['Low', 'Medium', 'High', 'Critical']
      if (!validPriorities.includes(payload.priority)) {
        return new Response(
          JSON.stringify({
            error: 'Invalid priority',
            valid_values: validPriorities,
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
    }

    if (payload.status) {
      const validStatuses = ['Open', 'In Progress', 'Resolved', 'Closed', 'Escalated']
      if (!validStatuses.includes(payload.status)) {
        return new Response(
          JSON.stringify({
            error: 'Invalid status',
            valid_values: validStatuses,
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
    }

    if (payload.category) {
      const validCategories = ['Technical', 'Billing', 'Course', 'Refund', 'Feature Request', 'General']
      if (!validCategories.includes(payload.category)) {
        return new Response(
          JSON.stringify({
            error: 'Invalid category',
            valid_values: validCategories,
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
    }

    if (payload.satisfaction !== undefined) {
      if (payload.satisfaction < 1 || payload.satisfaction > 5) {
        return new Response(
          JSON.stringify({
            error: 'Invalid satisfaction rating',
            message: 'Must be between 1 and 5',
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
    }

    const { data: contact, error: contactError } = await supabase
      .from('contacts_master')
      .select('id')
      .eq('id', payload.contact_id)
      .maybeSingle()

    if (!contact || contactError) {
      return new Response(
        JSON.stringify({
          error: 'Invalid contact_id',
          message: 'Contact ID not found in contacts_master table',
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

    if (payload.assigned_to) {
      const { data: assignedUser, error: assignedUserError } = await supabase
        .from('admin_users')
        .select('id')
        .eq('id', payload.assigned_to)
        .maybeSingle()

      if (!assignedUser || assignedUserError) {
        return new Response(
          JSON.stringify({
            error: 'Invalid assigned_to UUID',
            message: 'User ID not found in admin_users table',
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
    }

    const { data: latestTicket } = await supabase
      .from('support_tickets')
      .select('ticket_id')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    let nextTicketNumber = 1
    if (latestTicket && latestTicket.ticket_id) {
      const match = latestTicket.ticket_id.match(/TKT-(\d+)/)
      if (match) {
        nextTicketNumber = parseInt(match[1], 10) + 1
      }
    }

    const newTicketId = `TKT-${nextTicketNumber.toString().padStart(6, '0')}`

    const insertData: any = {
      ticket_id: newTicketId,
      contact_id: payload.contact_id,
      subject: payload.subject,
      description: payload.description,
      priority: payload.priority || 'Medium',
      status: payload.status || 'Open',
      category: payload.category || 'General',
      assigned_to: payload.assigned_to || null,
      response_time: payload.response_time || null,
      satisfaction: payload.satisfaction || null,
      tags: payload.tags || [],
      attachment_1_url: payload.attachment_1_url || null,
      attachment_1_name: payload.attachment_1_name || null,
      attachment_2_url: payload.attachment_2_url || null,
      attachment_2_name: payload.attachment_2_name || null,
      attachment_3_url: payload.attachment_3_url || null,
      attachment_3_name: payload.attachment_3_name || null,
    }

    const { data: newTicket, error: insertError } = await supabase
      .from('support_tickets')
      .insert(insertData)
      .select()
      .single()

    if (insertError) {
      console.error('Error inserting ticket:', insertError)
      return new Response(
        JSON.stringify({ error: 'Failed to create ticket', details: insertError.message }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Support ticket created successfully',
        data: newTicket,
      }),
      {
        status: 201,
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
