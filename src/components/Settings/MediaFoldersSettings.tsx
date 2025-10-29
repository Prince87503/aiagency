import React, { useState, useEffect } from 'react'
import { FolderOpen, Edit, Save, X } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { supabase } from '@/lib/supabase'
import { Badge } from '@/components/ui/badge'

interface MediaFolder {
  id: string
  folder_name: string
  ghl_folder_id: string | null
}

interface MediaFolderAssignment {
  id: string
  trigger_event: string
  module: string
  media_folder_id: string | null
}

const moduleColors: Record<string, string> = {
  'Attendance': 'bg-blue-100 text-blue-800',
  'Expenses': 'bg-green-100 text-green-800',
  'Team': 'bg-purple-100 text-purple-800',
  'Members': 'bg-orange-100 text-orange-800',
  'Leads': 'bg-pink-100 text-pink-800'
}

export function MediaFoldersSettings() {
  const [assignments, setAssignments] = useState<MediaFolderAssignment[]>([])
  const [mediaFolders, setMediaFolders] = useState<MediaFolder[]>([])
  const [loading, setLoading] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editingFolderId, setEditingFolderId] = useState<string | null>(null)

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)

      const [assignmentsResult, foldersResult] = await Promise.all([
        supabase
          .from('media_folder_assignments')
          .select('*')
          .order('module', { ascending: true }),
        supabase
          .from('media_folders')
          .select('id, folder_name, ghl_folder_id')
          .order('folder_name', { ascending: true })
      ])

      if (assignmentsResult.error) throw assignmentsResult.error
      if (foldersResult.error) throw foldersResult.error

      setAssignments(assignmentsResult.data || [])
      setMediaFolders(foldersResult.data || [])
    } catch (error) {
      console.error('Failed to fetch data:', error)
      alert('Failed to load media folder assignments')
    } finally {
      setLoading(false)
    }
  }

  const handleEdit = (assignment: MediaFolderAssignment) => {
    setEditingId(assignment.id)
    setEditingFolderId(assignment.media_folder_id || '__none__')
  }

  const handleSave = async (assignmentId: string) => {
    try {
      setLoading(true)

      const { error } = await supabase
        .from('media_folder_assignments')
        .update({
          media_folder_id: editingFolderId === '__none__' ? null : editingFolderId || null,
          updated_at: new Date().toISOString()
        })
        .eq('id', assignmentId)

      if (error) throw error

      await fetchData()
      setEditingId(null)
      setEditingFolderId(null)
    } catch (error) {
      console.error('Failed to update assignment:', error)
      alert('Failed to update media folder assignment')
    } finally {
      setLoading(false)
    }
  }

  const handleCancel = () => {
    setEditingId(null)
    setEditingFolderId(null)
  }

  const formatTriggerEvent = (event: string) => {
    return event
      .split('_')
      .map(word => word.charAt(0) + word.slice(1).toLowerCase())
      .join(' ')
  }

  return (
    <Card className="shadow-xl">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center space-x-2">
            <FolderOpen className="w-5 h-5 text-brand-primary" />
            <span>Media Folder Assignments</span>
          </CardTitle>
        </div>
        <p className="text-sm text-gray-600 mt-2">
          Configure which GHL media folder should be used for files related to specific trigger events.
          This helps organize media files from different modules (Attendance check-ins, Expense receipts, etc.)
        </p>
      </CardHeader>
      <CardContent>
        {loading && assignments.length === 0 ? (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-brand-primary"></div>
            <p className="mt-4 text-gray-600">Loading assignments...</p>
          </div>
        ) : assignments.length === 0 ? (
          <div className="text-center py-12 text-gray-500">
            <FolderOpen className="w-12 h-12 mx-auto mb-4 text-gray-300" />
            <p>No media folder assignments found</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-left py-3 px-4 font-semibold text-brand-text">Trigger Event</th>
                  <th className="text-left py-3 px-4 font-semibold text-brand-text">Module</th>
                  <th className="text-left py-3 px-4 font-semibold text-brand-text">Media Folder</th>
                  <th className="text-right py-3 px-4 font-semibold text-brand-text">Actions</th>
                </tr>
              </thead>
              <tbody>
                {assignments.map((assignment) => {
                  const isEditing = editingId === assignment.id
                  const folder = mediaFolders.find(f => f.id === assignment.media_folder_id)

                  return (
                    <tr
                      key={assignment.id}
                      className="border-b border-gray-100 hover:bg-gray-50 transition-colors"
                    >
                      <td className="py-3 px-4">
                        <div className="font-medium text-gray-900">
                          {formatTriggerEvent(assignment.trigger_event)}
                        </div>
                        <div className="text-xs text-gray-500 font-mono mt-1">
                          {assignment.trigger_event}
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <Badge
                          className={moduleColors[assignment.module] || 'bg-gray-100 text-gray-800'}
                          variant="secondary"
                        >
                          {assignment.module}
                        </Badge>
                      </td>
                      <td className="py-3 px-4">
                        {isEditing ? (
                          <Select
                            value={editingFolderId || '__none__'}
                            onValueChange={setEditingFolderId}
                          >
                            <SelectTrigger className="w-64">
                              <SelectValue placeholder="Select a folder..." />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="__none__">
                                <span className="text-gray-500">No folder assigned</span>
                              </SelectItem>
                              {mediaFolders.map((folder) => (
                                <SelectItem key={folder.id} value={folder.id}>
                                  <div className="flex items-center space-x-2">
                                    <FolderOpen className="w-4 h-4 text-gray-400" />
                                    <span>{folder.folder_name}</span>
                                  </div>
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                        ) : (
                          <div className="flex items-center space-x-2">
                            {folder ? (
                              <>
                                <FolderOpen className="w-4 h-4 text-gray-400" />
                                <span className="text-gray-900">{folder.folder_name}</span>
                              </>
                            ) : (
                              <span className="text-gray-500 italic">No folder assigned</span>
                            )}
                          </div>
                        )}
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center justify-end space-x-2">
                          {isEditing ? (
                            <>
                              <Button
                                size="sm"
                                onClick={() => handleSave(assignment.id)}
                                disabled={loading}
                                className="h-8"
                              >
                                <Save className="w-4 h-4 mr-1" />
                                Save
                              </Button>
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={handleCancel}
                                disabled={loading}
                                className="h-8"
                              >
                                <X className="w-4 h-4 mr-1" />
                                Cancel
                              </Button>
                            </>
                          ) : (
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleEdit(assignment)}
                              className="h-8"
                            >
                              <Edit className="w-4 h-4 mr-1" />
                              Edit
                            </Button>
                          )}
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}

        {mediaFolders.length === 0 && !loading && (
          <div className="mt-4 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <p className="text-sm text-yellow-800">
              <strong>Note:</strong> No media folders found. Please create media folders first in the Media Storage module before assigning them to trigger events.
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
