import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface ContactPayload {
  full_name: string
  email?: string
  phone: string
  date_of_birth?: string
  gender?: string
  education_level?: string
  profession?: string
  experience?: string
  business_name?: string
  address?: string
  city?: string
  state?: string
  pincode?: string
  gst_number?: string
  contact_type?: string
  status?: string
  notes?: string
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

    const payload: ContactPayload = await req.json()

    if (!payload.full_name || !payload.phone) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields',
          required: ['full_name', 'phone'],
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

    const { data: existingContact, error: checkError } = await supabase
      .from('contacts_master')
      .select('id, phone, contact_id')
      .eq('phone', payload.phone)
      .maybeSingle()

    if (checkError) {
      console.error('Error checking existing contact:', checkError)
      return new Response(
        JSON.stringify({ error: 'Failed to check existing contact', details: checkError.message }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    let contactData
    let operationType

    if (existingContact) {
      const { data: updatedContact, error: updateError } = await supabase
        .from('contacts_master')
        .update({
          full_name: payload.full_name,
          email: payload.email || null,
          date_of_birth: payload.date_of_birth || null,
          gender: payload.gender || null,
          education_level: payload.education_level || null,
          profession: payload.profession || null,
          experience: payload.experience || null,
          business_name: payload.business_name || null,
          address: payload.address || null,
          city: payload.city || null,
          state: payload.state || null,
          pincode: payload.pincode || null,
          gst_number: payload.gst_number || null,
          contact_type: payload.contact_type || 'Customer',
          status: payload.status || 'Active',
          notes: payload.notes || null,
          updated_at: new Date().toISOString(),
        })
        .eq('phone', payload.phone)
        .select()
        .single()

      if (updateError) {
        console.error('Error updating contact:', updateError)
        return new Response(
          JSON.stringify({ error: 'Failed to update contact', details: updateError.message }),
          {
            status: 500,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json',
            },
          }
        )
      }

      contactData = updatedContact
      operationType = 'updated'
    } else {
      const { data: newContact, error: insertError } = await supabase
        .from('contacts_master')
        .insert({
          full_name: payload.full_name,
          email: payload.email || null,
          phone: payload.phone,
          date_of_birth: payload.date_of_birth || null,
          gender: payload.gender || null,
          education_level: payload.education_level || null,
          profession: payload.profession || null,
          experience: payload.experience || null,
          business_name: payload.business_name || null,
          address: payload.address || null,
          city: payload.city || null,
          state: payload.state || null,
          pincode: payload.pincode || null,
          gst_number: payload.gst_number || null,
          contact_type: payload.contact_type || 'Customer',
          status: payload.status || 'Active',
          notes: payload.notes || null,
        })
        .select()
        .single()

      if (insertError) {
        console.error('Error inserting contact:', insertError)
        return new Response(
          JSON.stringify({ error: 'Failed to add contact', details: insertError.message }),
          {
            status: 500,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json',
            },
          }
        )
      }

      contactData = newContact
      operationType = 'created'
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Contact ${operationType} successfully`,
        operation: operationType,
        data: contactData,
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
