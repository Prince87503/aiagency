import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Link as LinkIcon, Copy, DollarSign, TrendingUp, Users, LogOut, Mail, Phone, Building, MapPin, User, LayoutDashboard, FileText, HeadphonesIcon, Settings, Menu, X, GraduationCap } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { formatCurrency } from '@/lib/utils'
import { supabase } from '@/lib/supabase'
import { PartnerOTPLogin } from '@/components/Auth/PartnerOTPLogin'
import { ReferralsTable } from '@/components/Partner/ReferralsTable'
import { LearningModule } from '@/components/Partner/LearningModule'

interface Affiliate {
  id: string
  affiliateId: string
  name: string
  email: string
  phone: string
  commissionPct: number
  uniqueLink: string
  referrals: number
  earningsPaid: number
  earningsPending: number
  status: string
  company?: string
  address?: string
  joinedOn: string
  lastActivity: string
}

type PartnerView = 'dashboard' | 'referrals' | 'earnings' | 'learning' | 'resources' | 'support' | 'settings'

export function PartnerPortal() {
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const [affiliate, setAffiliate] = useState<Affiliate | null>(null)
  const [loading, setLoading] = useState(true)
  const [currentView, setCurrentView] = useState<PartnerView>('dashboard')
  const [isSidebarOpen, setIsSidebarOpen] = useState(false)

  useEffect(() => {
    checkSession()
  }, [])

  const checkSession = async () => {
    const sessionData = localStorage.getItem('partner_session')

    if (sessionData) {
      try {
        const { affiliateId, expiresAt } = JSON.parse(sessionData)

        if (new Date(expiresAt) > new Date()) {
          const { data, error: fetchError } = await supabase
            .from('affiliates')
            .select('*')
            .eq('id', affiliateId)
            .maybeSingle()

          if (!fetchError && data && data.status === 'Active') {
            const formattedData: Affiliate = {
              id: data.id,
              affiliateId: data.affiliate_id,
              name: data.name,
              email: data.email,
              phone: data.phone,
              commissionPct: data.commission_pct,
              uniqueLink: data.unique_link,
              referrals: data.referrals,
              earningsPaid: Number(data.earnings_paid),
              earningsPending: Number(data.earnings_pending),
              status: data.status,
              company: data.company,
              address: data.address,
              joinedOn: data.joined_on,
              lastActivity: data.last_activity || 'Never'
            }

            setAffiliate(formattedData)
            setIsLoggedIn(true)
          } else {
            localStorage.removeItem('partner_session')
          }
        } else {
          localStorage.removeItem('partner_session')
        }
      } catch (err) {
        console.error('Session check error:', err)
        localStorage.removeItem('partner_session')
      }
    }

    setLoading(false)
  }

  const handleAuthenticated = async (affiliateId: string) => {
    try {
      setLoading(true)

      const { data, error: fetchError } = await supabase
        .from('affiliates')
        .select('*')
        .eq('id', affiliateId)
        .maybeSingle()

      if (fetchError) throw fetchError

      if (!data) {
        console.error('Affiliate not found')
        return
      }

      const formattedData: Affiliate = {
        id: data.id,
        affiliateId: data.affiliate_id,
        name: data.name,
        email: data.email,
        phone: data.phone,
        commissionPct: data.commission_pct,
        uniqueLink: data.unique_link,
        referrals: data.referrals,
        earningsPaid: Number(data.earnings_paid),
        earningsPending: Number(data.earnings_pending),
        status: data.status,
        company: data.company,
        address: data.address,
        joinedOn: data.joined_on,
        lastActivity: data.last_activity || 'Never'
      }

      setAffiliate(formattedData)
      setIsLoggedIn(true)

      const expiresAt = new Date()
      expiresAt.setDate(expiresAt.getDate() + 30)

      localStorage.setItem('partner_session', JSON.stringify({
        affiliateId: data.id,
        expiresAt: expiresAt.toISOString()
      }))

      await supabase
        .from('affiliates')
        .update({ last_activity: new Date().toISOString() })
        .eq('id', data.id)
    } catch (err) {
      console.error('Login error:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleLogout = () => {
    setIsLoggedIn(false)
    setAffiliate(null)
    localStorage.removeItem('partner_session')
  }

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text)
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 via-white to-green-50">
        <div className="text-center">
          <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-green-500 rounded-full flex items-center justify-center mx-auto mb-4 animate-pulse">
            <Users className="w-8 h-8 text-white" />
          </div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    )
  }

  if (!isLoggedIn) {
    return <PartnerOTPLogin onAuthenticated={handleAuthenticated} />
  }

  if (!affiliate) return null

  const menuItems = [
    { id: 'dashboard' as PartnerView, label: 'Dashboard', icon: LayoutDashboard },
    { id: 'referrals' as PartnerView, label: 'My Referrals', icon: Users },
    { id: 'earnings' as PartnerView, label: 'Earnings', icon: DollarSign },
    { id: 'learning' as PartnerView, label: 'Learning', icon: GraduationCap },
    { id: 'resources' as PartnerView, label: 'Resources', icon: FileText },
    { id: 'support' as PartnerView, label: 'Support', icon: HeadphonesIcon },
    { id: 'settings' as PartnerView, label: 'Settings', icon: Settings },
  ]

  const renderContent = () => {
    switch (currentView) {
      case 'dashboard':
        return renderDashboard()
      case 'referrals':
        return renderReferrals()
      case 'earnings':
        return renderEarnings()
      case 'learning':
        return renderLearning()
      case 'resources':
        return renderResources()
      case 'support':
        return renderSupport()
      case 'settings':
        return renderSettings()
      default:
        return renderDashboard()
    }
  }

  const renderDashboard = () => (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Welcome, {affiliate.name}!</h1>
        <p className="text-gray-600 mt-1">Affiliate ID: {affiliate.affiliateId}</p>
      </div>

      <motion.div
        className="grid grid-cols-1 md:grid-cols-4 gap-6"
        initial="hidden"
        animate="visible"
        variants={{
          hidden: { opacity: 0 },
          visible: {
            opacity: 1,
            transition: { staggerChildren: 0.1 }
          }
        }}
      >
          <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
            <Card className="shadow-xl border-0 bg-gradient-to-br from-blue-500 to-blue-600 text-white">
              <CardContent className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <Users className="w-8 h-8 opacity-80" />
                  <Badge className="bg-white/20 text-white border-0">Total</Badge>
                </div>
                <div className="text-3xl font-bold">{affiliate.referrals}</div>
                <div className="text-blue-100 text-sm">Total Referrals</div>
              </CardContent>
            </Card>
          </motion.div>

          <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
            <Card className="shadow-xl border-0 bg-gradient-to-br from-green-500 to-green-600 text-white">
              <CardContent className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <DollarSign className="w-8 h-8 opacity-80" />
                  <Badge className="bg-white/20 text-white border-0">Paid</Badge>
                </div>
                <div className="text-3xl font-bold">{formatCurrency(affiliate.earningsPaid)}</div>
                <div className="text-green-100 text-sm">Earnings Paid</div>
              </CardContent>
            </Card>
          </motion.div>

          <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
            <Card className="shadow-xl border-0 bg-gradient-to-br from-orange-500 to-orange-600 text-white">
              <CardContent className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <TrendingUp className="w-8 h-8 opacity-80" />
                  <Badge className="bg-white/20 text-white border-0">Pending</Badge>
                </div>
                <div className="text-3xl font-bold">{formatCurrency(affiliate.earningsPending)}</div>
                <div className="text-orange-100 text-sm">Pending Payout</div>
              </CardContent>
            </Card>
          </motion.div>

          <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
            <Card className="shadow-xl border-0 bg-gradient-to-br from-purple-500 to-purple-600 text-white">
              <CardContent className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <TrendingUp className="w-8 h-8 opacity-80" />
                  <Badge className="bg-white/20 text-white border-0">Rate</Badge>
                </div>
                <div className="text-3xl font-bold">{affiliate.commissionPct}%</div>
                <div className="text-purple-100 text-sm">Commission Rate</div>
              </CardContent>
            </Card>
          </motion.div>
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.2 }}
          >
            <Card className="shadow-xl">
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <LinkIcon className="w-5 h-5 text-blue-600" />
                  <span>Your Referral Link</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="p-4 bg-gray-50 rounded-lg mb-4">
                  <div className="flex items-center space-x-2">
                    <Input
                      value={affiliate.uniqueLink}
                      readOnly
                      className="flex-1 bg-white"
                    />
                    <Button
                      onClick={() => copyToClipboard(affiliate.uniqueLink)}
                      className="bg-gradient-to-r from-blue-600 to-green-600"
                    >
                      <Copy className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
                <p className="text-sm text-gray-600">
                  Share this link with potential customers. You'll earn {affiliate.commissionPct}% commission on every successful referral!
                </p>
              </CardContent>
            </Card>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 }}
          >
            <Card className="shadow-xl">
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <User className="w-5 h-5 text-blue-600" />
                  <span>Account Information</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex items-start space-x-3">
                    <Mail className="w-5 h-5 text-gray-400 mt-0.5" />
                    <div>
                      <div className="text-sm text-gray-600">Email</div>
                      <div className="font-medium">{affiliate.email}</div>
                    </div>
                  </div>
                  <div className="flex items-start space-x-3">
                    <Phone className="w-5 h-5 text-gray-400 mt-0.5" />
                    <div>
                      <div className="text-sm text-gray-600">Phone</div>
                      <div className="font-medium">{affiliate.phone}</div>
                    </div>
                  </div>
                  {affiliate.company && (
                    <div className="flex items-start space-x-3">
                      <Building className="w-5 h-5 text-gray-400 mt-0.5" />
                      <div>
                        <div className="text-sm text-gray-600">Company</div>
                        <div className="font-medium">{affiliate.company}</div>
                      </div>
                    </div>
                  )}
                  {affiliate.address && (
                    <div className="flex items-start space-x-3">
                      <MapPin className="w-5 h-5 text-gray-400 mt-0.5" />
                      <div>
                        <div className="text-sm text-gray-600">Address</div>
                        <div className="font-medium">{affiliate.address}</div>
                      </div>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </motion.div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
      >
          <Card className="shadow-xl">
            <CardHeader>
              <CardTitle>Account Status</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div>
                  <div className="text-sm text-gray-600 mb-2">Status</div>
                  <Badge
                    className={
                      affiliate.status === 'Active'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-gray-100 text-gray-800'
                    }
                  >
                    {affiliate.status}
                  </Badge>
                </div>
                <div>
                  <div className="text-sm text-gray-600 mb-2">Member Since</div>
                  <div className="font-medium">{affiliate.joinedOn}</div>
                </div>
                <div>
                  <div className="text-sm text-gray-600 mb-2">Last Activity</div>
                  <div className="font-medium">{affiliate.lastActivity}</div>
                </div>
              </div>
            </CardContent>
          </Card>
      </motion.div>
    </div>
  )

  const renderReferrals = () => (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">My Referrals</h1>
        <p className="text-gray-600 mt-1">Track and manage all your referred customers</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <LinkIcon className="w-5 h-5 text-blue-600" />
            <span>Your Referral Link</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="p-4 bg-gray-50 rounded-lg mb-4">
            <div className="flex items-center space-x-2">
              <Input
                value={affiliate.uniqueLink}
                readOnly
                className="flex-1 bg-white"
              />
              <Button
                onClick={() => copyToClipboard(affiliate.uniqueLink)}
                className="bg-gradient-to-r from-blue-600 to-green-600"
              >
                <Copy className="w-4 h-4" />
              </Button>
            </div>
          </div>
          <p className="text-sm text-gray-600">
            Share this link with potential customers. You'll earn {affiliate.commissionPct}% commission on every successful referral!
          </p>
        </CardContent>
      </Card>

      <ReferralsTable affiliateId={affiliate.id} affiliateName={affiliate.name} />
    </div>
  )

  const renderEarnings = () => (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Earnings</h1>
        <p className="text-gray-600 mt-1">Track your commission and payouts</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="shadow-xl border-0 bg-gradient-to-br from-green-500 to-green-600 text-white">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-4">
              <DollarSign className="w-8 h-8 opacity-80" />
              <Badge className="bg-white/20 text-white border-0">Paid</Badge>
            </div>
            <div className="text-3xl font-bold">{formatCurrency(affiliate.earningsPaid)}</div>
            <div className="text-green-100 text-sm">Total Earnings Paid</div>
          </CardContent>
        </Card>

        <Card className="shadow-xl border-0 bg-gradient-to-br from-orange-500 to-orange-600 text-white">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-4">
              <TrendingUp className="w-8 h-8 opacity-80" />
              <Badge className="bg-white/20 text-white border-0">Pending</Badge>
            </div>
            <div className="text-3xl font-bold">{formatCurrency(affiliate.earningsPending)}</div>
            <div className="text-orange-100 text-sm">Pending Payout</div>
          </CardContent>
        </Card>

        <Card className="shadow-xl border-0 bg-gradient-to-br from-blue-500 to-blue-600 text-white">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-4">
              <DollarSign className="w-8 h-8 opacity-80" />
              <Badge className="bg-white/20 text-white border-0">Total</Badge>
            </div>
            <div className="text-3xl font-bold">{formatCurrency(affiliate.earningsPaid + affiliate.earningsPending)}</div>
            <div className="text-blue-100 text-sm">Total Earnings</div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Payout History</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-12 text-gray-500">
            <DollarSign className="w-16 h-16 mx-auto mb-4 opacity-20" />
            <p>No payout history available yet</p>
          </div>
        </CardContent>
      </Card>
    </div>
  )

  const renderResources = () => (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Resources</h1>
        <p className="text-gray-600 mt-1">Marketing materials and guidelines</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Marketing Materials</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-12 text-gray-500">
            <FileText className="w-16 h-16 mx-auto mb-4 opacity-20" />
            <p>Marketing resources will be available soon</p>
          </div>
        </CardContent>
      </Card>
    </div>
  )

  const renderSupport = () => (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Support</h1>
        <p className="text-gray-600 mt-1">Get help with your affiliate account</p>
      </div>

      <Card className="shadow-xl">
        <CardContent className="p-8">
          <div className="text-center">
            <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-green-500 rounded-full flex items-center justify-center mx-auto mb-4">
              <HeadphonesIcon className="w-8 h-8 text-white" />
            </div>
            <h3 className="text-2xl font-bold mb-2">Need Help?</h3>
            <p className="text-gray-600 mb-6">
              If you have any questions or need support with your affiliate account, please contact our team.
            </p>
            <Button className="bg-gradient-to-r from-blue-600 to-green-600 hover:from-blue-700 hover:to-green-700">
              Contact Support
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )

  const renderLearning = () => (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Learning Center</h1>
        <p className="text-gray-600 mt-1">Access training courses and resources</p>
      </div>

      <LearningModule />
    </div>
  )

  const renderSettings = () => (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Account Settings</h1>
        <p className="text-gray-600 mt-1">Manage your profile and preferences</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <User className="w-5 h-5 text-blue-600" />
            <span>Account Information</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex items-start space-x-3">
              <User className="w-5 h-5 text-gray-400 mt-0.5" />
              <div className="flex-1">
                <div className="text-sm text-gray-600">Name</div>
                <div className="font-medium">{affiliate.name}</div>
              </div>
            </div>
            <div className="flex items-start space-x-3">
              <Mail className="w-5 h-5 text-gray-400 mt-0.5" />
              <div className="flex-1">
                <div className="text-sm text-gray-600">Email</div>
                <div className="font-medium">{affiliate.email}</div>
              </div>
            </div>
            <div className="flex items-start space-x-3">
              <Phone className="w-5 h-5 text-gray-400 mt-0.5" />
              <div className="flex-1">
                <div className="text-sm text-gray-600">Phone</div>
                <div className="font-medium">{affiliate.phone}</div>
              </div>
            </div>
            {affiliate.company && (
              <div className="flex items-start space-x-3">
                <Building className="w-5 h-5 text-gray-400 mt-0.5" />
                <div className="flex-1">
                  <div className="text-sm text-gray-600">Company</div>
                  <div className="font-medium">{affiliate.company}</div>
                </div>
              </div>
            )}
            {affiliate.address && (
              <div className="flex items-start space-x-3">
                <MapPin className="w-5 h-5 text-gray-400 mt-0.5" />
                <div className="flex-1">
                  <div className="text-sm text-gray-600">Address</div>
                  <div className="font-medium">{affiliate.address}</div>
                </div>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Account Status</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <div className="text-sm text-gray-600 mb-2">Status</div>
              <Badge
                className={
                  affiliate.status === 'Active'
                    ? 'bg-green-100 text-green-800'
                    : 'bg-gray-100 text-gray-800'
                }
              >
                {affiliate.status}
              </Badge>
            </div>
            <div>
              <div className="text-sm text-gray-600 mb-2">Member Since</div>
              <div className="font-medium">{affiliate.joinedOn}</div>
            </div>
            <div>
              <div className="text-sm text-gray-600 mb-2">Last Activity</div>
              <div className="font-medium">{affiliate.lastActivity}</div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Sidebar */}
      <div className={`fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-xl transform transition-transform duration-300 lg:translate-x-0 ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}`}>
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="flex items-center justify-between p-6 border-b">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-green-500 rounded-lg flex items-center justify-center">
                <Users className="w-6 h-6 text-white" />
              </div>
              <div>
                <h2 className="font-bold text-gray-900">Partner Portal</h2>
                <p className="text-xs text-gray-500">{affiliate.affiliateId}</p>
              </div>
            </div>
            <button
              onClick={() => setIsSidebarOpen(false)}
              className="lg:hidden text-gray-500 hover:text-gray-700"
            >
              <X className="w-6 h-6" />
            </button>
          </div>

          {/* Navigation */}
          <nav className="flex-1 overflow-y-auto p-4">
            <div className="space-y-1">
              {menuItems.map((item) => {
                const Icon = item.icon
                const isActive = currentView === item.id
                return (
                  <button
                    key={item.id}
                    onClick={() => {
                      setCurrentView(item.id)
                      setIsSidebarOpen(false)
                    }}
                    className={`w-full flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors ${
                      isActive
                        ? 'bg-gradient-to-r from-blue-500 to-green-500 text-white'
                        : 'text-gray-700 hover:bg-gray-100'
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                    <span className="font-medium">{item.label}</span>
                  </button>
                )
              })}
            </div>
          </nav>

          {/* User Info & Logout */}
          <div className="p-4 border-t space-y-3">
            <div className="flex items-center space-x-3 px-2">
              <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-green-500 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-white font-bold">
                  {affiliate.name.charAt(0).toUpperCase()}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-medium text-gray-900 truncate">{affiliate.name}</div>
                <div className="text-xs text-gray-500 truncate">{affiliate.email}</div>
              </div>
            </div>
            <Button
              variant="outline"
              onClick={handleLogout}
              className="w-full flex items-center justify-center space-x-2"
            >
              <LogOut className="w-4 h-4" />
              <span>Logout</span>
            </Button>
          </div>
        </div>
      </div>

      {/* Overlay */}
      {isSidebarOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-40 lg:hidden"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Main Content */}
      <div className="lg:pl-64">
        {/* Top Bar */}
        <div className="bg-white shadow-sm border-b sticky top-0 z-30">
          <div className="flex items-center justify-between px-6 py-4">
            <button
              onClick={() => setIsSidebarOpen(true)}
              className="lg:hidden text-gray-500 hover:text-gray-700"
            >
              <Menu className="w-6 h-6" />
            </button>
            <div className="lg:hidden flex items-center space-x-4">
              <div className="text-right">
                <div className="font-medium text-gray-900">{affiliate.name}</div>
                <div className="text-sm text-gray-500">{affiliate.email}</div>
              </div>
              <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-green-500 rounded-full flex items-center justify-center">
                <span className="text-white font-bold">
                  {affiliate.name.charAt(0).toUpperCase()}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Page Content */}
        <div className="p-6">
          <motion.div
            key={currentView}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
          >
            {renderContent()}
          </motion.div>
        </div>
      </div>
    </div>
  )
}
