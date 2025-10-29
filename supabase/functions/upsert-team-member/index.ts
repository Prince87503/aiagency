import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface TeamMemberPayload {
  phone: string
  email?: string
  full_name: string
  role: string
  department?: string
  permissions?: any
  status?: string
  is_active?: boolean
  member_id?: string
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

    if (!payload.phone || !payload.full_name || !payload.role) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields',
          required: ['phone', 'full_name', 'role'],
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

    let teamMemberData
    let operationType

    const { data: existingMember, error: checkError } = await supabase
      .from('admin_users')
      .select('id, phone, email, member_id')
      .eq('phone', payload.phone)
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
      const updateData: any = {
        updated_at: new Date().toISOString(),
      }

      if (payload.full_name !== undefined) updateData.full_name = payload.full_name
      if (payload.email !== undefined) updateData.email = payload.email
      if (payload.role !== undefined) updateData.role = payload.role
      if (payload.department !== undefined) updateData.department = payload.department
      if (payload.permissions !== undefined) updateData.permissions = payload.permissions
      if (payload.status !== undefined) updateData.status = payload.status
      if (payload.is_active !== undefined) updateData.is_active = payload.is_active

      const { data: updatedMember, error: updateError } = await supabase
        .from('admin_users')
        .update(updateData)
        .eq('phone', payload.phone)
        .select()
        .single()

      if (updateError) {
        console.error('Error updating team member:', updateError)
        return new Response(
          JSON.stringify({ error: 'Failed to update team member', details: updateError.message }),
          {
            status: 500,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json',
            },
          }
        )
      }

      teamMemberData = updatedMember
      operationType = 'updated'
    } else {
      if (!payload.email) {
        return new Response(
          JSON.stringify({
            error: 'Email is required when creating a new team member',
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

      const { data: emailCheck } = await supabase
        .from('admin_users')
        .select('id, email')
        .eq('email', payload.email)
        .maybeSingle()

      if (emailCheck) {
        return new Response(
          JSON.stringify({
            error: 'Email already exists for another team member',
            existing_member: emailCheck,
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
          phone: payload.phone,
          permissions: payload.permissions || {},
          status: payload.status || 'Active',
          is_active: payload.is_active !== undefined ? payload.is_active : true,
          password_hash: 'webhook_user_no_password',
        })
        .select()
        .single()

      if (insertError) {
        console.error('Error inserting team member:', insertError)
        return new Response(
          JSON.stringify({ error: 'Failed to create team member', details: insertError.message }),
          {
            status: 500,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json',
            },
          }
        )
      }

      teamMemberData = newMember
      operationType = 'created'
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Team member ${operationType} successfully`,
        operation: operationType,
        data: teamMemberData,
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
