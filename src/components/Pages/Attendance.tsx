import React, { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Clock, Camera, MapPin, CheckCircle, Calendar, User, LogOut, Plus, X, ChevronRight, ArrowLeft } from 'lucide-react'
import { PageHeader } from '@/components/Common/PageHeader'
import { KPICard } from '@/components/Common/KPICard'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { supabase } from '@/lib/supabase'
import { format } from 'date-fns'

interface AttendanceRecord {
  id: string
  admin_user_id: string
  date: string
  check_in_time: string
  check_out_time: string | null
  check_in_selfie_url: string | null
  check_in_location: {
    lat: number
    lng: number
    address: string
  } | null
  status: string
  notes: string | null
  admin_user?: {
    id: string
    full_name: string
    email: string
  }
}

const statusColors: Record<string, string> = {
  present: 'bg-green-100 text-green-800',
  absent: 'bg-red-100 text-red-800',
  late: 'bg-yellow-100 text-yellow-800',
  half_day: 'bg-blue-100 text-blue-800'
}

export function Attendance() {
  const [attendance, setAttendance] = useState<AttendanceRecord[]>([])
  const [teamMembers, setTeamMembers] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [showMarkModal, setShowMarkModal] = useState(false)
  const [selectedMember, setSelectedMember] = useState('')
  const [selfieDataUrl, setSelfieDataUrl] = useState<string | null>(null)
  const [isCameraActive, setIsCameraActive] = useState(false)
  const [location, setLocation] = useState<{ lat: number; lng: number; address: string } | null>(null)
  const [selectedRecord, setSelectedRecord] = useState<AttendanceRecord | null>(null)
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const streamRef = useRef<MediaStream | null>(null)

  useEffect(() => {
    fetchAttendance()
    fetchTeamMembers()
  }, [])

  useEffect(() => {
    return () => {
      stopCamera()
    }
  }, [])

  const fetchAttendance = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('attendance')
        .select(`
          *,
          admin_user:admin_users(id, full_name, email)
        `)
        .order('date', { ascending: false })
        .order('check_in_time', { ascending: false })

      if (error) {
        console.error('Supabase error:', error)
        alert(`Error loading attendance: ${error.message}`)
        throw error
      }

      console.log('Fetched attendance records:', data)
      setAttendance(data || [])
    } catch (err: any) {
      console.error('Error fetching attendance:', err)
      alert(`Failed to load attendance records: ${err.message || 'Unknown error'}`)
    } finally {
      setLoading(false)
    }
  }

  const fetchTeamMembers = async () => {
    try {
      const { data, error } = await supabase
        .from('admin_users')
        .select('id, full_name, email, role')
        .order('full_name', { ascending: true })

      if (error) throw error
      setTeamMembers(data || [])
    } catch (err) {
      console.error('Error fetching team members:', err)
    }
  }

  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: 'user',
          width: { ideal: 1280 },
          height: { ideal: 720 }
        },
        audio: false
      })

      if (videoRef.current) {
        videoRef.current.srcObject = stream
        streamRef.current = stream

        videoRef.current.onloadedmetadata = () => {
          videoRef.current?.play().catch(err => {
            console.error('Error playing video:', err)
          })
        }

        setIsCameraActive(true)
      }
    } catch (err) {
      console.error('Error accessing camera:', err)
      alert('Failed to access camera. Please allow camera permissions.')
    }
  }

  const stopCamera = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop())
      streamRef.current = null
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null
    }
    setIsCameraActive(false)
  }

  const captureSelfie = () => {
    if (videoRef.current && canvasRef.current) {
      const video = videoRef.current
      const canvas = canvasRef.current

      canvas.width = video.videoWidth
      canvas.height = video.videoHeight

      const ctx = canvas.getContext('2d')
      if (ctx) {
        ctx.drawImage(video, 0, 0)
        const dataUrl = canvas.toDataURL('image/jpeg', 0.8)
        setSelfieDataUrl(dataUrl)
        stopCamera()
      }
    }
  }

  const getCurrentLocation = () => {
    return new Promise<{ lat: number; lng: number; address: string }>((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('Geolocation not supported'))
        return
      }

      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const lat = position.coords.latitude
          const lng = position.coords.longitude

          try {
            const response = await fetch(
              `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`
            )
            const data = await response.json()
            const address = data.display_name || `${lat}, ${lng}`

            resolve({ lat, lng, address })
          } catch {
            resolve({ lat, lng, address: `${lat}, ${lng}` })
          }
        },
        (error) => {
          reject(error)
        }
      )
    })
  }

  const handleMarkAttendance = async () => {
    if (!selectedMember) {
      alert('Please select an employee')
      return
    }

    if (!selfieDataUrl) {
      alert('Please capture a selfie')
      return
    }

    try {
      const currentLocation = await getCurrentLocation()
      setLocation(currentLocation)

      let selfieUrl = selfieDataUrl

      try {
        const { data: integration, error: integrationError } = await supabase
          .from('integrations')
          .select('config')
          .eq('integration_type', 'ghl_api')
          .maybeSingle()

        if (integration?.config?.accessToken) {
          const accessToken = integration.config.accessToken
          const locationId = integration.config.locationId || 'iDIRFjdZBWH7SqBzTowc'

          const { data: folderAssignment } = await supabase
            .from('media_folder_assignments')
            .select('media_folder_id, media_folders!inner(ghl_folder_id, folder_name)')
            .eq('trigger_event', 'ATTENDANCE_CHECKIN')
            .eq('module', 'Attendance')
            .maybeSingle()

          const ghlFolderId = folderAssignment?.media_folders?.ghl_folder_id

          if (!ghlFolderId) {
            console.log('No GHL folder configured for attendance check-ins, using data URL')
          } else {
            let { data: attendanceFolder } = await supabase
              .from('media_folders')
              .select('id')
              .eq('ghl_folder_id', ghlFolderId)
              .maybeSingle()

            if (!attendanceFolder) {
              const { data: newFolder, error: folderError } = await supabase
                .from('media_folders')
                .insert({
                  folder_name: folderAssignment?.media_folders?.folder_name || 'Attendance',
                  ghl_folder_id: ghlFolderId,
                  parent_id: null,
                  location_id: locationId
                })
                .select('id')
                .single()

              if (!folderError && newFolder) {
                attendanceFolder = newFolder
              }
            }

            const response = await fetch(selfieDataUrl)
            const blob = await response.blob()

            const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
            const fileName = `attendance-${selectedMember}-${timestamp}.jpg`
            const file = new File([blob], fileName, { type: 'image/jpeg' })

            const formData = new FormData()
            formData.append('file', file)
            formData.append('name', fileName)
            formData.append('parentId', ghlFolderId)

            const uploadResponse = await fetch('https://services.leadconnectorhq.com/medias/upload-file', {
              method: 'POST',
              headers: {
                'Accept': 'application/json',
                'Version': '2021-07-28',
                'Authorization': `Bearer ${accessToken.trim()}`
              },
              body: formData
            })

            if (uploadResponse.ok) {
              const ghlFile = await uploadResponse.json()
              selfieUrl = ghlFile.url || ghlFile.fileUrl || selfieDataUrl

              await supabase.from('media_files').insert({
                file_name: fileName,
                file_url: selfieUrl,
                file_type: 'image/jpeg',
                file_size: file.size,
                ghl_file_id: ghlFile._id || ghlFile.id,
                folder_id: attendanceFolder?.id || null,
                location_id: locationId,
                thumbnail_url: ghlFile.thumbnailUrl || null,
                uploaded_by: selectedMember
              })
            } else {
              console.error('Failed to upload to GHL, using data URL')
            }
          }
        }
      } catch (uploadErr) {
        console.error('Error uploading selfie to GHL:', uploadErr)
      }

      const { error } = await supabase
        .from('attendance')
        .insert({
          admin_user_id: selectedMember,
          date: format(new Date(), 'yyyy-MM-dd'),
          check_in_time: new Date().toISOString(),
          check_in_selfie_url: selfieUrl,
          check_in_location: currentLocation,
          status: 'present'
        })

      if (error) {
        if (error.code === '23505') {
          alert('Attendance already marked for today')
        } else {
          throw error
        }
        return
      }

      alert('Attendance marked successfully')
      fetchAttendance()
      handleCloseModal()
    } catch (err) {
      console.error('Error marking attendance:', err)
      alert('Failed to mark attendance')
    }
  }

  const handleCheckOut = async (attendanceId: string) => {
    if (!confirm('Mark check-out for this attendance record?')) return

    try {
      const { error } = await supabase
        .from('attendance')
        .update({
          check_out_time: new Date().toISOString()
        })
        .eq('id', attendanceId)

      if (error) throw error

      alert('Check-out marked successfully')
      fetchAttendance()
    } catch (err) {
      console.error('Error marking check-out:', err)
      alert('Failed to mark check-out')
    }
  }

  const handleCloseModal = () => {
    setShowMarkModal(false)
    setSelectedMember('')
    setSelfieDataUrl(null)
    setLocation(null)
    stopCamera()
  }

  const totalPresent = attendance.filter(a =>
    a.date === format(new Date(), 'yyyy-MM-dd') && a.status === 'present'
  ).length
  const totalLate = attendance.filter(a =>
    a.date === format(new Date(), 'yyyy-MM-dd') && a.status === 'late'
  ).length
  const totalAbsent = teamMembers.length - totalPresent - totalLate

  return (
    <>
      {/* Desktop View */}
      <div className="hidden md:block p-8 space-y-8">
        <PageHeader
          title="Attendance Management"
          subtitle="Track and manage team attendance"
        />

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <KPICard
            title="Present Today"
            value={totalPresent.toString()}
            icon={CheckCircle}
            category="success"
          />
          <KPICard
            title="Late Today"
            value={totalLate.toString()}
            icon={Clock}
            category="warning"
          />
          <KPICard
            title="Absent Today"
            value={totalAbsent.toString()}
            icon={User}
            category="warning"
          />
          <KPICard
            title="Total Staff"
            value={teamMembers.length.toString()}
            icon={User}
            category="primary"
          />
        </div>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>Attendance Records</CardTitle>
            <Button onClick={() => setShowMarkModal(true)}>
              <Plus className="w-4 h-4 mr-2" />
              Mark Attendance
            </Button>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-4 font-medium">Member</th>
                    <th className="text-left py-3 px-4 font-medium">Date</th>
                    <th className="text-left py-3 px-4 font-medium">Check In</th>
                    <th className="text-left py-3 px-4 font-medium">Check Out</th>
                    <th className="text-left py-3 px-4 font-medium">Selfie</th>
                    <th className="text-left py-3 px-4 font-medium">Location</th>
                    <th className="text-left py-3 px-4 font-medium">Status</th>
                    <th className="text-left py-3 px-4 font-medium">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                    <tr>
                      <td colSpan={8} className="text-center py-8 text-gray-500">
                        Loading...
                      </td>
                    </tr>
                  ) : attendance.length === 0 ? (
                    <tr>
                      <td colSpan={8} className="text-center py-8 text-gray-500">
                        No attendance records found
                      </td>
                    </tr>
                  ) : (
                    attendance.map((record) => (
                      <tr key={record.id} className="border-b hover:bg-gray-50">
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-3">
                            <Avatar>
                              <AvatarFallback>
                                {record.admin_user?.full_name?.charAt(0) || '?'}
                              </AvatarFallback>
                            </Avatar>
                            <div>
                              <div className="font-medium">{record.admin_user?.full_name || 'Unknown'}</div>
                              <div className="text-sm text-gray-500">{record.admin_user?.email || 'No email'}</div>
                            </div>
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-2">
                            <Calendar className="w-4 h-4 text-gray-400" />
                            {format(new Date(record.date), 'dd/MM/yyyy')}
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-2">
                            <Clock className="w-4 h-4 text-gray-400" />
                            {format(new Date(record.check_in_time), 'HH:mm')}
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          {record.check_out_time ? (
                            <div className="flex items-center gap-2">
                              <Clock className="w-4 h-4 text-gray-400" />
                              {format(new Date(record.check_out_time), 'HH:mm')}
                            </div>
                          ) : (
                            <span className="text-gray-400">Not checked out</span>
                          )}
                        </td>
                        <td className="py-3 px-4">
                          {record.check_in_selfie_url ? (
                            <img
                              src={record.check_in_selfie_url}
                              alt="Selfie"
                              className="w-12 h-12 rounded-full object-cover cursor-pointer"
                              onClick={() => window.open(record.check_in_selfie_url!, '_blank')}
                            />
                          ) : (
                            <Camera className="w-8 h-8 text-gray-300" />
                          )}
                        </td>
                        <td className="py-3 px-4">
                          {record.check_in_location ? (
                            <div className="flex items-center gap-2 max-w-xs">
                              <MapPin className="w-4 h-4 text-gray-400 flex-shrink-0" />
                              <span className="text-sm truncate" title={record.check_in_location.address}>
                                {record.check_in_location.address}
                              </span>
                            </div>
                          ) : (
                            <span className="text-gray-400">N/A</span>
                          )}
                        </td>
                        <td className="py-3 px-4">
                          <Badge className={statusColors[record.status] || 'bg-gray-100 text-gray-800'}>
                            {record.status}
                          </Badge>
                        </td>
                        <td className="py-3 px-4">
                          {!record.check_out_time && (
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleCheckOut(record.id)}
                            >
                              <LogOut className="w-4 h-4 mr-1" />
                              Check Out
                            </Button>
                          )}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Mobile View - App-like Experience */}
      <div className="md:hidden min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50">
        {/* Mobile Header */}
        <div className="bg-gradient-to-r from-brand-primary to-blue-600 text-white px-4 py-6 shadow-lg">
          <h1 className="text-2xl font-bold mb-1">Attendance</h1>
          <p className="text-blue-100 text-sm">{format(new Date(), 'EEEE, MMMM dd, yyyy')}</p>
        </div>

        {/* Stats Cards */}
        <div className="px-4 -mt-4 mb-4">
          <div className="grid grid-cols-2 gap-3">
            <motion.div
              whileTap={{ scale: 0.95 }}
              className="bg-white rounded-2xl p-4 shadow-lg border border-green-100"
            >
              <div className="flex items-center justify-between mb-2">
                <div className="bg-green-100 p-2 rounded-xl">
                  <CheckCircle className="w-5 h-5 text-green-600" />
                </div>
                <span className="text-2xl font-bold text-green-600">{totalPresent}</span>
              </div>
              <p className="text-xs text-gray-600 font-medium">Present</p>
            </motion.div>

            <motion.div
              whileTap={{ scale: 0.95 }}
              className="bg-white rounded-2xl p-4 shadow-lg border border-yellow-100"
            >
              <div className="flex items-center justify-between mb-2">
                <div className="bg-yellow-100 p-2 rounded-xl">
                  <Clock className="w-5 h-5 text-yellow-600" />
                </div>
                <span className="text-2xl font-bold text-yellow-600">{totalLate}</span>
              </div>
              <p className="text-xs text-gray-600 font-medium">Late</p>
            </motion.div>

            <motion.div
              whileTap={{ scale: 0.95 }}
              className="bg-white rounded-2xl p-4 shadow-lg border border-red-100"
            >
              <div className="flex items-center justify-between mb-2">
                <div className="bg-red-100 p-2 rounded-xl">
                  <User className="w-5 h-5 text-red-600" />
                </div>
                <span className="text-2xl font-bold text-red-600">{totalAbsent}</span>
              </div>
              <p className="text-xs text-gray-600 font-medium">Absent</p>
            </motion.div>

            <motion.div
              whileTap={{ scale: 0.95 }}
              className="bg-white rounded-2xl p-4 shadow-lg border border-blue-100"
            >
              <div className="flex items-center justify-between mb-2">
                <div className="bg-blue-100 p-2 rounded-xl">
                  <User className="w-5 h-5 text-blue-600" />
                </div>
                <span className="text-2xl font-bold text-blue-600">{teamMembers.length}</span>
              </div>
              <p className="text-xs text-gray-600 font-medium">Total Staff</p>
            </motion.div>
          </div>
        </div>

        {/* Mark Attendance Button */}
        <div className="px-4 mb-4">
          <motion.button
            whileTap={{ scale: 0.98 }}
            onClick={() => setShowMarkModal(true)}
            className="w-full bg-gradient-to-r from-brand-primary to-blue-600 text-white rounded-2xl py-4 px-6 shadow-lg flex items-center justify-center gap-3 font-semibold"
          >
            <Plus className="w-5 h-5" />
            Mark Attendance
          </motion.button>
        </div>

        {/* Recent Records */}
        <div className="px-4 pb-20">
          <h2 className="text-lg font-bold text-gray-800 mb-3">Recent Records</h2>
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-brand-primary"></div>
            </div>
          ) : attendance.length === 0 ? (
            <div className="text-center py-12">
              <Calendar className="w-12 h-12 text-gray-300 mx-auto mb-2" />
              <p className="text-gray-500 text-sm">No records yet</p>
            </div>
          ) : (
            <div className="space-y-3">
              {attendance.map((record) => (
                <motion.div
                  key={record.id}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => setSelectedRecord(record)}
                  className="bg-white rounded-2xl p-4 shadow-md active:shadow-lg transition-shadow"
                >
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <div className="relative">
                        <Avatar className="w-12 h-12">
                          <AvatarFallback className="bg-gradient-to-br from-brand-primary to-blue-600 text-white text-lg">
                            {record.admin_user?.full_name?.charAt(0) || '?'}
                          </AvatarFallback>
                        </Avatar>
                        {record.check_in_selfie_url && (
                          <div className="absolute -bottom-1 -right-1 bg-green-500 rounded-full p-1">
                            <Camera className="w-3 h-3 text-white" />
                          </div>
                        )}
                      </div>
                      <div>
                        <p className="font-semibold text-gray-800">{record.admin_user?.full_name || 'Unknown'}</p>
                        <p className="text-xs text-gray-500">{format(new Date(record.date), 'MMM dd, yyyy')}</p>
                      </div>
                    </div>
                    <ChevronRight className="w-5 h-5 text-gray-400" />
                  </div>

                  <div className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2 text-gray-600">
                      <Clock className="w-4 h-4" />
                      <span className="font-medium">{format(new Date(record.check_in_time), 'HH:mm')}</span>
                    </div>
                    {record.check_out_time ? (
                      <div className="flex items-center gap-2 text-gray-600">
                        <LogOut className="w-4 h-4" />
                        <span className="font-medium">{format(new Date(record.check_out_time), 'HH:mm')}</span>
                      </div>
                    ) : (
                      <Badge className="bg-yellow-100 text-yellow-800 text-xs">Active</Badge>
                    )}
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Detail Modal for Mobile */}
      <AnimatePresence>
        {selectedRecord && (
          <motion.div
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'spring', damping: 30, stiffness: 300 }}
            className="md:hidden fixed inset-0 bg-white z-50 overflow-y-auto"
          >
            <div className="bg-gradient-to-r from-brand-primary to-blue-600 text-white px-4 py-6 sticky top-0 z-10">
              <div className="flex items-center gap-3">
                <button onClick={() => setSelectedRecord(null)}>
                  <ArrowLeft className="w-6 h-6" />
                </button>
                <h2 className="text-xl font-bold">Attendance Details</h2>
              </div>
            </div>

            <div className="p-4 space-y-4">
              <div className="bg-white rounded-2xl shadow-lg p-6">
                <div className="flex items-center gap-4 mb-4">
                  {selectedRecord.check_in_selfie_url ? (
                    <img
                      src={selectedRecord.check_in_selfie_url}
                      alt="Selfie"
                      className="w-20 h-20 rounded-2xl object-cover"
                    />
                  ) : (
                    <div className="w-20 h-20 rounded-2xl bg-gray-100 flex items-center justify-center">
                      <Camera className="w-8 h-8 text-gray-400" />
                    </div>
                  )}
                  <div>
                    <p className="text-lg font-bold text-gray-800">{selectedRecord.admin_user?.full_name}</p>
                    <p className="text-sm text-gray-500">{selectedRecord.admin_user?.email}</p>
                  </div>
                </div>

                <div className="space-y-3">
                  <div className="flex items-center justify-between py-3 border-b">
                    <div className="flex items-center gap-3">
                      <div className="bg-blue-100 p-2 rounded-xl">
                        <Calendar className="w-4 h-4 text-blue-600" />
                      </div>
                      <span className="text-sm text-gray-600">Date</span>
                    </div>
                    <span className="font-semibold text-gray-800">
                      {format(new Date(selectedRecord.date), 'MMM dd, yyyy')}
                    </span>
                  </div>

                  <div className="flex items-center justify-between py-3 border-b">
                    <div className="flex items-center gap-3">
                      <div className="bg-green-100 p-2 rounded-xl">
                        <Clock className="w-4 h-4 text-green-600" />
                      </div>
                      <span className="text-sm text-gray-600">Check In</span>
                    </div>
                    <span className="font-semibold text-gray-800">
                      {format(new Date(selectedRecord.check_in_time), 'hh:mm a')}
                    </span>
                  </div>

                  <div className="flex items-center justify-between py-3 border-b">
                    <div className="flex items-center gap-3">
                      <div className="bg-orange-100 p-2 rounded-xl">
                        <LogOut className="w-4 h-4 text-orange-600" />
                      </div>
                      <span className="text-sm text-gray-600">Check Out</span>
                    </div>
                    <span className="font-semibold text-gray-800">
                      {selectedRecord.check_out_time
                        ? format(new Date(selectedRecord.check_out_time), 'hh:mm a')
                        : 'Not yet'
                      }
                    </span>
                  </div>

                  {selectedRecord.check_in_location && (
                    <div className="py-3">
                      <div className="flex items-center gap-3 mb-2">
                        <div className="bg-purple-100 p-2 rounded-xl">
                          <MapPin className="w-4 h-4 text-purple-600" />
                        </div>
                        <span className="text-sm text-gray-600">Location</span>
                      </div>
                      <p className="text-sm text-gray-700 ml-12 leading-relaxed">
                        {selectedRecord.check_in_location.address}
                      </p>
                    </div>
                  )}
                </div>

                {!selectedRecord.check_out_time && (
                  <motion.button
                    whileTap={{ scale: 0.95 }}
                    onClick={() => {
                      handleCheckOut(selectedRecord.id)
                      setSelectedRecord(null)
                    }}
                    className="mt-4 w-full bg-gradient-to-r from-orange-500 to-red-500 text-white rounded-xl py-3 font-semibold flex items-center justify-center gap-2"
                  >
                    <LogOut className="w-5 h-5" />
                    Check Out
                  </motion.button>
                )}
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Desktop Mark Attendance Modal */}
      {showMarkModal && (
        <div className="hidden md:flex fixed inset-0 bg-black bg-opacity-50 items-center justify-center z-50 p-4">
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto"
          >
            <div className="p-6 border-b flex justify-between items-center">
              <h2 className="text-2xl font-bold">Mark Attendance</h2>
              <button onClick={handleCloseModal} className="text-gray-500 hover:text-gray-700">
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="p-6 space-y-6">
              <div>
                <label className="block text-sm font-medium mb-2">Employee Name *</label>
                <select
                  value={selectedMember}
                  onChange={(e) => setSelectedMember(e.target.value)}
                  className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select employee</option>
                  {teamMembers.map((member) => (
                    <option key={member.id} value={member.id}>
                      {member.full_name} - {member.role}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Selfie Image <span className="text-red-500">*</span>
                </label>

                {!selfieDataUrl ? (
                  <div className="space-y-4">
                    <div
                      className="relative bg-gray-900 rounded-lg overflow-hidden"
                      style={{ aspectRatio: '4/3' }}
                    >
                      <video
                        ref={videoRef}
                        autoPlay
                        playsInline
                        muted
                        className="w-full h-full object-cover"
                      />
                      {!isCameraActive && (
                        <div className="absolute inset-0 flex items-center justify-center bg-gray-800">
                          <div className="text-center text-white">
                            <Camera className="w-12 h-12 mx-auto mb-3 opacity-50" />
                            <p className="text-sm">Camera will appear here</p>
                          </div>
                        </div>
                      )}
                    </div>

                    <div className="flex gap-3">
                      <Button
                        type="button"
                        onClick={isCameraActive ? captureSelfie : startCamera}
                        className="flex-1 bg-green-600 hover:bg-green-700"
                      >
                        <Camera className="w-4 h-4 mr-2" />
                        {isCameraActive ? 'Capture Photo' : 'Start Camera'}
                      </Button>

                      {isCameraActive && (
                        <Button
                          type="button"
                          variant="outline"
                          onClick={stopCamera}
                          className="px-8"
                        >
                          Cancel
                        </Button>
                      )}
                    </div>

                    <canvas ref={canvasRef} className="hidden" />
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div
                      className="relative bg-gray-100 rounded-lg overflow-hidden"
                      style={{ aspectRatio: '4/3' }}
                    >
                      <img
                        src={selfieDataUrl}
                        alt="Captured selfie"
                        className="w-full h-full object-cover"
                      />
                    </div>

                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => {
                        setSelfieDataUrl(null)
                        startCamera()
                      }}
                      className="w-full"
                    >
                      <Camera className="w-4 h-4 mr-2" />
                      Retake Photo
                    </Button>
                  </div>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">Date</label>
                <div className="px-4 py-2 bg-gray-100 rounded-lg">
                  {format(new Date(), 'MMMM dd, yyyy')}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">Time</label>
                <div className="px-4 py-2 bg-gray-100 rounded-lg">
                  {format(new Date(), 'hh:mm a')}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">GPS Location</label>
                <div className="px-4 py-2 bg-gray-100 rounded-lg flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-gray-500" />
                  <span className="text-sm">Will be captured when submitting</span>
                </div>
              </div>
            </div>

            <div className="p-6 border-t flex gap-3">
              <Button onClick={handleCloseModal} variant="outline" className="flex-1">
                Cancel
              </Button>
              <Button onClick={handleMarkAttendance} className="flex-1">
                Mark Attendance
              </Button>
            </div>
          </motion.div>
        </div>
      )}

      {/* Mobile Mark Attendance Page */}
      <AnimatePresence>
        {showMarkModal && (
          <motion.div
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'spring', damping: 30, stiffness: 300 }}
            className="md:hidden fixed inset-0 bg-white z-[60] overflow-y-auto"
          >
            <div className="bg-gradient-to-r from-brand-primary to-blue-600 text-white px-4 py-6 sticky top-0 z-10">
              <div className="flex items-center gap-3 mb-4">
                <button onClick={handleCloseModal}>
                  <ArrowLeft className="w-6 h-6" />
                </button>
                <h2 className="text-xl font-bold">Mark Attendance</h2>
              </div>
            </div>

            <div className="p-4 pb-24 space-y-6">
              {/* Employee Selection */}
              <div className="bg-white rounded-2xl shadow-lg p-6">
                <label className="block text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
                  <User className="w-4 h-4" />
                  Select Employee *
                </label>
                <select
                  value={selectedMember}
                  onChange={(e) => setSelectedMember(e.target.value)}
                  className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="">Choose employee</option>
                  {teamMembers.map((member) => (
                    <option key={member.id} value={member.id}>
                      {member.full_name} - {member.role}
                    </option>
                  ))}
                </select>
              </div>

              {/* Camera Section */}
              <div className="bg-white rounded-2xl shadow-lg p-6">
                <label className="block text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
                  <Camera className="w-4 h-4" />
                  Selfie Image *
                </label>

                {!selfieDataUrl ? (
                  <div className="space-y-4">
                    <div
                      className="relative bg-gray-900 rounded-2xl overflow-hidden"
                      style={{ aspectRatio: '4/3' }}
                    >
                      <video
                        ref={videoRef}
                        autoPlay
                        playsInline
                        muted
                        className="w-full h-full object-cover"
                      />
                      {!isCameraActive && (
                        <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-gray-800 to-gray-900">
                          <div className="text-center text-white">
                            <Camera className="w-16 h-16 mx-auto mb-4 opacity-50" />
                            <p className="text-sm font-medium">Camera will appear here</p>
                          </div>
                        </div>
                      )}
                    </div>

                    <div className="flex gap-3">
                      <motion.button
                        whileTap={{ scale: 0.95 }}
                        onClick={isCameraActive ? captureSelfie : startCamera}
                        className="flex-1 bg-gradient-to-r from-green-500 to-emerald-600 text-white rounded-xl py-3 font-semibold flex items-center justify-center gap-2"
                      >
                        <Camera className="w-5 h-5" />
                        {isCameraActive ? 'Capture Photo' : 'Start Camera'}
                      </motion.button>

                      {isCameraActive && (
                        <motion.button
                          whileTap={{ scale: 0.95 }}
                          onClick={stopCamera}
                          className="px-6 border-2 border-gray-300 rounded-xl font-semibold text-gray-700"
                        >
                          Cancel
                        </motion.button>
                      )}
                    </div>

                    <canvas ref={canvasRef} className="hidden" />
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div
                      className="relative bg-gray-100 rounded-2xl overflow-hidden"
                      style={{ aspectRatio: '4/3' }}
                    >
                      <img
                        src={selfieDataUrl}
                        alt="Captured selfie"
                        className="w-full h-full object-cover"
                      />
                      <div className="absolute top-3 right-3">
                        <div className="bg-green-500 rounded-full p-2">
                          <CheckCircle className="w-6 h-6 text-white" />
                        </div>
                      </div>
                    </div>

                    <motion.button
                      whileTap={{ scale: 0.95 }}
                      onClick={() => {
                        setSelfieDataUrl(null)
                        startCamera()
                      }}
                      className="w-full border-2 border-gray-300 rounded-xl py-3 font-semibold text-gray-700 flex items-center justify-center gap-2"
                    >
                      <Camera className="w-5 h-5" />
                      Retake Photo
                    </motion.button>
                  </div>
                )}
              </div>

              {/* Date & Time Info */}
              <div className="bg-white rounded-2xl shadow-lg p-6 space-y-4">
                <div className="flex items-center justify-between py-3 border-b">
                  <div className="flex items-center gap-3">
                    <div className="bg-blue-100 p-2 rounded-xl">
                      <Calendar className="w-4 h-4 text-blue-600" />
                    </div>
                    <span className="text-sm font-medium text-gray-600">Date</span>
                  </div>
                  <span className="text-sm font-semibold text-gray-800">
                    {format(new Date(), 'MMM dd, yyyy')}
                  </span>
                </div>

                <div className="flex items-center justify-between py-3 border-b">
                  <div className="flex items-center gap-3">
                    <div className="bg-green-100 p-2 rounded-xl">
                      <Clock className="w-4 h-4 text-green-600" />
                    </div>
                    <span className="text-sm font-medium text-gray-600">Time</span>
                  </div>
                  <span className="text-sm font-semibold text-gray-800">
                    {format(new Date(), 'hh:mm a')}
                  </span>
                </div>

                <div className="flex items-center justify-between py-3">
                  <div className="flex items-center gap-3">
                    <div className="bg-purple-100 p-2 rounded-xl">
                      <MapPin className="w-4 h-4 text-purple-600" />
                    </div>
                    <span className="text-sm font-medium text-gray-600">GPS Location</span>
                  </div>
                  <span className="text-xs text-gray-500">Auto-captured</span>
                </div>
              </div>
            </div>

            {/* Fixed Bottom Button */}
            <div className="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 p-4 shadow-lg z-20">
              <motion.button
                whileTap={{ scale: 0.98 }}
                onClick={handleMarkAttendance}
                className="w-full bg-gradient-to-r from-brand-primary to-blue-600 text-white rounded-2xl py-4 font-bold text-lg shadow-lg flex items-center justify-center gap-2"
              >
                <CheckCircle className="w-5 h-5" />
                Mark Attendance
              </motion.button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  )
}
