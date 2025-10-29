import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface AppointmentPayload {
  appointment_id?: string
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

    let appointmentData
    let operationType

    if (payload.appointment_id) {
      const { data: existingAppointment, error: checkError } = await supabase
        .from('appointments')
        .select('id, appointment_id')
        .eq('appointment_id', payload.appointment_id)
        .maybeSingle()

      if (checkError) {
        console.error('Error checking existing appointment:', checkError)
        return new Response(
          JSON.stringify({ error: 'Failed to check existing appointment', details: checkError.message }),
          {
            status: 500,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json',
            },
          }
        )
      }

      if (existingAppointment) {
        const updateData: any = {
          updated_at: new Date().toISOString(),
        }

        if (payload.contact_id !== undefined) {
          const { data: contact } = await supabase
            .from('contacts_master')
            .select('id')
            .eq('contact_id', payload.contact_id)
            .maybeSingle()
          updateData.contact_id = contact?.id || null
        }

        if (payload.assigned_to !== undefined) {
          const { data: adminUser } = await supabase
            .from('admin_users')
            .select('id')
            .eq('user_id', payload.assigned_to)
            .maybeSingle()
          updateData.assigned_to = adminUser?.id || null
        }

        if (payload.calendar_id !== undefined) {
          const { data: calendar } = await supabase
            .from('calendars')
            .select('id')
            .eq('calendar_id', payload.calendar_id)
            .maybeSingle()
          updateData.calendar_id = calendar?.id || null
        }

        if (payload.created_by !== undefined) {
          const { data: creator } = await supabase
            .from('admin_users')
            .select('id')
            .eq('user_id', payload.created_by)
            .maybeSingle()
          updateData.created_by = creator?.id || null
        }

        if (payload.title !== undefined) updateData.title = payload.title
        if (payload.contact_name !== undefined) updateData.contact_name = payload.contact_name
        if (payload.contact_phone !== undefined) updateData.contact_phone = payload.contact_phone
        if (payload.contact_email !== undefined) updateData.contact_email = payload.contact_email
        if (payload.appointment_date !== undefined) updateData.appointment_date = payload.appointment_date
        if (payload.appointment_time !== undefined) updateData.appointment_time = payload.appointment_time
        if (payload.duration_minutes !== undefined) updateData.duration_minutes = payload.duration_minutes
        if (payload.location !== undefined) updateData.location = payload.location
        if (payload.meeting_type !== undefined) updateData.meeting_type = payload.meeting_type
        if (payload.status !== undefined) updateData.status = payload.status
        if (payload.purpose !== undefined) updateData.purpose = payload.purpose
        if (payload.notes !== undefined) updateData.notes = payload.notes
        if (payload.reminder_sent !== undefined) updateData.reminder_sent = payload.reminder_sent

        const { data: updatedAppointment, error: updateError } = await supabase
          .from('appointments')
          .update(updateData)
          .eq('appointment_id', payload.appointment_id)
          .select()
          .single()

        if (updateError) {
          console.error('Error updating appointment:', updateError)
          return new Response(
            JSON.stringify({ error: 'Failed to update appointment', details: updateError.message }),
            {
              status: 500,
              headers: {
                ...corsHeaders,
                'Content-Type': 'application/json',
              },
            }
          )
        }

        appointmentData = updatedAppointment
        operationType = 'updated'
      } else {
        return new Response(
          JSON.stringify({
            error: 'Appointment ID provided but not found',
            appointment_id: payload.appointment_id,
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
    } else {
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

      appointmentData = newAppointment
      operationType = 'created'
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Appointment ${operationType} successfully`,
        operation: operationType,
        data: appointmentData,
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
