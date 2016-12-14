#--------------------------------------------------------------------------
#     Copyright (c) Microsoft Corporation.  All rights reserved.
#--------------------------------------------------------------------------

<#
 .SYNOPSIS	
   This cmdlet analyses the Office 365 tenant state, the configuration of the Microsoft Dynamics NAV app in the Windows Azure Active Directory (AAD) tenant, and the user mappings.	
	
 .DESCRIPTION	
   This cmdlet analyses the Office 365 tenant state, the configuration of the Microsoft Dynamics NAV app in the Windows Azure Active Directory tenant, and the user mappings.	
   The process involves the following validation steps:	
	 1. The AAD tenant name/ID that is configured in the Microsoft Dynamics NAV Server Instance or Web Server Instance configuration file should be the same as the connected tenant.
     2. The application that is specified by the "wtrealm" query string parameter of the ACSUri parameter in the web.config file exists in the current AAD tenant.	
     3. The application return URI is the same as the entry point URI for the Microsoft Dynmaics NAV Web Client.	
     4. The Service Principal Names are correctly configured in the ServicePrincipal entry in AAD.	
	 5. The Microsoft Dynamics NAV administrator user is mapped to an Office 365 user account in the Microsoft Dynamics NAV database.
	
 .PARAMETER NavServerInstance	
   The name of the Microsoft Dynamics NAV server instance. If the Windows Service for Micrsoft Dynamics NAV is called 'MicrosoftDynamicsNavServer$DynamicsNAV', 	
   then the NavServerInstance is 'DynamicsNAV'.	
 .PARAMETER NavTenantId 	
   The ID of the mounted tenant if the Microsoft Dynamics NAV Server instance is configured for multitenancy - otherwise use the value 'default'.	
 .PARAMETER AADTenantIdentifierNavServer	
   The AAD tenant name or ID that is specified as part of the 	
   ClientServicesFederationMetadataLocation parameter for the Microsoft Dynamics NAV Server instance configuration.	
 .PARAMETER AADTenantIdentifierWebServer	
   The AAD tenant name or ID that is specified as part of the 	
   ACSUri parameter in the web.config file for the Microsoft Dynamics NAV Web server instance.	
 .PARAMETER ApplicationRealm	
   The value of the 'wtrealm' query string portion of the the ACSUri parameter.	
   Remark: This can be a URLEncoded string, which might need to be decoded.	
 .PARAMETER Office365AdminUserName	
   The name of the administrator user for the Office 365 subscription that is being verified.	
 .PARAMETER ScriptResourceDirectory	
   The directory where other PowerShell script resources that the current command depends on are located.	
 .PARAMETER ValidateNavServer	
   A non-empty string indicates that a Microsoft Dynamics NAV Server instance is available for validation on this computer.	
 .PARAMETER ValidateNavWebServer	
   A non-empty string indicates that the Microsoft Dynamics NAV Web Server instance is available for validation on this computer.	
