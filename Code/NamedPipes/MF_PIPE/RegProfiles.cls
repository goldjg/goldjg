VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "RegProfiles"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'The following 2 consts are made public through properties:
Private Const rp_REG_SZ As Long = 1
Private Const rp_REG_DWORD As Long = 4

'The following 6 consts are made public through properties:
Private Const rp_HKEY_CLASSES_ROOT = &H80000000
Private Const rp_HKEY_CURRENT_USER = &H80000001
Private Const rp_HKEY_LOCAL_MACHINE = &H80000002
Private Const rp_HKEY_USERS = &H80000003
Private Const rp_HKEY_CURRENT_CONFIG As Long = &H80000005
Private Const rp_HKEY_PERFORMANCE_DATA = &H80000004

Private Const CurrentUserHive = "HKEY_CURRENT_USER"

Private Const ERROR_NONE = 0
Private Const ERROR_BADDB = 1
Private Const ERROR_BADKEY = 2
Private Const ERROR_CANTOPEN = 3
Private Const ERROR_CANTREAD = 4
Private Const ERROR_CANTWRITE = 5
Private Const ERROR_OUTOFMEMORY = 6
Private Const ERROR_ARENA_TRASHED = 7
Private Const ERROR_ACCESS_DENIED = 8
Private Const ERROR_INVALID_PARAMETERS = 87
Private Const ERROR_NO_MORE_ITEMS = 259

'Private Const KEY_ALL_ACCESS = &H3F
Private Const REG_OPTION_NON_VOLATILE = 0

Private Const SYNCHRONIZE = &H100000
Private Const STANDARD_RIGHTS_READ = &H20000
Private Const STANDARD_RIGHTS_WRITE = &H20000
Private Const STANDARD_RIGHTS_EXECUTE = &H20000
Private Const STANDARD_RIGHTS_REQUIRED = &HF0000
Private Const STANDARD_RIGHTS_ALL = &H1F0000
Private Const KEY_QUERY_VALUE = &H1
Private Const KEY_SET_VALUE = &H2
Private Const KEY_CREATE_SUB_KEY = &H4
Private Const KEY_ENUMERATE_SUB_KEYS = &H8
Private Const KEY_NOTIFY = &H10
Private Const KEY_CREATE_LINK = &H20
Private Const KEY_READ = ((STANDARD_RIGHTS_READ Or KEY_QUERY_VALUE Or KEY_ENUMERATE_SUB_KEYS Or KEY_NOTIFY) And (Not SYNCHRONIZE))
Private Const KEY_WRITE = ((STANDARD_RIGHTS_WRITE Or KEY_SET_VALUE Or KEY_CREATE_SUB_KEY) And (Not SYNCHRONIZE))
Private Const KEY_EXECUTE = (KEY_READ)
Private Const KEY_ALL_ACCESS = ((STANDARD_RIGHTS_ALL Or KEY_QUERY_VALUE Or KEY_SET_VALUE Or KEY_CREATE_SUB_KEY Or KEY_ENUMERATE_SUB_KEYS Or KEY_NOTIFY Or KEY_CREATE_LINK) And (Not SYNCHRONIZE))
Private Const ERROR_SUCCESS = 0&



Private Declare Function RegCloseKey Lib "advapi32.dll" (ByVal hKey As Long) As Long

Private Declare Function RegCreateKeyEx Lib "advapi32.dll" Alias "RegCreateKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, ByVal Reserved As Long, ByVal lpClass As String, ByVal dwOptions As Long, ByVal samDesired As Long, ByVal lpSecurityAttributes As Long, phkResult As Long, lpdwDisposition As Long) As Long
Private Declare Function RegOpenKeyEx Lib "advapi32.dll" Alias "RegOpenKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, ByVal ulOptions As Long, ByVal samDesired As Long, phkResult As Long) As Long

Private Declare Function RegQueryValueExString Lib "advapi32.dll" Alias "RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal lpReserved As Long, lpType As Long, ByVal lpData As String, lpcbData As Long) As Long
Private Declare Function RegQueryValueExLong Lib "advapi32.dll" Alias "RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal lpReserved As Long, lpType As Long, lpData As Long, lpcbData As Long) As Long
Private Declare Function RegQueryValueExNULL Lib "advapi32.dll" Alias "RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal lpReserved As Long, lpType As Long, ByVal lpData As Long, lpcbData As Long) As Long
Private Declare Function RegSetValueExString Lib "advapi32.dll" Alias "RegSetValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal Reserved As Long, ByVal dwType As Long, ByVal lpValue As String, ByVal cbData As Long) As Long
Private Declare Function RegSetValueExLong Lib "advapi32.dll" Alias "RegSetValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal Reserved As Long, ByVal dwType As Long, lpValue As Long, ByVal cbData As Long) As Long
        
