import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

interface FilterParams {
  expense_id?: string
  status?: string
  category?: string
  payment_method?: string
  admin_user_id?: string
  approved_by?: string
  expense_date?: string
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
      const validStatuses = ['Pending', 'Approved', 'Rejected', 'Paid']
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

    if (filters.category) {
      const validCategories = ['Travel', 'Office Supplies', 'Marketing', 'Software', 'Meals', 'Entertainment', 'Training', 'Other']
      if (!validCategories.includes(filters.category)) {
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

    if (filters.payment_method) {
      const validPaymentMethods = ['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Digital Wallet', 'Other']
      if (!validPaymentMethods.includes(filters.payment_method)) {
        return new Response(
          JSON.stringify({
            error: 'Invalid payment_method',
            valid_values: validPaymentMethods,
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

    if (filters.admin_user_id) {
      const { data: adminUser, error: adminUserError } = await supabase
        .from('admin_users')
        .select('id')
        .eq('id', filters.admin_user_id)
        .maybeSingle()

      if (!adminUser || adminUserError) {
        return new Response(
          JSON.stringify({
            error: 'Invalid admin_user_id UUID',
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

    if (filters.approved_by) {
      const { data: approver, error: approverError } = await supabase
        .from('admin_users')
        .select('id')
        .eq('id', filters.approved_by)
        .maybeSingle()

      if (!approver || approverError) {
        return new Response(
          JSON.stringify({
            error: 'Invalid approved_by UUID',
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

    let query = supabase
      .from('expenses')
      .select('*')

    if (filters.expense_id) {
      query = query.eq('expense_id', filters.expense_id)
    }

    if (filters.status) {
      query = query.eq('status', filters.status)
    }

    if (filters.category) {
      query = query.eq('category', filters.category)
    }

    if (filters.payment_method) {
      query = query.eq('payment_method', filters.payment_method)
    }

    if (filters.admin_user_id) {
      query = query.eq('admin_user_id', filters.admin_user_id)
    }

    if (filters.approved_by) {
      query = query.eq('approved_by', filters.approved_by)
    }

    if (filters.expense_date) {
      query = query.eq('expense_date', filters.expense_date)
    }

    query = query.order('created_at', { ascending: false })

    const { data: expenses, error: fetchError } = await query

    if (fetchError) {
      console.error('Error fetching expenses:', fetchError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch expenses', details: fetchError.message }),
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
        count: expenses?.length || 0,
        data: expenses || [],
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
