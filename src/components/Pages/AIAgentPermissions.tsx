import React, { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Shield, Save, ArrowLeft, Check, X as XIcon } from 'lucide-react'
import { PageHeader } from '@/components/Common/PageHeader'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { supabase } from '@/lib/supabase'

interface ModulePermission {
  can_view: boolean
  can_create: boolean
  can_edit: boolean
  can_delete: boolean
}

interface Permission {
  [moduleName: string]: ModulePermission
}

const CRM_MODULES = [
  'Leads',
  'Tasks',
  'Appointments',
  'Support Tickets',
  'Notes',
  'Files',
  'Contacts',
  'Members',
  'Affiliates',
  'Expenses',
  'Products',
  'Billing'
]

export function AIAgentPermissions() {
  const navigate = useNavigate()
  const { id } = useParams()
  const [loading, setLoading] = useState(false)
  const [agentName, setAgentName] = useState('')
  const [permissions, setPermissions] = useState<Permission>({})

  useEffect(() => {
    if (id) {
      fetchAgentAndPermissions()
    }
  }, [id])

  const fetchAgentAndPermissions = async () => {
    try {
      setLoading(true)

      const { data: agentData, error: agentError } = await supabase
        .from('ai_agents')
        .select('name')
        .eq('id', id)
        .single()

      if (agentError) throw agentError
      setAgentName(agentData.name)

      const { data: permData, error: permError } = await supabase
        .from('ai_agent_permissions')
        .select('*')
        .eq('agent_id', id)
        .maybeSingle()

      if (permError) throw permError

      const defaultPermissions: Permission = {}
      CRM_MODULES.forEach(module => {
        defaultPermissions[module] = {
          can_view: true,
          can_create: false,
          can_edit: false,
          can_delete: false
        }
      })

      if (permData && permData.permissions) {
        const existingPerms = permData.permissions as Permission
        Object.keys(existingPerms).forEach(module => {
          if (defaultPermissions[module]) {
            defaultPermissions[module] = existingPerms[module]
          }
        })
      }

      setPermissions(defaultPermissions)
    } catch (error) {
      console.error('Error fetching permissions:', error)
      alert('Failed to load permissions')
      navigate('/ai-agents')
    } finally {
      setLoading(false)
    }
  }

  const handlePermissionToggle = (moduleName: string, permissionType: 'can_view' | 'can_create' | 'can_edit' | 'can_delete') => {
    setPermissions(prev => ({
      ...prev,
      [moduleName]: {
        ...prev[moduleName],
        [permissionType]: !prev[moduleName][permissionType]
      }
    }))
  }

  const handleSavePermissions = async () => {
    if (!id) return

    try {
      setLoading(true)

      const { data: existingData } = await supabase
        .from('ai_agent_permissions')
        .select('id')
        .eq('agent_id', id)
        .maybeSingle()

      if (existingData) {
        const { error: updateError } = await supabase
          .from('ai_agent_permissions')
          .update({ permissions })
          .eq('agent_id', id)

        if (updateError) throw updateError
      } else {
        const { error: insertError } = await supabase
          .from('ai_agent_permissions')
          .insert({ agent_id: id, permissions })

        if (insertError) throw insertError
      }

      alert('Permissions saved successfully')
      navigate('/ai-agents')
    } catch (error) {
      console.error('Error saving permissions:', error)
      alert('Failed to save permissions')
    } finally {
      setLoading(false)
    }
  }

  const getPermissionCount = (module: ModulePermission) => {
    return [module.can_view, module.can_create, module.can_edit, module.can_delete].filter(Boolean).length
  }

  return (
    <div className="p-8">
      <div className="mb-6">
        <Button
          variant="outline"
          onClick={() => navigate('/ai-agents')}
          className="mb-4"
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back to Agents
        </Button>
        <PageHeader
          title="Module Access Permissions"
          subtitle={`Configure permissions for ${agentName}`}
          icon={Shield}
        />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <Card>
          <CardHeader>
            <CardTitle>CRM Module Permissions</CardTitle>
            <p className="text-sm text-gray-500 mt-2">
              Control what actions this AI agent can perform in each module. By default, only View is enabled.
            </p>
          </CardHeader>
          <CardContent>
            {loading && permissions.length === 0 ? (
              <div className="text-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
                <p className="text-gray-500 mt-4">Loading permissions...</p>
              </div>
            ) : (
              <>
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Module
                        </th>
                        <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                          View
                        </th>
                        <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Create
                        </th>
                        <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Edit
                        </th>
                        <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Delete
                        </th>
                        <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Permissions
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {CRM_MODULES.map((moduleName) => {
                        const permission = permissions[moduleName]
                        if (!permission) return null

                        return (
                          <tr key={moduleName} className="hover:bg-gray-50">
                            <td className="px-6 py-4 whitespace-nowrap">
                              <div className="text-sm font-medium text-gray-900">
                                {moduleName}
                              </div>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-center">
                              <button
                                onClick={() => handlePermissionToggle(moduleName, 'can_view')}
                                className={`
                                  w-8 h-8 rounded-lg flex items-center justify-center transition-colors
                                  ${permission.can_view
                                    ? 'bg-green-100 text-green-600 hover:bg-green-200'
                                    : 'bg-gray-100 text-gray-400 hover:bg-gray-200'
                                  }
                                `}
                              >
                                {permission.can_view ? <Check className="w-5 h-5" /> : <XIcon className="w-5 h-5" />}
                              </button>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-center">
                              <button
                                onClick={() => handlePermissionToggle(moduleName, 'can_create')}
                                className={`
                                  w-8 h-8 rounded-lg flex items-center justify-center transition-colors
                                  ${permission.can_create
                                    ? 'bg-blue-100 text-blue-600 hover:bg-blue-200'
                                    : 'bg-gray-100 text-gray-400 hover:bg-gray-200'
                                  }
                                `}
                              >
                                {permission.can_create ? <Check className="w-5 h-5" /> : <XIcon className="w-5 h-5" />}
                              </button>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-center">
                              <button
                                onClick={() => handlePermissionToggle(moduleName, 'can_edit')}
                                className={`
                                  w-8 h-8 rounded-lg flex items-center justify-center transition-colors
                                  ${permission.can_edit
                                    ? 'bg-yellow-100 text-yellow-600 hover:bg-yellow-200'
                                    : 'bg-gray-100 text-gray-400 hover:bg-gray-200'
                                  }
                                `}
                              >
                                {permission.can_edit ? <Check className="w-5 h-5" /> : <XIcon className="w-5 h-5" />}
                              </button>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-center">
                              <button
                                onClick={() => handlePermissionToggle(moduleName, 'can_delete')}
                                className={`
                                  w-8 h-8 rounded-lg flex items-center justify-center transition-colors
                                  ${permission.can_delete
                                    ? 'bg-red-100 text-red-600 hover:bg-red-200'
                                    : 'bg-gray-100 text-gray-400 hover:bg-gray-200'
                                  }
                                `}
                              >
                                {permission.can_delete ? <Check className="w-5 h-5" /> : <XIcon className="w-5 h-5" />}
                              </button>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-center">
                              <span className="text-sm text-gray-500">
                                {getPermissionCount(permission)}/4
                              </span>
                            </td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                </div>

                <div className="flex gap-4 mt-6 pt-6 border-t">
                  <Button
                    onClick={handleSavePermissions}
                    disabled={loading}
                    className="flex-1"
                  >
                    {loading ? (
                      <>
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                        Saving...
                      </>
                    ) : (
                      <>
                        <Save className="w-4 h-4 mr-2" />
                        Save Permissions
                      </>
                    )}
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => navigate('/ai-agents')}
                    disabled={loading}
                  >
                    Cancel
                  </Button>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </motion.div>
    </div>
  )
}
