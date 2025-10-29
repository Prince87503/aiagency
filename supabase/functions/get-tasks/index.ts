import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface FilterParams {
  task_id?: string
  status?: string
  assigned_by?: string
  assigned_to?: string
  contact_id?: string
  due_date?: string
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

    const filters: FilterParams = await req.json()

    if (filters.status) {
      const validStatuses = ['To Do', 'In Progress', 'In Review', 'Completed', 'Cancelled']
      if (!validStatuses.includes(filters.status)) {
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

    if (filters.assigned_by) {
      const { data: assignedByUser, error: assignedByUserError } = await supabase
        .from('admin_users')
        .select('id')
        .eq('id', filters.assigned_by)
        .maybeSingle()

      if (!assignedByUser || assignedByUserError) {
        return new Response(
          JSON.stringify({
            error: 'Invalid assigned_by UUID',
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

    if (filters.assigned_to) {
      const { data: assignedToUser, error: assignedToUserError } = await supabase
        .from('admin_users')
        .select('id')
        .eq('id', filters.assigned_to)
        .maybeSingle()

      if (!assignedToUser || assignedToUserError) {
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

    if (filters.contact_id) {
      const { data: contact, error: contactError } = await supabase
        .from('contacts_master')
        .select('id')
        .eq('id', filters.contact_id)
        .maybeSingle()

      if (!contact || contactError) {
        return new Response(
          JSON.stringify({
            error: 'Invalid contact_id UUID',
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

    let query = supabase
      .from('tasks')
      .select('*')

    if (filters.task_id) {
      query = query.eq('task_id', filters.task_id)
    }

    if (filters.status) {
      query = query.eq('status', filters.status)
    }

    if (filters.assigned_by) {
      query = query.eq('assigned_by', filters.assigned_by)
    }

    if (filters.assigned_to) {
      query = query.eq('assigned_to', filters.assigned_to)
    }

    if (filters.contact_id) {
      query = query.eq('contact_id', filters.contact_id)
    }

    if (filters.due_date) {
      query = query.eq('due_date', filters.due_date)
    }

    query = query.order('created_at', { ascending: false })

    const { data: tasks, error: fetchError } = await query

    if (fetchError) {
      console.error('Error fetching tasks:', fetchError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch tasks', details: fetchError.message }),
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
        count: tasks?.length || 0,
        data: tasks || [],
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
