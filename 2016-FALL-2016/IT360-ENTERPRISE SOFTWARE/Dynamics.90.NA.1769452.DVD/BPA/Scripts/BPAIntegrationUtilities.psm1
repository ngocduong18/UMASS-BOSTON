#--------------------------------------------------------------------------
#     Copyright (c) Microsoft Corporation.  All rights reserved.
#--------------------------------------------------------------------------

<#
 .SYNOPSIS
   Writes text to stderr, which is later consulted by BPA.

 .PARAMETER TextToWrite
   Specifies the string to be written to the 'stderr' file.
 .PARAMETER IsError
   Specifies if the text is an error message; otherwise it is considered a warning message.
#>
function Write-Stderr {
    PARAM (
        [string] $TextToWrite,
        [switch] $IsWarning = $false
    )

    PROCESS {
        if ($IsWarning)
        {
            $Host.UI.WriteErrorLine("`nWarning: $TextToWrite")
        }
        else
        {
            $Host.UI.WriteErrorLine("`nError: $TextToWrite")
        }
    }
}


<#
 .SYNOPSIS
   UrlDecodes a string.

 .PARAMETER StringToDecode
   The string to decode.
#>
function UrlDecode-String {
    PARAM (
        [string] $StringToDecode
    )
    
    PROCESS {
        [System.Web.HttpUtility]::UrlDecode($StringToDecode)
    }
}


<#
 .SYNOPSIS
   Gets the content of the response for an HTTP request. If an error occured, returns null.
 .PARAMETER RequestUrl
   The URL to issue the HTTP request to. 
