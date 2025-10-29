import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface TaskPayload {
  title: string
  description?: string
  status?: string
  priority?: string
  assigned_to?: string
  assigned_by?: string
  due_date?: string
  start_date?: string
  completion_date?: string
  estimated_hours?: number
  actual_hours?: number
  category?: string
  tags?: string[]
  attachments?: any[]
  progress_percentage?: number
  notes?: string
  contact_id?: string
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

    const payload: TaskPayload = await req.json()

    if (!payload.title) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields',
          required: ['title'],
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

    if (payload.status) {
      const validStatuses = ['To Do', 'In Progress', 'In Review', 'Completed', 'Cancelled']
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

    if (payload.priority) {
      const validPriorities = ['Low', 'Medium', 'High', 'Urgent']
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

    if (payload.category) {
      const validCategories = ['Development', 'Design', 'Marketing', 'Sales', 'Support', 'Operations', 'Other']
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

    if (payload.progress_percentage !== undefined) {
      if (payload.progress_percentage < 0 || payload.progress_percentage > 100) {
        return new Response(
          JSON.stringify({
            error: 'Invalid progress_percentage',
            message: 'Must be between 0 and 100',
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
            error: 'Invalid assigned_to',
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

    if (payload.assigned_by) {
      const { data: assignedByUser, error: assignedByUserError } = await supabase
        .from('admin_users')
        .select('id')
        .eq('id', payload.assigned_by)
        .maybeSingle()

      if (!assignedByUser || assignedByUserError) {
        return new Response(
          JSON.stringify({
            error: 'Invalid assigned_by',
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

    const insertData: any = {
      title: payload.title,
      description: payload.description || null,
      status: payload.status || 'To Do',
      priority: payload.priority || 'Medium',
      assigned_to: payload.assigned_to || null,
      assigned_by: payload.assigned_by || null,
      due_date: payload.due_date || null,
      start_date: payload.start_date || null,
      completion_date: payload.completion_date || null,
      estimated_hours: payload.estimated_hours || null,
      actual_hours: payload.actual_hours || null,
      category: payload.category || 'Other',
      tags: payload.tags || [],
      attachments: payload.attachments || [],
      progress_percentage: payload.progress_percentage !== undefined ? payload.progress_percentage : 0,
      notes: payload.notes || null,
      contact_id: payload.contact_id || null,
    }

    const { data: newTask, error: insertError } = await supabase
      .from('tasks')
      .insert(insertData)
      .select()
      .single()

    if (insertError) {
      console.error('Error inserting task:', insertError)
      return new Response(
        JSON.stringify({ error: 'Failed to create task', details: insertError.message }),
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
        message: 'Task created successfully',
        data: newTask,
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