Private Declare Function RegEnumKeyEx Lib "advapi32.dll" Alias "RegEnumKeyExA" (ByVal hKey As Long, ByVal dwIndex As Long, ByVal lpname As String, lpcbName As Long, ByVal lpReserved As Long, ByVal lpClass As String, lpcbClass As Long, lpftLastWriteTime As FILETIME) As Long

Private Declare Function RegEnumValue Lib "advapi32.dll" Alias "RegEnumValueA" (ByVal hKey As Long, ByVal dwIndex As Long, ByVal lpValueName As String, lpcbValueName As Long, ByVal lpReserved As Long, lpType As Long, lpData As Byte, lpcbData As Long) As Long

Private Type FILETIME
    dwLowDateTime As Long
    dwHighDateTime As Long
End Type




Private Function SetValueEx(ByVal hKey As Long, strValueName As String, lngType As Long, varValue As Variant) As Long
    Dim lngValue As Long
    Dim strValue As String
    
    Select Case lngType
        Case rp_REG_SZ
            strValue = varValue & Chr$(0)
            SetValueEx = RegSetValueExString(hKey, strValueName, 0&, lngType, strValue, Len(strValue))
        Case rp_REG_DWORD
            lngValue = varValue
            SetValueEx = RegSetValueExLong(hKey, strValueName, 0&, lngType, lngValue, 4)
    End Select
End Function

Private Function QueryValueEx(ByVal lhKey As Long, ByVal szValueName As String, vValue As Variant, Optional lngType As Long = -1) As Long
    Dim cch As Long
    Dim lrc As Long
    Dim lType As Long
    Dim lValue As Long
    Dim sValue As String
    
On Error GoTo QueryValueExError
    ' Determine the size and type of data to be read
    lrc = RegQueryValueExNULL(lhKey, szValueName, 0&, lType, 0&, cch)
    If lrc <> ERROR_NONE Then Error 5
    
    If lngType <> -1 Then
        lType = lngType   'Force it to select this type
    End If
    
    Select Case lType
        ' For strings
        Case rp_REG_SZ:
            sValue = String(cch, 0)
            lrc = RegQueryValueExString(lhKey, szValueName, 0&, lType, sValue, cch)
            If lrc = ERROR_NONE Then
                vValue = Left$(sValue, cch - 1)
            Else
                vValue = Empty
            End If
        ' For DWORDS
        Case rp_REG_DWORD:
            lrc = RegQueryValueExLong(lhKey, szValueName, 0&, lType, lValue, cch)
            If lrc = ERROR_NONE Then vValue = lValue
        Case Else
            'all other data types not supported
            lrc = -1
        End Select
    
QueryValueExExit:
    QueryValueEx = lrc
    Exit Function
    
QueryValueExError:
    Resume QueryValueExExit
End Function


Public Function SetKeyValue(lngHive As Long, strKeyName As String, strValueName As String, _
                                    varValueSetting As Variant, lValueType As Long) As Boolean
    Dim lngRetVal As Long    'result of the RegOpenKeyEx function (0 = success)
    Dim lngRetval2 As Long   'result of the SetValueEx function   (0 = success)
    Dim hKey As Long         'handle of open key
           
    lngRetVal = RegOpenKeyEx(lngHive, strKeyName, 0, KEY_ALL_ACCESS, hKey)
    lngRetval2 = SetValueEx(hKey, strValueName, lValueType, varValueSetting)
    RegCloseKey (hKey)
    SetKeyValue = (Not (CBool(lngRetVal)) And Not (CBool(lngRetval2)))
End Function

Public Function QueryValue(lngHive As Long, strKeyName As String, _
                        strValueName As String, Optional lngType As Long = -1) As Variant
    Dim lngRetVal As Long       'result of the API functions
    Dim hKey As Long            'handle of opened key
    Dim varValue As Variant     'setting of queried value
    
    lngRetVal = RegOpenKeyEx(lngHive, strKeyName, 0, KEY_ALL_ACCESS, hKey)
    
    If lngType <> -1 Then
        lngRetVal = QueryValueEx(hKey, strValueName, varValue, lngType)
    Else
        lngRetVal = QueryValueEx(hKey, strValueName, varValue)
    End If
    
    QueryValue = varValue
    RegCloseKey (hKey)
