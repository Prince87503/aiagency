import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
};

interface EnrolledMemberPayload {
  user_id?: string;
  email: string;
  full_name: string;
  phone?: string;
  date_of_birth?: string;
  gender?: string;
  education_level?: string;
  profession?: string;
  experience?: string;
  business_name?: string;
  address?: string;
  city?: string;
  state?: string;
  pincode?: string;
  gst_number?: string;
  enrollment_date?: string;
  status?: string;
  course_id?: string;
  course_name?: string;
  payment_status?: string;
  payment_amount?: number;
  payment_date?: string;
  subscription_type?: string;
  notes?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    if (req.method === 'GET') {
      const url = new URL(req.url);
      const limit = url.searchParams.get('limit');
      const status = url.searchParams.get('status');
      const email = url.searchParams.get('email');

      let query = supabase
        .from('enrolled_members')
        .select('*')
        .order('enrollment_date', { ascending: false });

      if (status) {
        query = query.eq('status', status);
      }

      if (email) {
        query = query.eq('email', email);
      }

      if (limit) {
        query = query.limit(parseInt(limit));
      }

      const { data, error } = await query;

      if (error) {
        console.error('Database error:', error);
        return new Response(
          JSON.stringify({ error: 'Failed to fetch enrolled members', details: error.message }),
          {
            status: 500,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json',
            },
          }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          count: data?.length || 0,
          data: data,
        }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    }

    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed. Use GET or POST.' }),
        {
          status: 405,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    }

    const payload: EnrolledMemberPayload = await req.json();

    // Validate required fields
    if (!payload.email || !payload.full_name) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields',
          required: ['email', 'full_name'],
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(payload.email)) {
      return new Response(
        JSON.stringify({ error: 'Invalid email format' }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    }

    // Insert the enrolled member
    const { data, error } = await supabase
      .from('enrolled_members')
      .insert([
        {
          user_id: payload.user_id || null,
          email: payload.email,
          full_name: payload.full_name,
          phone: payload.phone || null,
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
          enrollment_date: payload.enrollment_date || new Date().toISOString(),
          status: payload.status || 'active',
          course_id: payload.course_id || null,
          course_name: payload.course_name || null,
          payment_status: payload.payment_status || 'pending',
          payment_amount: payload.payment_amount || null,
          payment_date: payload.payment_date || null,
          subscription_type: payload.subscription_type || null,
          notes: payload.notes || null,
        },
      ])
      .select()
      .single();

    if (error) {
      console.error('Database error:', error);
      return new Response(
        JSON.stringify({ error: 'Failed to create enrolled member', details: error.message }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Enrolled member added successfully',
        data: data,
      }),
      {
        status: 201,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    );
  } catch (error) {
    console.error('Unexpected error:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    );
  }
});