import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface UpdateTaskPayload {
  task_id: string
  title?: string
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

    const payload: UpdateTaskPayload = await req.json()

    if (!payload.task_id) {
      return new Response(
        JSON.stringify({
          error: 'Missing required field',
          required: ['task_id'],
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

    const { data: existingTask, error: checkError } = await supabase
      .from('tasks')
      .select('id, task_id')
      .eq('task_id', payload.task_id)
      .maybeSingle()

    if (checkError) {
      console.error('Error checking existing task:', checkError)
      return new Response(
        JSON.stringify({ error: 'Failed to check existing task', details: checkError.message }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    if (!existingTask) {
      return new Response(
        JSON.stringify({
          error: 'Task not found',
          task_id: payload.task_id,
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

    const updateData: any = {
      updated_at: new Date().toISOString(),
    }

    if (payload.title !== undefined) updateData.title = payload.title
    if (payload.description !== undefined) updateData.description = payload.description
    if (payload.status !== undefined) updateData.status = payload.status
    if (payload.priority !== undefined) updateData.priority = payload.priority
    if (payload.assigned_to !== undefined) updateData.assigned_to = payload.assigned_to
    if (payload.assigned_by !== undefined) updateData.assigned_by = payload.assigned_by
    if (payload.due_date !== undefined) updateData.due_date = payload.due_date
    if (payload.start_date !== undefined) updateData.start_date = payload.start_date
    if (payload.completion_date !== undefined) updateData.completion_date = payload.completion_date
    if (payload.estimated_hours !== undefined) updateData.estimated_hours = payload.estimated_hours
    if (payload.actual_hours !== undefined) updateData.actual_hours = payload.actual_hours
    if (payload.category !== undefined) updateData.category = payload.category
    if (payload.tags !== undefined) updateData.tags = payload.tags
    if (payload.attachments !== undefined) updateData.attachments = payload.attachments
    if (payload.progress_percentage !== undefined) updateData.progress_percentage = payload.progress_percentage
    if (payload.notes !== undefined) updateData.notes = payload.notes
    if (payload.contact_id !== undefined) updateData.contact_id = payload.contact_id

    const { data: updatedTask, error: updateError } = await supabase
      .from('tasks')
      .update(updateData)
      .eq('task_id', payload.task_id)
      .select()
      .single()

    if (updateError) {
      console.error('Error updating task:', updateError)
      return new Response(
        JSON.stringify({ error: 'Failed to update task', details: updateError.message }),
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
        message: 'Task updated successfully',
        data: updatedTask,
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