End Function

Public Function CreateRegistryKey(lngHive As Long, strKeyName As String) As Boolean
    Dim hKey As Long         'handle of open key
    Dim dwDispostion As Long
    Dim lngRetVal As Long    'result of RegCreateKeyEx (0 = success)
    
    lngRetVal = RegCreateKeyEx(lngHive, strKeyName, 0, rp_REG_SZ, _
                            REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, 0, hKey, dwDispostion)
    RegCloseKey (hKey)
    CreateRegistryKey = Not (CBool(lngRetVal))
End Function

Public Function KeyExists(lngHive As Long, strKeyName As String) As Boolean
    Dim hKey As Long
    Dim lngRetVal As Long  'result of RegOpenKeyEx (0 = success)
    
    lngRetVal = RegOpenKeyEx(lngHive, strKeyName, 0, KEY_READ, hKey)
    RegCloseKey (hKey)
    KeyExists = Not (CBool(lngRetVal))
End Function

'Enumerates sub keys for a given key
Public Function EnumKey(lngHive As Long, strKeyName As String, _
                                                    lngSubKey As Long) As String
    Dim lngResult As Long
    Dim strSubKeyName As String
    Dim lngSubKeyNameLength As Long
    Dim strClass As String
    Dim lngClassLength As Long
    Dim ft As FILETIME
    Dim hKey As Long
    Dim lngResevered As Long
    
    lngSubKeyNameLength = 2000
    strSubKeyName = String$(lngSubKeyNameLength, 0)
    lngClassLength = 2000
    strClass = String$(lngClassLength, 0)
    
    If ERROR_SUCCESS = RegOpenKeyEx(lngHive, strKeyName, 0, KEY_READ, hKey) Then
        lngResult = RegEnumKeyEx(hKey, lngSubKey, strSubKeyName, _
                    lngSubKeyNameLength, lngResevered, strClass, lngClassLength, ft)
        If lngResult = 0 Then
            EnumKey = Left$(strSubKeyName, lngSubKeyNameLength)
        Else
            EnumKey = ""
        End If
    Else
        EnumKey = ""
    End If
End Function

'Enumerates the values for a specified key
Public Function EnumValue(lngHive As Long, strKeyName As String, lngIndex As Long, _
                ByRef strReturnValue As String, _
                Optional ByRef lngReturnType As Long) As Boolean
    Dim lngResult As Long
    Dim hKey As Long
    Dim strValueName As String
    Dim lngValueNameLength As Long
    Dim lngReserved As Long
    Dim lngType As Long
    
    lngValueNameLength = 500
    strValueName = String$(lngValueNameLength, 0)

    If ERROR_SUCCESS = RegOpenKeyEx(lngHive, strKeyName, 0, KEY_READ, hKey) Then
        lngResult = RegEnumValue(hKey, lngIndex, strValueName, lngValueNameLength, _
                            lngReserved, lngType, ByVal 0&, ByVal 0&)
        If lngResult = 0 Then
            strReturnValue = Left$(strValueName, lngValueNameLength)
            lngReturnType = lngType
            EnumValue = True
        Else
            strReturnValue = ""
            lngReturnType = 0
            EnumValue = False
        End If
    Else
        strReturnValue = ""
        lngReturnType = 0
        EnumValue = False
    End If
End Function


Public Property Get REG_SZ() As Long
    REG_SZ = rp_REG_SZ
End Property

Public Property Get REG_DWORD() As Long
    REG_DWORD = rp_REG_DWORD
End Property

Public Property Get HKEY_CLASSES_ROOT() As Long
    HKEY_CLASSES_ROOT = rp_HKEY_CLASSES_ROOT
End Property
Public Property Get HKEY_CURRENT_USER() As Long
    HKEY_CURRENT_USER = rp_HKEY_CURRENT_USER
End Property
Public Property Get HKEY_LOCAL_MACHINE() As Long
    HKEY_LOCAL_MACHINE = rp_HKEY_LOCAL_MACHINE
End Property
Public Property Get HKEY_USERS() As Long
    HKEY_USERS = rp_HKEY_USERS
End Property
Public Property Get HKEY_CURRENT_CONFIG() As Long
    HKEY_CURRENT_CONFIG = rp_HKEY_CURRENT_CONFIG
End Property
Public Property Get HKEY_PERFORMANCE_DATA() As Long
    HKEY_PERFORMANCE_DATA = rp_HKEY_PERFORMANCE_DATA
End Property