#>
function Get-NavOffice365StateForSSO
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
		[AllowEmptyString()]
        [string] $NavServerInstance,

        [parameter(Mandatory=$false)]
		[AllowEmptyString()]
        [string] $NavTenantId = "default",

        [parameter(Mandatory=$true)]
		[AllowEmptyString()]
        [string] $NavWebServerInstanceName,

        [parameter(Mandatory=$true)]
		[AllowEmptyString()]
        [string] $AADTenantIdentifierNavServer,
        
        [parameter(Mandatory=$true)]
		[AllowEmptyString()]
        [string] $AADTenantIdentifierWebServer,
        
        [parameter(Mandatory=$true)]
		[AllowEmptyString()]
        [string] $ApplicationRealm, 
        
        [parameter(Mandatory=$true)]
        [string] $Office365AdminUserName, 

		[parameter(Mandatory=$true)]
        [string] $ScriptResourceDirectory = ".",

		[parameter(Mandatory=$true)]
		[AllowEmptyString()]
        [string] $ValidateNavServer,

		[parameter(Mandatory=$true)]
		[AllowEmptyString()]
        [string] $ValidateNavWebServer
    )
    PROCESS 
    {   
        # Import dependencies
        Import-Module "$ScriptResourceDirectory\BPAIntegrationUtilities.psm1" -ErrorVariable dependenciesError -ErrorAction SilentlyContinue
		if ($dependenciesError)
		{
			Write-Error "The dependent modules could not be loaded. Please make sure that the modules are correctly deployed and that you are running this cmdlet with the correct parameters."
		}

        Import-Module MSOnline -ErrorVariable msOnlineInstallationError -ErrorAction SilentlyContinue
		if ($msOnlineInstallationError)
        {      
			# The Online Services Sign-In Assistant is a BETA version of September 9, 2013. There is a Professional RTW version, but that cannot be used to install the Windows Azure AD module.
			$errorMessage = "The prerequisites for validating the Office 365 tenant configuration are not installed on this computer." + `
				"`n`tMicrosoft Online Services Sign-In Assistant for IT Professionals can be downloaded and installed from http://go.microsoft.com/fwlink/?LinkID=330113" + `
				"`n`tWindows Azure Active Directory Module for Windows PowerShell can be downloaded and installed from http://go.microsoft.com/fwlink/?LinkID=330114"
            Write-Stderr $errorMessage
			return
        }
        
        # Get Nav management assembly path based on which components need validation
        if ($ValidateNavWebServer)
        {
            $componentRegEntry = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft Dynamics NAV\90\Web Client" -ErrorAction SilentlyContinue
            $relativeAssemblyPath = "\bin\Microsoft.Dynamics.Nav.Management.dll"
        }
        if ($ValidateNavServer)
        {
            $componentRegEntry = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft Dynamics NAV\90\Service" -ErrorAction SilentlyContinue
            $relativeAssemblyPath  = "\Microsoft.Dynamics.Nav.Management.dll"
        }
        
        if ($componentRegEntry -and $componentRegEntry.Path)
        {
            $managementDllPath = Join-Path $componentRegEntry.Path $relativeAssemblyPath
        }
        
        # Import the management module
		if ($managementDllPath)
		{
			Import-Module $managementDllPath -ErrorVariable mgmDllError -ErrorAction SilentlyContinue
		}

		# If the import was not performed or did not succeed, then add the PSSnapin
        if (!($managementDllPath) -or $mgmDllError)
        {
            Add-PSSnapin Microsoft.Dynamics.Nav.Management -ErrorVariable mgmtSnapInError -ErrorAction SilentlyContinue
            if ($mgmtSnapInError)
            {
                Write-Stderr "Could not load the Microsoft.Dynamics.Nav.Management module. Please make sure that the Microsoft Dynamics NAV Server or Web Server are properly installed on the computer."
				return
            }
        }

        # The MSOL connection is validated, based on the credentials that the user entered.
        if (!(Connect-Office365 -UserName $Office365AdminUserName))
        {
            # Fail and return since there is no sense in continuing the validation steps
			$errorMessage = "Failed to connect to Office 365 with the provided credentials or the Microsoft Online service could not be contacted." + `
				"`n`tYou must use an Organizational Account (OrgID) to sign in to the Windows Azure Active Directory management service."
			Write-Stderr $errorMessage
            return
        }

		$tenantDomain = (Get-MsolCompanyInformation).InitialDomain

        if ($ValidateNavServer)        
        {
            # The client name / id specified in the Server Instance CustomSettings.config's ClientServicesFederationMetadataLocation setting is validated.
            if (!(Validate-AadTenantIdentifier -TenantIdentifier $AADTenantIdentifierNavServer))
            {
                Write-Stderr "The Windows Azure Active Directory tenant domain '$AADTenantIdentifierNavServer' that is specified in the ClientServicesFederationMetadataLocation parameter on the Microsoft Dynamics NAV Server instance does not match the tenant domain '$tenantDomain' that you specified in the Office 365 user name."
            }

            # The NAV essential user's mapping to an O365 user account is validated.
            if (!(Validate-NavUserIsConfiguedForOffice365 -NavServerInstance $NavServerInstance -NavTenantId $NavTenantId -Office365AdminUserName $Office365AdminUserName))
            {
                Write-Stderr "A Microsoft Dynamics NAV user was not mapped to the specified Office 365 User Account Email ($Office365AdminUserName)."                  
            }
        }

        if ($ValidateNavWebServer)
        {
            # The client name / id specified in the Web Server web.config's ACSUri setting is validated.
            if (!(Validate-AadTenantIdentifier -TenantIdentifier $AADTenantIdentifierWebServer))
            {
                Write-Stderr "The Windows Azure Active Directory tenant domain '$AADTenantIdentifierWebServer' that is specified in the ACSUri parameter on the Microsoft Dynamics NAV Web Server instance is not valid. Your tenant domain is: $tenantDomain."
            }

            # Gets the AAD application based on the realm specified in the ACSUri configuration setting.
			$navAadApp = Get-AadApplication -ApplicationRealm (UrlDecode-String -StringToDecode $ApplicationRealm)
			if (!$navAadApp)
			{
		        Write-Stderr "The application realm '$ApplicationRealm' that is specified in the ACSUri parameter in the Microsoft Dynamics NAV Web Server instance configuration could not be found in your Windows Azure Active Directory tenant."
			}
            else
            {
                # The Web Client Return Address is validated in the AAD tenant.
                if (!(Validate-AadApplicationReplyUrl -AadServicePrincipalForNav $navAadApp -AadTenantIdentifierWeb $AADTenantIdentifierWebServer -NavWebServerInstance $NavWebServerInstanceName))
                {
                    $invalidReturnUri = $navAadApp.Addresses.Address
                    $errorMessage = "Either the Microsoft Dynamics NAV Web Server is not started or the following Reply URL(s) for the Microsoft Dynamics NAV Web Client application are not configured correctly in Windows Azure Active Directory:" +`
			            "`n`t$invalidReturnUri" +`
			            "`n`tVerify that the Microsoft Dynamics NAV Web Server is started. For each Reply URL, make sure that at least the host name portion of the URL matches the value in the Microsoft Dynamics NAV Web Client address. For example, if the Microsoft Dynamics NAV Web Client address is https://HostName/MyInstance1/WebClient, then valid Reply URLs are: https://HostName/MyInstance1/WebClient, https://HostName/MyInstance1, or https://HostName."
                    Write-Stderr -IsWarning $errorMessage
                }

                # The AAD application's ServicePrincipalNames structure and format are validated.
                if (!(Validate-AadApplicationServicePrincipalNames -AadServicePrincipalForNav $navAadApp))
                {
                    $invalidSpns = $navAadApp.ServicePrincipalNames
                    Write-Stderr "The application's ServicePrincipalNames are not valid in the Windows Azure Active Directory tenant: $invalidSpns. One of the ServicePrincipalNames must have the same value as the ""wtrealm"" attribute in the ACSUri parameter and the other one must be the ApplicationID/ClientID."
                }
            }
        }
    }
}

function Connect-Office365([string] $UserName)
{ 
    # Connecting to Office 365 using user name/password credentials.
    Write-Host "Connecting to Office 365"
      
    $office365Credentials = Get-Credential -UserName $UserName -Message "Please enter your Office 365 user name and password:"
    
    # Connecting to Office 365. The credentials are going to be prompted for and the user, eventually automatically filling in the user name.
    if ($office365Credentials)
    {
        Connect-MsolService -Credential $office365Credentials -ErrorVariable connectError -ErrorAction SilentlyContinue
    }
    else
    {
        Connect-MsolService -ErrorVariable connectError -ErrorAction SilentlyContinue
    }

    if (!$connectError)
    {              
        $Global:O365Connection = $True
        $domain = (Get-MsolCompanyInformation).InitialDomain
        Write-Host "Successfully connected to the AAD tenant: $domain"
        return $true        
    }
    
    return $false
}

function Validate-Office365Subscription
{  
    # Check Subscription
    $subscription = Get-MsolSubscription 
    
    # Check Sku
    $skuPartNumber = $subscription.SkuPartNumber
    $midsizesku = "MIDSIZEPACK"
    $enterprisesizesku = "ENTERPRISEPACK"
        
    write-host $skuPartNumber
    if (($skuPartNumber -eq $midsizesku) -or ($skuPartNumber -eq $enterprisesizesku))
    {            
        Write-Host "Sku part number is OK."
        return $true
    }
        
    return $false    
}

function Validate-AadTenantIdentifier([string] $TenantIdentifier) 
{
	if (!$TenantIdentifier)
    {
        return $false
    }

    foreach ($domain in (Get-MsolDomain)) 
    {
        if ($domain.Name.ToLower().Equals($TenantIdentifier.ToLower()))
        {
            Write-Host "The $TenantIdentifier is the actual tenant name."
            return $true
        }
    }

    if ((Get-MsolCompanyInformation).ObjectId.ToString().ToLower().Equals($TenantIdentifier.ToLower()))
    {
        Write-Host "The $TenantIdentifier is the actual tenant ID."
        return $true;
    }

    return $false;
}

function Get-AadApplication([string] $ApplicationRealm)
{
    if (!$ApplicationRealm)
    {
        return $false
    }

    foreach ($app in (Get-MsolServicePrincipal))
    {
        foreach ($spn in $app.ServicePrincipalNames)
        {
            if ($spn.ToLower().Equals($ApplicationRealm.ToLower()))
            {
                Write-Host "Found a valid application in AAD for the following realm: $ApplicationRealm"
                return $app
            }
        }
    }

    return $null;
}

function Validate-AadApplicationReplyUrl([object] $AadServicePrincipalForNav, [string] $AadTenantIdentifierWeb, [string] $NavWebServerInstance)
{
    if (!$AadServicePrincipalForNav)
    {
        return $false
    }

    if (!$NavWebServerInstance)
    {
        $wsInstance = Get-NAVWebServerInstance
    }
    else 
    {
        $wsInstance = Get-NAVWebServerInstance -WebServerInstance $NavWebServerInstance
    }
    
    if (!$wsInstance -or ($wsInstance.Count -and $wsInstance.Count -ne 1))
    {
        return $false
    }

    Write-Host "Server instance for validation is $($wsInstance.WebServerInstance)"

    # Iterate through all AAD reply addresses
    foreach ($aadReplyAddress in $AadServicePrincipalForNav.Addresses)
    {
        Write-Host " Checking the $($aadReplyAddress.Address) ReplyURL in the AAD Service Principal."
        
        # Get the AAD Reply URI
        $aadReplyUri = New-Object -TypeName System.Uri -ArgumentList ( $aadReplyAddress.Address, [System.UriKind]::Absolute )

        # Iterate through all the web server instance registered URIs
        foreach ($iisNavEndpoint in $wsInstance.Uri.Split(','))
        {
            Write-Host "  Checking the $iisNavEndpoint address in IIS for the selected Nav Web Server instance."

            $navEndpointUri = New-Object -TypeName System.Uri -ArgumentList $iisNavEndpoint

            # Test if the web client connection is setup and redirecting to AAD before attempting to do anything
            if (!$(Test-WebClientEndpoint -AadServicePrincipalForNav $AadServicePrincipalForNav -AadTenantIdentifierWeb $AadTenantIdentifierWeb -NavEndpoint $iisNavEndpoint))
            {
                continue
            }

            # If the NAV endpoint begins with the reply address set in AAD, then the validation is complete
            if ($iisNavEndpoint.ToLower().StartsWith($aadReplyAddress.Address.ToLower()))
            {
                Write-Host "   The specified AAD application's Return URI ($NavWebAddress) is valid."
                return $true
            }
            
            # If the schemes are equal on AAD and IIS, then try to see if the hosts resolve to at leat one IP address which is the same.
            if ($aadReplyUri.Scheme -eq $navEndpointUri.Scheme -and !$aadReplyUri.DnsSafeHost.Equals($navEndpointUri.DnsSafeHost))
            {
                Write-Host "   Hosts are different. Checking if they resolve to same IP Addresses. AAD Host: $($aadReplyUri.DnsSafeHost); IIS Host: $($navEndpointUri.DnsSafeHost)"
                $aadIpAddresses = [System.Net.Dns]::GetHostAddresses($aadReplyUri.DnsSafeHost)
                $iisIpAddresses = [System.Net.Dns]::GetHostAddresses($navEndpointUri.DnsSafeHost)

                # If the schemes are the same, then we can proceed with further validation
                if ($aadIpAddresses | ? { $_.IPAddressToString -in $iisIpAddresses.IPAddressToString})
                {
                    # We next validate if the segments of the two URLs are the same
                    Write-Host "   Hosts were resolved to the same IP. Checking segments. AAD: $($aadReplyUri.Segments); IIS: $($navEndpointUri.Segments)"

                    $areUriSegmentsValid = $true
                    for ($i = 0; $i -lt $aadReplyUri.Segments.Length; $i++)
                    {
                        if (!$aadReplyUri.Segments[$i].ToLower().Equals($navEndpointUri.Segments[$i].ToLower()))
                        {
                            # If one of the segments in the NAV Web Client endpoint does not match the one on the same position in the AAD Reply URI, 
                            # then the configured Reply URI is not valid. So break the loop.
                            $areUriSegmentsValid = $false
                            break
                        }
                    }
                    
                    if ($areUriSegmentsValid)
                    {
                        Write-Host "   The specified AAD application's Return URI ($aadReplyUri) is valid."
                        return $true
                    }
                }
            }
        }
    }

    # If we reach this point, we are sure that the NAV Web Client application is not properly configured / not working properly.
    return $false
}

function Test-WebClientEndpoint([object] $AadServicePrincipalForNav, [string] $AadTenantIdentifierWeb, [string] $NavEndpoint)
{
    # Issue an HTTP request to the web client endpoint in order to ensure it redirects to AAD
    Write-Host "   Checking availability of $NavEndpoint/SignIn.aspx..."
    $responseContent = Get-HttpResponseContent "$NavEndpoint/SignIn.aspx"
    if (!$responseContent)
    {
        Write-Host "   - An error has been encountered: $responseError"
    }
            
    $aadIdentifier = Select-String "https\:\/\/login\.windows\.net\/(?<aadtenant>[^/]+)" -InputObject $responseContent | %{ $_.Matches[0].Groups['aadtenant'].Value }
    if (!$aadIdentifier)
    {
        return $false
    }

    # We now check that the NAV endpoint address leads to the ACSUri.
    Write-Host "   AAD tenant identifier that matches the pattern: $aadIdentifier"
    if ($aadIdentifier.ToLower().Equals($AadTenantIdentifierWeb.ToLower()))
    {
        $applicationRealm = Select-String "wsfed\?wa=wsignin1\.0\&amp;wtrealm=(?<apprealm>(http|https)(\://|%3a%2f%2f).[^\&]+)" -InputObject $responseContent | %{$_.Matches[0].Groups['apprealm'].Value }
        Write-Host "   NAV Web Client Application Realm: $applicationRealm"
        if ((Get-AadApplication -ApplicationRealm $applicationRealm).ObjectId -eq $AadServicePrincipalForNav.ObjectId)
        {
            Write-Host "   Successfully matched AAD Application Service Principal with Web Client"
            return $true
        }
    }
}

function Validate-AadApplicationServicePrincipalNames([object] $AadServicePrincipalForNav)
{
    if (!$AadServicePrincipalForNav)
    {
        return $false
    }

    $clientId = $AadServicePrincipalForNav.AppPrincipalId.ToString()  

    foreach ($spn in $AadServicePrincipalForNav.ServicePrincipalNames)
    {
        if ($clientId.Equals($spn))
        {
            Write-Host "The Service Principal Names for the current AAD application are valid."
            return $true
        }
    }

    return $false

    # TODO: When validating the SP App, verify that there is also a SPN which has the following format: "clientId/serverAuthorityOfRealm"
}

function Validate-NavUserIsConfiguedForOffice365([string] $NavServerInstance, [string]$NavTenantId, [string] $Office365AdminUserName)
{         
    if (!$NavServerInstance -or !$Office365AdminUserName)
    {
        return $false
    }

    if (!$NavTenantId)
    {
        $NavTenantId = "default"
    }

    Write-Host "Validating user state in the NAV database"
    Write-Host "  Nav server instance: $NavServerInstance"
    Write-Host "  Nav Admin User: $NavAdminUserName"
    Write-Host "  O365 Admin User: $Office365AdminUserName"

    # Find users emails
    $office365Emails = (Get-MsolUser).UserPrincipalName
        
    $navusers = Get-NAVServerUser $NavServerInstance -Tenant $NavTenantId -ErrorVariable getNavUserError -ErrorAction SilentlyContinue
    if ($getNavUserError)
    {
        Write-Stderr "Could not retrieve the list of Microsoft Dynamics NAV users. Exception detail is: $($getNavUserError[0].Exception)"
        return
    }

    # Match Nav users with Office 365 users
    foreach ($navUser in $navusers) 
    {
        $AuthenticationEmail = $navUser.AuthenticationEmail
        if ($AuthenticationEmail)
        {
            if ($Office365AdminUserName -eq $AuthenticationEmail)
            {
                Write-Host "Admin user $NavAdminUserName was mapped to Office 365 as $Office365AdminUserName"
                return $true                
            }
        }   
    }

    return $false
}

# SIG # Begin signature block
# MIIghQYJKoZIhvcNAQcCoIIgdjCCIHICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUrX0XrAYKCW2bkumMwCuBVLxT
# Zb6gghsfMIIEwzCCA6ugAwIBAgITMwAAAHp9lu0XI96URAAAAAAAejANBgkqhkiG
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
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFA3tdjvw
# GXqv6S1Ygp2OGo5qfvaeMIGIBgorBgEEAYI3AgEMMXoweKBagFgATQBpAGMAcgBv
# AHMAbwBmAHQAIABEAHkAbgBhAG0AaQBjAHMAIABOAEEAVgAgAEMAbwBkAGUAcwBp
# AGcAbgAgAFMAdQBiAG0AaQBzAHMAcwBpAG8AbgAuoRqAGGh0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbTANBgkqhkiG9w0BAQEFAASCAQCJ/RKLe59lfqa+eM2nzs+1hl4X
# 8RVzd8TvCkrGZgvIKU9O6H9iphMe7T76OEwYRyl+/basAGtxuu7YtVRqrzUmHZym
# PeB+hWJS3lQjZrXnULyiLGtoprYAvtD5fKobIbtCvuvhMQVAja+NPxC0vn2RB0Bn
# G7ZzqkAZIaN3v6s1dWs13raWAfdJcENjJBoPxlQcr6d8lJiYORcMkhgNxrPe7Kym
# 1N/7aCEKxXX0i+n01QorPZYo3jqFsH2bx97MsXm+ukGQ+H6goTDl0Wtj87Wb6F1A
# IganxB9ZtxqTBNXX5xi7/Y6k31lfMxiWCDbIiQzU39Y9LKujI3iB8h5xxkadoYIC
# KDCCAiQGCSqGSIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFBDQQITMwAAAHp9lu0XI96URAAAAAAAejAJBgUrDgMCGgUAoF0wGAYJKoZI
# hvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTUwOTE1MjA0NTUw
# WjAjBgkqhkiG9w0BCQQxFgQUCGazR02CQfmQRaSUZqRwXcJTy+0wDQYJKoZIhvcN
# AQEFBQAEggEAaYYLcW4lAPRAQv9ysnNv198wxb76dtH2oFltc+LYAD0iQq6Uwc80
# uF49N3oa54nNjKZPUGXrj3dkHKkUdQb6CPG9u/1t9gV6SkkjqsyY9ov3JaYIQY81
# mZe0Pd1cq/lG0PHZ3L+I/UPadaxOdIUQ3U+VZE9+ej4Tg4BEIKe1ocw44tj8m104
# sTo5/JDkwTtJzWmQP35zTHp2VXhv5rhXUUb+BJ4qX0ciJxDdzXgy4fDLgcQcWcPW
# Lvszb9tSIA+56K7Xn4HLmB7onuJCrSLde5Cum3N12f5S3ku9g73Qu5plJJhX7Bbi
# rDIJGbOayrwRdFKMnzUZlYJGUswfwMszoA==
# SIG # End signature block
