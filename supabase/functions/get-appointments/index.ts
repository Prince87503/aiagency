import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface FilterParams {
  appointment_id?: string
  status?: string
  meeting_type?: string
  purpose?: string
  assigned_to?: string
  contact_id?: string
  calendar_id?: string
  appointment_date?: string
  created_by?: string
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
      const validStatuses = ['Scheduled', 'Confirmed', 'Completed', 'Cancelled', 'No-Show']
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

    if (filters.meeting_type) {
      const validMeetingTypes = ['In-Person', 'Video Call', 'Phone Call']
      if (!validMeetingTypes.includes(filters.meeting_type)) {
        return new Response(
          JSON.stringify({
            error: 'Invalid meeting_type',
            valid_values: validMeetingTypes,
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

    if (filters.purpose) {
      const validPurposes = ['Sales Meeting', 'Product Demo', 'Follow-up', 'Consultation', 'Other']
      if (!validPurposes.includes(filters.purpose)) {
        return new Response(
          JSON.stringify({
            error: 'Invalid purpose',
            valid_values: validPurposes,
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

    if (filters.created_by) {
      const { data: createdByUser, error: createdByUserError } = await supabase
        .from('admin_users')
        .select('id')
        .eq('id', filters.created_by)
        .maybeSingle()

      if (!createdByUser || createdByUserError) {
        return new Response(
          JSON.stringify({
            error: 'Invalid created_by UUID',
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

    if (filters.calendar_id) {
      const { data: calendar, error: calendarError } = await supabase
        .from('calendars')
        .select('id')
        .eq('id', filters.calendar_id)
        .maybeSingle()

      if (!calendar || calendarError) {
        return new Response(
          JSON.stringify({
            error: 'Invalid calendar_id UUID',
            message: 'Calendar ID not found in calendars table',
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
      .from('appointments')
      .select('*')

    if (filters.appointment_id) {
      query = query.eq('appointment_id', filters.appointment_id)
    }

    if (filters.status) {
      query = query.eq('status', filters.status)
    }

    if (filters.meeting_type) {
      query = query.eq('meeting_type', filters.meeting_type)
    }

    if (filters.purpose) {
      query = query.eq('purpose', filters.purpose)
    }

    if (filters.assigned_to) {
      query = query.eq('assigned_to', filters.assigned_to)
    }

    if (filters.created_by) {
      query = query.eq('created_by', filters.created_by)
    }

    if (filters.contact_id) {
      query = query.eq('contact_id', filters.contact_id)
    }

    if (filters.calendar_id) {
      query = query.eq('calendar_id', filters.calendar_id)
    }

    if (filters.appointment_date) {
      query = query.eq('appointment_date', filters.appointment_date)
    }

    query = query.order('created_at', { ascending: false })

    const { data: appointments, error: fetchError } = await query

    if (fetchError) {
      console.error('Error fetching appointments:', fetchError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch appointments', details: fetchError.message }),
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
        count: appointments?.length || 0,
        data: appointments || [],
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
