import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface UpdateTicketPayload {
  ticket_id: string
  contact_id?: string
  subject?: string
  description?: string
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

    const payload: UpdateTicketPayload = await req.json()

    if (!payload.ticket_id) {
      return new Response(
        JSON.stringify({
          error: 'Missing required field',
          required: ['ticket_id'],
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

    const { data: existingTicket, error: checkError } = await supabase
      .from('support_tickets')
      .select('id, ticket_id')
      .eq('ticket_id', payload.ticket_id)
      .maybeSingle()

    if (checkError) {
      console.error('Error checking existing ticket:', checkError)
      return new Response(
        JSON.stringify({ error: 'Failed to check existing ticket', details: checkError.message }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    if (!existingTicket) {
      return new Response(
        JSON.stringify({
          error: 'Ticket not found',
          ticket_id: payload.ticket_id,
        }),
        {
          status: 404,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    if (payload.contact_id) {
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

    const updateData: any = {
      updated_at: new Date().toISOString(),
    }

    if (payload.contact_id !== undefined) updateData.contact_id = payload.contact_id
    if (payload.subject !== undefined) updateData.subject = payload.subject
    if (payload.description !== undefined) updateData.description = payload.description
    if (payload.priority !== undefined) updateData.priority = payload.priority
    if (payload.status !== undefined) updateData.status = payload.status
    if (payload.category !== undefined) updateData.category = payload.category
    if (payload.assigned_to !== undefined) updateData.assigned_to = payload.assigned_to
    if (payload.response_time !== undefined) updateData.response_time = payload.response_time
    if (payload.satisfaction !== undefined) updateData.satisfaction = payload.satisfaction
    if (payload.tags !== undefined) updateData.tags = payload.tags
    if (payload.attachment_1_url !== undefined) updateData.attachment_1_url = payload.attachment_1_url
    if (payload.attachment_1_name !== undefined) updateData.attachment_1_name = payload.attachment_1_name
    if (payload.attachment_2_url !== undefined) updateData.attachment_2_url = payload.attachment_2_url
    if (payload.attachment_2_name !== undefined) updateData.attachment_2_name = payload.attachment_2_name
    if (payload.attachment_3_url !== undefined) updateData.attachment_3_url = payload.attachment_3_url
    if (payload.attachment_3_name !== undefined) updateData.attachment_3_name = payload.attachment_3_name

    const { data: updatedTicket, error: updateError } = await supabase
      .from('support_tickets')
      .update(updateData)
      .eq('ticket_id', payload.ticket_id)
      .select()
      .single()

    if (updateError) {
      console.error('Error updating ticket:', updateError)
      return new Response(
        JSON.stringify({ error: 'Failed to update ticket', details: updateError.message }),
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
        message: 'Support ticket updated successfully',
        data: updatedTicket,
      }),
      {
        status: 200,
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
