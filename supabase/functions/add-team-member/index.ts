import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface TeamMemberPayload {
  email: string
  full_name: string
  role: string
  department?: string
  permissions?: any
  phone?: string
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

    const payload: TeamMemberPayload = await req.json()

    if (!payload.email || !payload.full_name || !payload.role) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields',
          required: ['email', 'full_name', 'role'],
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

    const { data: existingMember, error: checkError } = await supabase
      .from('admin_users')
      .select('id, email')
      .eq('email', payload.email)
      .maybeSingle()

    if (checkError) {
      console.error('Error checking existing member:', checkError)
      return new Response(
        JSON.stringify({ error: 'Failed to check existing member', details: checkError.message }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    if (existingMember) {
      return new Response(
        JSON.stringify({
          error: 'Team member already exists',
          member: existingMember,
        }),
        {
          status: 409,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    const { data: newMember, error: insertError } = await supabase
      .from('admin_users')
      .insert({
        email: payload.email,
        full_name: payload.full_name,
        role: payload.role,
        department: payload.department || null,
        phone: payload.phone || null,
        permissions: payload.permissions || {},
        status: 'Active',
        password_hash: 'webhook_user_no_password',
      })
      .select()
      .single()

    if (insertError) {
      console.error('Error inserting team member:', insertError)
      return new Response(
        JSON.stringify({ error: 'Failed to add team member', details: insertError.message }),
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
        message: 'Team member added successfully',
        data: newMember,
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
