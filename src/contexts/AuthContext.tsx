import React, { createContext, useContext, useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'

interface AuthContextType {
  isAuthenticated: boolean
  userMobile: string | null
  login: (mobile: string) => Promise<void>
  logout: () => Promise<void>
  isLoading: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [userMobile, setUserMobile] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    checkAuthStatus()
  }, [])

  const checkAuthStatus = async () => {
    try {
      const storedMobile = localStorage.getItem('admin_mobile')
      const storedTimestamp = localStorage.getItem('admin_auth_timestamp')

      if (storedMobile && storedTimestamp) {
        const authTime = parseInt(storedTimestamp)
        const currentTime = Date.now()
        const hoursSinceAuth = (currentTime - authTime) / (1000 * 60 * 60)

        if (hoursSinceAuth < 24) {
          setIsAuthenticated(true)
          setUserMobile(storedMobile)
        } else {
          localStorage.removeItem('admin_mobile')
          localStorage.removeItem('admin_auth_timestamp')
        }
      }
    } catch (error) {
      console.error('Error checking auth status:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const login = async (mobile: string) => {
    try {
      const timestamp = Date.now()

      localStorage.setItem('admin_mobile', mobile)
      localStorage.setItem('admin_auth_timestamp', timestamp.toString())

      const { error } = await supabase
        .from('admin_users')
        .update({ last_login: new Date().toISOString() })
        .eq('phone', mobile)

      if (error) {
        console.error('Error updating last login:', error)
      }

      setIsAuthenticated(true)
      setUserMobile(mobile)
    } catch (error) {
      console.error('Login error:', error)
      throw error
    }
  }

  const logout = async () => {
    try {
      localStorage.removeItem('admin_mobile')
      localStorage.removeItem('admin_auth_timestamp')
      setIsAuthenticated(false)
      setUserMobile(null)
    } catch (error) {
      console.error('Logout error:', error)
      throw error
    }
  }

  return (
    <AuthContext.Provider
      value={{
        isAuthenticated,
        userMobile,
        login,
        logout,
        isLoading
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