#>
function Get-HttpResponseContent {
    PARAM (
        [string] $RequestUrl
    )

    PROCESS {
        # Disable SSL validation 
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }

        # Create and issue an HTTP request
        [System.Net.HttpWebRequest] $request = [System.Net.HttpWebRequest]::Create($RequestUrl)
        $request.Method = "GET"
        $request.AllowAutoRedirect = $false
        try 
        {
            $response = $request.GetResponse()
            $responseReader = New-Object -TypeName System.IO.StreamReader -ArgumentList $response.GetResponseStream()
            $responseContent = $responseReader.ReadToEnd()
        }
        catch
        {
            $exceptionMessage = $_.Exception.Message
            Write-Host " $exceptionMessage"
            return $null
        }

        Write-Host " The response content is: $responseContent"
        return $responseContent
    }
}
# SIG # Begin signature block
# MIIghQYJKoZIhvcNAQcCoIIgdjCCIHICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUcGxuGsiPTzod+9wb1spTKLDR
# HrKgghsfMIIEwzCCA6ugAwIBAgITMwAAAHp9lu0XI96URAAAAAAAejANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTUwNjA0MTc0MDUw
# WhcNMTYwOTA0MTc0MDUwWjCBszELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNO
# OjU4NDctRjc2MS00RjcwMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6b56jC6C2Uc1
# 2KxcPpm1I1Xxc2BPiAi1UPEVjihDHwdDSzBr/QPSXxAVUTz8MTpXXqBedpklq44+
# 79048n/2K0ikAshHYCP1GhD1BnqYJ0vF2WqiYvXFfpDfhPo0x6hygwKNc5DpDZU5
# sEKd7ek2BsWoT4DJ2F7F61MAJeBomm3jllLWgrfBPBugureJkRjd3/gvq0k7vxwJ
# w+ggnbqjSjqVjjRW2cV9ryrXmyPjPIQsoirzA8bjS3Ju6G117IGV5RVKQhcO7eT5
# G8TDkBbU45w6kl47swdtU0afpRvSE5mI8TiMdKr1YXvOZc/GD15L/tqFS0oUOFhg
# rZ9iLZjRZwIDAQABo4IBCTCCAQUwHQYDVR0OBBYEFJXdwLlfqN8g4fJApMvr7Huv
# hWipMB8GA1UdIwQYMBaAFCM0+NlSRnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsG
# AQUFBzAChjxodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFRpbWVTdGFtcFBDQS5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQEFBQADggEBAAeKHqOyaVuzuYzVBZEs7xooZ9UGAzLjzAhMhQj++ao7vriC
# aZIHm1giTvxgHH7pswjZvKB9UxnTIq20jBj7Evv+Q0xcJwm0CLXnoe3MSBgOhv01
# /RgIslaH9Cz2W0F10SdKP6kVe7RDmykqpEtg25mmXkRcbBQBkMJtB/Yls/54MnDh
# xx8ItDh+yFWseHi4tamqwPlZYIfb7Yq59vdI3Q51kWQFkbJQa4th4jPOJbgjXNBM
# EP0b44WvTuwgvijEHhP+MbqvpR6tzNd3ovcolM+cEk+xk7mmIyGDeqRtMrEtZEy3
# UNe5StxMymJWl1XdR4x775pwZ8ALCTIgHJ7R+FQwggTsMIID1KADAgECAhMzAAAB
# Cix5rtd5e6asAAEAAAEKMA0GCSqGSIb3DQEBBQUAMHkxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNVBAMTGk1pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBMB4XDTE1MDYwNDE3NDI0NVoXDTE2MDkwNDE3NDI0NVowgYMxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIx
# HjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAJL8bza74QO5KNZG0aJhuqVG+2MWPi75R9LH7O3HmbEm
# UXW92swPBhQRpGwZnsBfTVSJ5E1Q2I3NoWGldxOaHKftDXT3p1Z56Cj3U9KxemPg
# 9ZSXt+zZR/hsPfMliLO8CsUEp458hUh2HGFGqhnEemKLwcI1qvtYb8VjC5NJMIEb
# e99/fE+0R21feByvtveWE1LvudFNOeVz3khOPBSqlw05zItR4VzRO/COZ+owYKlN
# Wp1DvdsjusAP10sQnZxN8FGihKrknKc91qPvChhIqPqxTqWYDku/8BTzAMiwSNZb
# /jjXiREtBbpDAk8iAJYlrX01boRoqyAYOCj+HKIQsaUCAwEAAaOCAWAwggFcMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBSJ/gox6ibN5m3HkZG5lIyiGGE3
# NDBRBgNVHREESjBIpEYwRDENMAsGA1UECxMETU9QUjEzMDEGA1UEBRMqMzE1OTUr
# MDQwNzkzNTAtMTZmYS00YzYwLWI2YmYtOWQyYjFjZDA1OTg0MB8GA1UdIwQYMBaA
# FMsR6MrStBZYAck3LjMWFrlMmgofMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY0NvZFNpZ1BDQV8w
# OC0zMS0yMDEwLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljQ29kU2lnUENBXzA4LTMx
# LTIwMTAuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQCmqFOR3zsB/mFdBlrrZvAM2PfZ
# hNMAUQ4Q0aTRFyjnjDM4K9hDxgOLdeszkvSp4mf9AtulHU5DRV0bSePgTxbwfo/w
# iBHKgq2k+6apX/WXYMh7xL98m2ntH4LB8c2OeEti9dcNHNdTEtaWUu81vRmOoECT
# oQqlLRacwkZ0COvb9NilSTZUEhFVA7N7FvtH/vto/MBFXOI/Enkzou+Cxd5AGQfu
# FcUKm1kFQanQl56BngNb/ErjGi4FrFBHL4z6edgeIPgF+ylrGBT6cgS3C6eaZOwR
# XU9FSY0pGi370LYJU180lOAWxLnqczXoV+/h6xbDGMcGszvPYYTitkSJlKOGMIIF
# mTCCA4GgAwIBAgIQea0WoUqgpa1Mc1j0BxMuZTANBgkqhkiG9w0BAQUFADBfMRMw
# EQYKCZImiZPyLGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0w
# KwYDVQQDEyRNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcN
# MDEwNTA5MjMxOTIyWhcNMjEwNTA5MjMyODEzWjBfMRMwEQYKCZImiZPyLGQBGRYD
# Y29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQDEyRNaWNyb3Nv
# ZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQDzXfqAZ9Rap6kMLJAg0DUIPHWEzbcHiZyJ2t7Ow2D6kWha
# npRxKRh2fMLgyCV2lA5Y+gQ0Nubfr/eAuulYCyuT5Z0F43cikfc0ZDwikR1e4QmQ
# vBT+/HVYGeF5tweSo66IWQjYnwfKA1j8aCltMtfSqMtL/OELSDJP5uu4rU/kXG8T
# lJnbldV126gat5SRtHdb9UgMj2p5fRRwBH1tr5D12nDYR7e/my9s5wW34RFgrHmR
# FHzF1qbk4X7Vw37lktI8ALU2gt554W3ztW74nzPJy1J9c5g224uha6KVl5uj3sJN
# Jv8GlmclBsjnrOTuEjOVMZnINQhONMp5U9W1vmMyWUA2wKVOBE0921sHM+RYv+8/
# U2TYQlk1V/0PRXwkBE2e1jh0EZcikM5oRHSSb9VLb7CG48c2QqDQ/MHAWvmjYbkw
# R3GWChawkcBCle8Qfyhq4yofseTNAz93cQTHIPxJDx1FiKTXy36IrY4t7EXbxFEE
# ySr87IaemhGXW97OU4jm4rf9rJXCKEDb7wSQ34EzOdmyRaUjhwalVYkxuwYtYA5B
# GH0fLrWXyxHrFdUkpZTvFRSJ/Utz+jJb/NEzAPlZYnAHMuouq0Ate8rdIWcbMJmP
# FqojqEHRsG4RmzbE3kB0nOFYZcFgHnpbOMiPuwQmfNQWQOW2a2yqhv0Av87BNQID
# AQABo1EwTzALBgNVHQ8EBAMCAcYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU
# DqyCYEBWJ5flJRP8KuEKU5VZ5KQwEAYJKwYBBAGCNxUBBAMCAQAwDQYJKoZIhvcN
# AQEFBQADggIBAMURTQM6YN1dUhF3j7K7NsiyBb+0t6jYIJ1cEwO2HCL6BhM1tshj
# 1JpHbyZX0lXxBLEmX9apUGigvNK4bszD6azfGc14rFl0rGY0NsQbPmw4TDMOMBIN
# oyb+UVMA/69aToQNDx/kbQUuToVLjWwzb1TSZKu/UK99ejmgN+1jAw/8EwbOFjbU
# VDuVG1FiOuVNF9QFOZKaJ6hbqr3su77jIIlgcWxWs6UT0G0OI36VA+1oPfLYY7hr
# TbboMLXhypRL96KqXZkwsj2nwlFsKCABJCcrSwC3nRFrcL6yEIK8DJto0I07JIeq
# mShynTNfWZC99d6TnjpiWjQ54ohVHbkGsMGJay3XacMZEjaE0Mmg2v8vaXiy5Xra
# 69cMwPe9Yxe4ORM4ojZbe/KFVmodZGLBOOKqv1FmopT1EpxmIhBr8rcwki3yKfA9
# OxRDaKLxnCk3y844ICVtfGfzfiQSJAMIgUfspZ6X9RjXz7vV73aW7/3O21adlaBC
# +ZdY4dcxItNfWeY+biIA6kOEtiXb2fMIVmjAZGsdfOy2k6JiV24u2OdYj8QxSSbd
# 3ik1h/UwcXBbFDxpvYkSfesuo/7Yf56CWlIKK8FDK9kwiJ/IEPuJjeahhXUzfmye
# 23MTZGJppS99ypZtn/gETTCSPW4hFCHJPeDD/YprnUr90aGdmUN3P7DaMIIFvDCC
# A6SgAwIBAgIKYTMmGgAAAAAAMTANBgkqhkiG9w0BAQUFADBfMRMwEQYKCZImiZPy
# LGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQDEyRN
# aWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMTAwODMxMjIx
# OTMyWhcNMjAwODMxMjIyOTMyWjB5MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSMwIQYDVQQDExpNaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJyWVwZMGS/HZpgICBCmXZT
# bD4b1m/My/Hqa/6XFhDg3zp0gxq3L6Ay7P/ewkJOI9VyANs1VwqJyq4gSfTwaKxN
# S42lvXlLcZtHB9r9Jd+ddYjPqnNEf9eB2/O98jakyVxF3K+tPeAoaJcap6Vyc1bx
# F5Tk/TWUcqDWdl8ed0WDhTgW0HNbBbpnUo2lsmkv2hkL/pJ0KeJ2L1TdFDBZ+NKN
# Yv3LyV9GMVC5JxPkQDDPcikQKCLHN049oDI9kM2hOAaFXE5WgigqBTK3S9dPY+fS
# LWLxRT3nrAgA9kahntFbjCZT6HqqSvJGzzc8OJ60d1ylF56NyxGPVjzBrAlfA9MC
# AwEAAaOCAV4wggFaMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFMsR6MrStBZY
# Ack3LjMWFrlMmgofMAsGA1UdDwQEAwIBhjASBgkrBgEEAYI3FQEEBQIDAQABMCMG
# CSsGAQQBgjcVAgQWBBT90TFO0yaKleGYYDuoMW+mPLzYLTAZBgkrBgEEAYI3FAIE
# DB4KAFMAdQBiAEMAQTAfBgNVHSMEGDAWgBQOrIJgQFYnl+UlE/wq4QpTlVnkpDBQ
# BgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9taWNyb3NvZnRyb290Y2VydC5jcmwwVAYIKwYBBQUHAQEESDBG
# MEQGCCsGAQUFBzAChjhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRz
# L01pY3Jvc29mdFJvb3RDZXJ0LmNydDANBgkqhkiG9w0BAQUFAAOCAgEAWTk+fyZG
# r+tvQLEytWrrDi9uqEn361917Uw7LddDrQv+y+ktMaMjzHxQmIAhXaw9L0y6oqhW
# nONwu7i0+Hm1SXL3PupBf8rhDBdpy6WcIC36C1DEVs0t40rSvHDnqA2iA6VW4LiK
# S1fylUKc8fPv7uOGHzQ8uFaa8FMjhSqkghyT4pQHHfLiTviMocroE6WRTsgb0o9y
# lSpxbZsa+BzwU9ZnzCL/XB3Nooy9J7J5Y1ZEolHN+emjWFbdmwJFRC9f9Nqu1IIy
# bvyklRPk62nnqaIsvsgrEA5ljpnb9aL6EiYJZTiU8XofSrvR4Vbo0HiWGFzJNRZf
# 3ZMdSY4tvq00RBzuEBUaAF3dNVshzpjHCe6FDoxPbQ4TTj18KUicctHzbMrB7HCj
# V5JXfZSNoBtIA1r3z6NnCnSlNu0tLxfI5nI3EvRvsTxngvlSso0zFmUeDordEN5k
# 9G/ORtTTF+l5xAS00/ss3x+KnqwK+xMnQK3k+eGpf0a7B2BHZWBATrBC7E7ts3Z5
# 2Ao0CW0cgDEf4g5U3eWh++VHEK1kmP9QFi58vwUheuKVQSdpw5OPlcmN2Jshrg1c
# nPCiroZogwxqLbt2awAdlq3yFnv2FoMkuYjPaqhHMS+a3ONxPdcAfmJH0c6IybgY
# +g5yjcGjPa8CQGr/aZuW4hCoELQ3UAjWwz0wggYHMIID76ADAgECAgphFmg0AAAA
# AAAcMA0GCSqGSIb3DQEBBQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJ
# kiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENl
# cnRpZmljYXRlIEF1dGhvcml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMxMzAz
# MDlaMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNV
# BAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBAJ+hbLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn0Uyt
# dDAgEesH1VSVFUmUG0KSrphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0Zxws
# /HvniB3q506jocEjU8qN+kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4nrIZP
# VVIM5AMs+2qQkDBuh/NZMJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YRJylm
# qJfk0waBSqL5hKcRRxQJgp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54QTF3
# zJvfO4OToWECtR0Nsfz3m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8GA1Ud
# EwEB/wQFMAMBAf8wHQYDVR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsGA1Ud
# DwQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJgQFYn
# l+UlE/wq4QpTlVnkpKFjpGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmS
# JomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2Vy
# dGlmaWNhdGUgQXV0aG9yaXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJMEcw
# RaBDoEGGP2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L21pY3Jvc29mdHJvb3RjZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUH
# MAKGOGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0
# Um9vdENlcnQuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBBQUA
# A4ICAQAQl4rDXANENt3ptK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1iuFcC
# y04gE1CZ3XpA4le7r1iaHOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+rkuTn
# jWrVgMHmlPIGL4UD6ZEqJCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGctxVEO
# 6mJcPxaYiyA/4gcaMvnMMUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/FNSte
# o7/rvH0LQnvUU3Ih7jDKu3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbonXCU
# bKw5TNT2eb+qGHpiKe+imyk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0NbhO
# xXEjEiZ2CzxSjHFaRkMUvLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPpK+m7
# 9EjMLNTYMoBMJipIJF9a6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2JoXZh
# tG6hE6a/qkfwEm/9ijJssv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0eFQF
# 1EEuUKyUsKV4q7OglnUa2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng9wFl
# b4kLfchpyOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TGCBNAwggTMAgEB
# MIGQMHkxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNV
# BAMTGk1pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBAhMzAAABCix5rtd5e6asAAEA
# AAEKMAkGBSsOAwIaBQCggekwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFC5YOBDE
# RFA4Dnx1VOKx1MMcA3GtMIGIBgorBgEEAYI3AgEMMXoweKBagFgATQBpAGMAcgBv
# AHMAbwBmAHQAIABEAHkAbgBhAG0AaQBjAHMAIABOAEEAVgAgAEMAbwBkAGUAcwBp
# AGcAbgAgAFMAdQBiAG0AaQBzAHMAcwBpAG8AbgAuoRqAGGh0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbTANBgkqhkiG9w0BAQEFAASCAQAzSq5ORBCvBZSroNFAhjE94pW1
# tB+FDaVNIRKjlC9663wHJLXlMph6ZCxVWqsgHDgRkONDVt5ZqRA/67aJNPofZcHU
# fkTaPL3ZzX0huie9lY0yK9sJVgDQkQIaz0ei3No2rd3peTMlwV73z0xoctc7crVU
# jFP5HZT72UeTxyzBAYvUTOYuhcWkDLdKjIoMy27t8q1f+m3pxjM2aDB018efoNxl
# dMviuZyuTT6q8WzxYXiEXepwK6jYGJelEoJLWCw7+vBKo8e7GgNSFuTBK17/fzhE
# HFEuY6cWptRviFOYJRKxMel1pA6hL2PkgwM5KdcjTehJskI+pBbxKrvYIWucoYIC
# KDCCAiQGCSqGSIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFBDQQITMwAAAHp9lu0XI96URAAAAAAAejAJBgUrDgMCGgUAoF0wGAYJKoZI
# hvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTUwOTE1MjA0NTUw
# WjAjBgkqhkiG9w0BCQQxFgQUUwhQy/o1I0m1j++T2woisxxUozIwDQYJKoZIhvcN
# AQEFBQAEggEALvM8I2EYka9C6d+8CIf+ooolPPmhKy5NyhaAIGcY12JVMCdl/Css
# XhFhH8ETvuEGub6WmPZ+3JQhyyQWNLkSKt7XPuh4toxUFmwDGMOuuqx/F02jcxEJ
# ZFtiSsbP/fhA4yLHLwEIDqm3TF3oGxUXJkLCjCQF8flkuS+Qj+D7iFfombW4B8rY
# ZDKgQbg8J52Sp6454NGliLpifuZh8dFci/E2zemDdIYgoUC/OT/tsOWgFe8AgAIC
# WVz9SbHkqeRgy4J+ufgi19RvTbYvsqYwgE+PC6X0M811zai5oN2XYM0zzRU6Pufd
# S7EPyVhxKJ2eAUPTaLpBqfXAaqINzXn2Dw==
# SIG # End signature block
