import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Calendar, Plus, Edit, Trash2, Save, X, Clock, MapPin, Users, Video, Phone, Eye, Settings as SettingsIcon, AlertCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { supabase } from '@/lib/supabase'

interface CalendarAvailability {
  enabled: boolean
  slots: Array<{ start: string; end: string }>
}

interface CalendarData {
  id: string
  calendar_id: string
  title: string
  description: string | null
  thumbnail: string | null
  availability: {
    monday: CalendarAvailability
    tuesday: CalendarAvailability
    wednesday: CalendarAvailability
    thursday: CalendarAvailability
    friday: CalendarAvailability
    saturday: CalendarAvailability
    sunday: CalendarAvailability
  }
  assigned_user_id: string | null
  slot_duration: number
  meeting_type: string[]
  default_location: string | null
  buffer_time: number
  max_bookings_per_day: number | null
  booking_window_days: number
  color: string
  is_active: boolean
  timezone: string
  created_at: string
  updated_at: string
}

interface TeamMember {
  id: string
  full_name: string
  email: string
}

const DAYS_OF_WEEK = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
const DAY_LABELS: Record<string, string> = {
  monday: 'Monday',
  tuesday: 'Tuesday',
  wednesday: 'Wednesday',
  thursday: 'Thursday',
  friday: 'Friday',
  saturday: 'Saturday',
  sunday: 'Sunday'
}

const MEETING_TYPES = ['In-Person', 'Video Call', 'Phone Call']

const DEFAULT_AVAILABILITY = {
  monday: { enabled: true, slots: [{ start: '09:00', end: '17:00' }] },
  tuesday: { enabled: true, slots: [{ start: '09:00', end: '17:00' }] },
  wednesday: { enabled: true, slots: [{ start: '09:00', end: '17:00' }] },
  thursday: { enabled: true, slots: [{ start: '09:00', end: '17:00' }] },
  friday: { enabled: true, slots: [{ start: '09:00', end: '17:00' }] },
  saturday: { enabled: false, slots: [] },
  sunday: { enabled: false, slots: [] }
}

