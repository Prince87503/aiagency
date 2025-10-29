import { createClient } from 'npm:@supabase/supabase-js@2.58.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Call the database function to process due reminders
    const { data, error } = await supabase.rpc('process_due_task_reminders')

    if (error) {
      console.error('Error processing reminders:', error)
      throw error
    }

    const processedCount = data?.[0]?.processed_count || 0
    const reminderIds = data?.[0]?.reminder_ids || []

    console.log(`Processed ${processedCount} task reminders`)

    return new Response(
      JSON.stringify({
        success: true,
        message: `Processed ${processedCount} task reminders`,
        processed_count: processedCount,
        reminder_ids: reminderIds,
        timestamp: new Date().toISOString()
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
    console.error('Error in process-task-reminders:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Unknown error occurred',
        timestamp: new Date().toISOString()
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
