import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface AppointmentPayload {
  title: string
  contact_id?: string
  contact_name: string
  contact_phone: string
  contact_email?: string
  appointment_date: string
  appointment_time: string
  duration_minutes?: number
  location?: string
  meeting_type: string
  status?: string
  purpose: string
  notes?: string
  reminder_sent?: boolean
  assigned_to?: string
  calendar_id?: string
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

    const payload: AppointmentPayload = await req.json()

    if (!payload.title || !payload.contact_name || !payload.contact_phone ||
        !payload.appointment_date || !payload.appointment_time ||
        !payload.meeting_type || !payload.purpose) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields',
          required: ['title', 'contact_name', 'contact_phone', 'appointment_date', 'appointment_time', 'meeting_type', 'purpose'],
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

    const validMeetingTypes = ['In-Person', 'Video Call', 'Phone Call']
    if (!validMeetingTypes.includes(payload.meeting_type)) {
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

    const validPurposes = ['Sales Meeting', 'Product Demo', 'Follow-up', 'Consultation', 'Other']
    if (!validPurposes.includes(payload.purpose)) {
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

    if (payload.status) {
      const validStatuses = ['Scheduled', 'Confirmed', 'Completed', 'Cancelled', 'No-Show']
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

    let contactUuid = null
    if (payload.contact_id) {
      const { data: contact } = await supabase
        .from('contacts_master')
        .select('id')
        .eq('contact_id', payload.contact_id)
        .maybeSingle()

      contactUuid = contact?.id || null
    }

    let assignedToUuid = null
    if (payload.assigned_to) {
      const { data: adminUser } = await supabase
        .from('admin_users')
        .select('id')
        .eq('user_id', payload.assigned_to)
        .maybeSingle()

      assignedToUuid = adminUser?.id || null
    }

    let calendarUuid = null
    if (payload.calendar_id) {
      const { data: calendar } = await supabase
        .from('calendars')
        .select('id')
        .eq('calendar_id', payload.calendar_id)
        .maybeSingle()

      calendarUuid = calendar?.id || null
    }

    let createdByUuid = null
    if (payload.created_by) {
      const { data: creator } = await supabase
        .from('admin_users')
        .select('id')
        .eq('user_id', payload.created_by)
        .maybeSingle()

      createdByUuid = creator?.id || null
    }

    const { data: newAppointment, error: insertError } = await supabase
      .from('appointments')
      .insert({
        title: payload.title,
        contact_id: contactUuid,
        contact_name: payload.contact_name,
        contact_phone: payload.contact_phone,
        contact_email: payload.contact_email || null,
        appointment_date: payload.appointment_date,
        appointment_time: payload.appointment_time,
        duration_minutes: payload.duration_minutes || 30,
        location: payload.location || null,
        meeting_type: payload.meeting_type,
        status: payload.status || 'Scheduled',
        purpose: payload.purpose,
        notes: payload.notes || null,
        reminder_sent: payload.reminder_sent || false,
        assigned_to: assignedToUuid,
        calendar_id: calendarUuid,
        created_by: createdByUuid,
      })
      .select()
      .single()

    if (insertError) {
      console.error('Error inserting appointment:', insertError)
      return new Response(
        JSON.stringify({ error: 'Failed to create appointment', details: insertError.message }),
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
        message: 'Appointment created successfully',
        data: newAppointment,
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