export function CalendarSettings() {
  const [calendars, setCalendars] = useState<CalendarData[]>([])
  const [teamMembers, setTeamMembers] = useState<TeamMember[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [editingCalendar, setEditingCalendar] = useState<CalendarData | null>(null)
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    thumbnail: '',
    assignedUserId: '',
    slotDuration: '30',
    meetingTypes: ['In-Person', 'Video Call', 'Phone Call'],
    defaultLocation: '',
    bufferTime: '0',
    maxBookingsPerDay: '',
    maxBookingsPerSlot: '1',
    bookingWindowDays: '30',
    color: '#3B82F6',
    timezone: 'Asia/Kolkata',
    isActive: true
  })
  const [availability, setAvailability] = useState<CalendarData['availability']>(DEFAULT_AVAILABILITY)

  useEffect(() => {
    fetchCalendars()
    fetchTeamMembers()
  }, [])

  const fetchCalendars = async () => {
    setIsLoading(true)
    setError(null)
    try {
      const { data, error: fetchError } = await supabase
        .from('calendars')
        .select('*')
        .order('created_at', { ascending: false })

      if (fetchError) throw fetchError
      setCalendars(data || [])
    } catch (error) {
      console.error('Error fetching calendars:', error)
      setError(error instanceof Error ? error.message : 'Failed to fetch calendars')
    } finally {
      setIsLoading(false)
    }
  }

  const fetchTeamMembers = async () => {
    try {
      const { data, error: fetchError } = await supabase
        .from('admin_users')
        .select('id, full_name, email')
        .eq('status', 'Active')
        .order('full_name', { ascending: true })

      if (fetchError) throw fetchError
      setTeamMembers(data || [])
    } catch (error) {
      console.error('Error fetching team members:', error)
    }
  }

  const handleCreateCalendar = async () => {
    try {
      const { error: insertError } = await supabase
        .from('calendars')
        .insert({
          title: formData.title,
          description: formData.description || null,
          thumbnail: formData.thumbnail || null,
          availability: availability,
          assigned_user_id: formData.assignedUserId || null,
          slot_duration: parseInt(formData.slotDuration),
          meeting_type: formData.meetingTypes,
          default_location: formData.defaultLocation || null,
          buffer_time: parseInt(formData.bufferTime),
          max_bookings_per_day: formData.maxBookingsPerDay ? parseInt(formData.maxBookingsPerDay) : null,
          max_bookings_per_slot: parseInt(formData.maxBookingsPerSlot),
          booking_window_days: parseInt(formData.bookingWindowDays),
          color: formData.color,
          is_active: formData.isActive,
          timezone: formData.timezone
        })

      if (insertError) throw insertError

      setIsEditing(false)
      resetForm()
      fetchCalendars()
    } catch (error) {
      console.error('Error creating calendar:', error)
      setError(error instanceof Error ? error.message : 'Failed to create calendar')
    }
  }

  const handleUpdateCalendar = async () => {
    if (!editingCalendar) return

    try {
      const { error: updateError } = await supabase
        .from('calendars')
        .update({
          title: formData.title,
          description: formData.description || null,
          thumbnail: formData.thumbnail || null,
          availability: availability,
          assigned_user_id: formData.assignedUserId || null,
          slot_duration: parseInt(formData.slotDuration),
          meeting_type: formData.meetingTypes,
          default_location: formData.defaultLocation || null,
          buffer_time: parseInt(formData.bufferTime),
          max_bookings_per_day: formData.maxBookingsPerDay ? parseInt(formData.maxBookingsPerDay) : null,
          max_bookings_per_slot: parseInt(formData.maxBookingsPerSlot),
          booking_window_days: parseInt(formData.bookingWindowDays),
          color: formData.color,
          is_active: formData.isActive,
          timezone: formData.timezone
        })
        .eq('id', editingCalendar.id)

      if (updateError) throw updateError

      setIsEditing(false)
      resetForm()
      fetchCalendars()
    } catch (error) {
      console.error('Error updating calendar:', error)
      setError(error instanceof Error ? error.message : 'Failed to update calendar')
    }
  }

  const handleDeleteCalendar = async (calendarId: string) => {
    if (confirm('Are you sure you want to delete this calendar?')) {
      try {
        const { error: deleteError } = await supabase
          .from('calendars')
          .delete()
          .eq('id', calendarId)

        if (deleteError) throw deleteError
        fetchCalendars()
      } catch (error) {
        console.error('Error deleting calendar:', error)
        setError(error instanceof Error ? error.message : 'Failed to delete calendar')
      }
    }
  }

  const handleEditClick = (calendar: CalendarData) => {
    setEditingCalendar(calendar)
    setFormData({
      title: calendar.title,
      description: calendar.description || '',
      thumbnail: calendar.thumbnail || '',
      assignedUserId: calendar.assigned_user_id || '',
      slotDuration: calendar.slot_duration.toString(),
      meetingTypes: calendar.meeting_type,
      defaultLocation: calendar.default_location || '',
      bufferTime: calendar.buffer_time.toString(),
      maxBookingsPerDay: calendar.max_bookings_per_day?.toString() || '',
      maxBookingsPerSlot: calendar.max_bookings_per_slot?.toString() || '1',
      bookingWindowDays: calendar.booking_window_days.toString(),
      color: calendar.color,
      timezone: calendar.timezone,
      isActive: calendar.is_active
    })
    setAvailability(calendar.availability)
    setIsEditing(true)
  }

  const resetForm = () => {
    setFormData({
      title: '',
      description: '',
      thumbnail: '',
      assignedUserId: '',
      slotDuration: '30',
      meetingTypes: ['In-Person', 'Video Call', 'Phone Call'],
      defaultLocation: '',
      bufferTime: '0',
      maxBookingsPerDay: '',
      maxBookingsPerSlot: '1',
      bookingWindowDays: '30',
      color: '#3B82F6',
      timezone: 'Asia/Kolkata',
      isActive: true
    })
    setAvailability(DEFAULT_AVAILABILITY)
    setEditingCalendar(null)
  }

  const handleMeetingTypeToggle = (type: string) => {
    setFormData(prev => ({
      ...prev,
      meetingTypes: prev.meetingTypes.includes(type)
        ? prev.meetingTypes.filter(t => t !== type)
        : [...prev.meetingTypes, type]
    }))
  }

  const handleDayToggle = (day: string) => {
    setAvailability(prev => ({
      ...prev,
      [day]: {
        ...prev[day as keyof typeof prev],
        enabled: !prev[day as keyof typeof prev].enabled
      }
    }))
  }

  const handleAddTimeSlot = (day: string) => {
    setAvailability(prev => ({
      ...prev,
      [day]: {
        ...prev[day as keyof typeof prev],
        slots: [...prev[day as keyof typeof prev].slots, { start: '09:00', end: '17:00' }]
      }
    }))
  }

  const handleRemoveTimeSlot = (day: string, index: number) => {
    setAvailability(prev => ({
      ...prev,
      [day]: {
        ...prev[day as keyof typeof prev],
        slots: prev[day as keyof typeof prev].slots.filter((_, i) => i !== index)
      }
    }))
  }

  const handleTimeSlotChange = (day: string, index: number, field: 'start' | 'end', value: string) => {
    setAvailability(prev => ({
      ...prev,
      [day]: {
        ...prev[day as keyof typeof prev],
        slots: prev[day as keyof typeof prev].slots.map((slot, i) =>
          i === index ? { ...slot, [field]: value } : slot
        )
      }
    }))
  }

  return (
    <div className="space-y-6">
      {!isEditing ? (
        <>
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-semibold text-gray-900">Calendars</h3>
              <p className="text-sm text-gray-600 mt-1">Manage your booking calendars and availability</p>
            </div>
            <Button
              onClick={() => setIsEditing(true)}
              className="flex items-center gap-2"
            >
              <Plus className="w-4 h-4" />
              Add Calendar
            </Button>
          </div>

          {error && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-center space-x-3"
            >
              <AlertCircle className="w-5 h-5 text-red-500" />
              <div>
                <div className="font-medium text-red-800">Error</div>
                <div className="text-sm text-red-600">{error}</div>
              </div>
            </motion.div>
          )}

          {isLoading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-brand-primary"></div>
            </div>
          ) : calendars.length === 0 ? (
            <Card>
              <CardContent className="flex flex-col items-center justify-center py-12">
                <Calendar className="w-12 h-12 text-gray-300 mb-4" />
                <p className="text-gray-500 mb-4">No calendars created yet</p>
                <Button onClick={() => setIsEditing(true)}>
                  <Plus className="w-4 h-4 mr-2" />
                  Create Your First Calendar
                </Button>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {calendars.map((calendar) => (
                <motion.div
                  key={calendar.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  whileHover={{ y: -4 }}
                  transition={{ duration: 0.2 }}
                >
                  <Card className="h-full hover:shadow-xl transition-shadow">
                    <CardContent className="p-6">
                      <div className="flex items-start justify-between mb-4">
                        <div className="flex items-start gap-3">
                          <div
                            className="w-12 h-12 rounded-lg flex items-center justify-center"
                            style={{ backgroundColor: calendar.color + '20' }}
                          >
                            <Calendar className="w-6 h-6" style={{ color: calendar.color }} />
                          </div>
                          <div>
                            <h4 className="font-semibold text-gray-900">{calendar.title}</h4>
                            <p className="text-xs text-gray-500">{calendar.calendar_id}</p>
                          </div>
                        </div>
                        <Badge className={calendar.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}>
                          {calendar.is_active ? 'Active' : 'Inactive'}
                        </Badge>
                      </div>

                      {calendar.description && (
                        <p className="text-sm text-gray-600 mb-4 line-clamp-2">{calendar.description}</p>
                      )}

                      <div className="space-y-2 mb-4">
                        <div className="flex items-center text-sm text-gray-600">
                          <Clock className="w-4 h-4 mr-2" />
                          {calendar.slot_duration} min slots
                        </div>
                        {calendar.default_location && (
                          <div className="flex items-center text-sm text-gray-600">
                            <MapPin className="w-4 h-4 mr-2" />
                            {calendar.default_location}
                          </div>
                        )}
                        <div className="flex items-center gap-1 flex-wrap">
                          {calendar.meeting_type.includes('In-Person') && (
                            <Badge variant="outline" className="text-xs">
                              <Users className="w-3 h-3 mr-1" />
                              In-Person
                            </Badge>
                          )}
                          {calendar.meeting_type.includes('Video Call') && (
                            <Badge variant="outline" className="text-xs">
                              <Video className="w-3 h-3 mr-1" />
                              Video
                            </Badge>
                          )}
                          {calendar.meeting_type.includes('Phone Call') && (
                            <Badge variant="outline" className="text-xs">
                              <Phone className="w-3 h-3 mr-1" />
                              Phone
                            </Badge>
                          )}
                        </div>
                      </div>

                      <div className="flex items-center gap-2 pt-4 border-t">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleEditClick(calendar)}
                          className="flex-1"
                        >
                          <Edit className="w-4 h-4 mr-1" />
                          Edit
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleDeleteCalendar(calendar.id)}
                          className="text-red-600 hover:text-red-700"
                        >
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                </motion.div>
              ))}
            </div>
          )}
        </>
      ) : (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>{editingCalendar ? 'Edit Calendar' : 'Create New Calendar'}</CardTitle>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setIsEditing(false)
                  resetForm()
                }}
              >
                <X className="w-4 h-4" />
              </Button>
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Basic Information */}
            <div>
              <h4 className="font-semibold mb-4">Basic Information</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-2">Title *</label>
                  <Input
                    value={formData.title}
                    onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
                    placeholder="e.g., Sales Consultation"
                  />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-2">Description</label>
                  <textarea
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary"
                    rows={3}
                    value={formData.description}
                    onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                    placeholder="Brief description of this calendar..."
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Thumbnail URL</label>
                  <Input
                    value={formData.thumbnail}
                    onChange={(e) => setFormData(prev => ({ ...prev, thumbnail: e.target.value }))}
                    placeholder="https://example.com/image.jpg"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Color</label>
                  <div className="flex items-center gap-2">
                    <Input
                      type="color"
                      value={formData.color}
                      onChange={(e) => setFormData(prev => ({ ...prev, color: e.target.value }))}
                      className="w-20 h-10"
                    />
                    <Input
                      value={formData.color}
                      onChange={(e) => setFormData(prev => ({ ...prev, color: e.target.value }))}
                      placeholder="#3B82F6"
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Assignment */}
            <div>
              <h4 className="font-semibold mb-4">Assignment</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Assign to Team Member</label>
                  <select
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary"
                    value={formData.assignedUserId}
                    onChange={(e) => setFormData(prev => ({ ...prev, assignedUserId: e.target.value }))}
                  >
                    <option value="">Unassigned</option>
                    {teamMembers.map(member => (
                      <option key={member.id} value={member.id}>
                        {member.full_name} ({member.email})
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Timezone</label>
                  <Input
                    value={formData.timezone}
                    onChange={(e) => setFormData(prev => ({ ...prev, timezone: e.target.value }))}
                    placeholder="Asia/Kolkata"
                  />
                </div>
              </div>
            </div>

            {/* Meeting Configuration */}
            <div>
              <h4 className="font-semibold mb-4">Meeting Configuration</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Slot Duration (minutes) *</label>
                  <Input
                    type="number"
                    value={formData.slotDuration}
                    onChange={(e) => setFormData(prev => ({ ...prev, slotDuration: e.target.value }))}
                    min="5"
                    step="5"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Buffer Time (minutes)</label>
                  <Input
                    type="number"
                    value={formData.bufferTime}
                    onChange={(e) => setFormData(prev => ({ ...prev, bufferTime: e.target.value }))}
                    min="0"
                    step="5"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Max Bookings Per Day</label>
                  <Input
                    type="number"
                    value={formData.maxBookingsPerDay}
                    onChange={(e) => setFormData(prev => ({ ...prev, maxBookingsPerDay: e.target.value }))}
                    placeholder="Unlimited"
                    min="1"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Booking Window (days)</label>
                  <Input
                    type="number"
                    value={formData.bookingWindowDays}
                    onChange={(e) => setFormData(prev => ({ ...prev, bookingWindowDays: e.target.value }))}
                    min="1"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Max Bookings Per Slot *</label>
                  <Input
                    type="number"
                    value={formData.maxBookingsPerSlot}
                    onChange={(e) => setFormData(prev => ({ ...prev, maxBookingsPerSlot: e.target.value }))}
                    min="1"
                  />
                  <p className="text-xs text-gray-500 mt-1">How many appointments can be booked in the same time slot (default: 1)</p>
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-2">Default Location</label>
                  <Input
                    value={formData.defaultLocation}
                    onChange={(e) => setFormData(prev => ({ ...prev, defaultLocation: e.target.value }))}
                    placeholder="e.g., Office, Zoom link, etc."
                  />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-2">Meeting Types *</label>
                  <div className="flex flex-wrap gap-2">
                    {MEETING_TYPES.map(type => (
                      <button
                        key={type}
                        type="button"
                        onClick={() => handleMeetingTypeToggle(type)}
                        className={`px-4 py-2 rounded-lg border-2 transition-colors ${
                          formData.meetingTypes.includes(type)
                            ? 'border-brand-primary bg-brand-primary text-white'
                            : 'border-gray-300 bg-white text-gray-700 hover:border-brand-primary'
                        }`}
                      >
                        {type}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            {/* Availability */}
            <div>
              <h4 className="font-semibold mb-4">Weekly Availability</h4>
              <div className="space-y-3">
                {DAYS_OF_WEEK.map(day => (
                  <div key={day} className="border rounded-lg p-4">
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center gap-3">
                        <input
                          type="checkbox"
                          checked={availability[day as keyof typeof availability].enabled}
                          onChange={() => handleDayToggle(day)}
                          className="w-4 h-4 text-brand-primary focus:ring-brand-primary border-gray-300 rounded"
                        />
                        <label className="font-medium text-gray-900">{DAY_LABELS[day]}</label>
                      </div>
                      {availability[day as keyof typeof availability].enabled && (
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleAddTimeSlot(day)}
                        >
                          <Plus className="w-4 h-4 mr-1" />
                          Add Slot
                        </Button>
                      )}
                    </div>

                    {availability[day as keyof typeof availability].enabled && (
                      <div className="space-y-2 pl-7">
                        {availability[day as keyof typeof availability].slots.map((slot, index) => (
                          <div key={index} className="flex items-center gap-2">
                            <Input
                              type="time"
                              value={slot.start}
                              onChange={(e) => handleTimeSlotChange(day, index, 'start', e.target.value)}
                              className="w-32"
                            />
                            <span className="text-gray-500">to</span>
                            <Input
                              type="time"
                              value={slot.end}
                              onChange={(e) => handleTimeSlotChange(day, index, 'end', e.target.value)}
                              className="w-32"
                            />
                            {availability[day as keyof typeof availability].slots.length > 1 && (
                              <Button
                                size="sm"
                                variant="ghost"
                                onClick={() => handleRemoveTimeSlot(day, index)}
                                className="text-red-600 hover:text-red-700"
                              >
                                <X className="w-4 h-4" />
                              </Button>
                            )}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Status */}
            <div>
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={formData.isActive}
                  onChange={(e) => setFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                  className="w-4 h-4 text-brand-primary focus:ring-brand-primary border-gray-300 rounded"
                />
                <span className="text-sm font-medium text-gray-700">Calendar is Active</span>
              </label>
            </div>

            {/* Actions */}
            <div className="flex items-center gap-3 pt-4 border-t">
              <Button
                onClick={editingCalendar ? handleUpdateCalendar : handleCreateCalendar}
                disabled={!formData.title || formData.meetingTypes.length === 0}
              >
                <Save className="w-4 h-4 mr-2" />
                {editingCalendar ? 'Save Changes' : 'Create Calendar'}
              </Button>
              <Button
                variant="outline"
                onClick={() => {
                  setIsEditing(false)
                  resetForm()
                }}
              >
                Cancel
              </Button>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
