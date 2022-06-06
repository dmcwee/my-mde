<#
 .Synopsis
  Get the status of MDE on the current machine

 .Description
  This command reads the status registry variables an describes the current state of MDE installation and onboarding
  of the machine.

 .Example
  Get-MyMDEStatus
#>
function Get-MyMDEStatus {

    $outputProperties = @{
        IsOnboarded = $false
        Onboarded = "Thi devices IS NOT onboarded"
        LastConnected = ""
        TenantId = ""
        GlobalLocation = ""
        DataCenter = ""
    }

    $myObj = New-Object psobject -Property $outputProperties
    $mdeKey = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection" -ErrorAction SilentlyContinue
    
    if($null -ne $mdeKey) {
        $onboardInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection" -Name OnboardedInfo -ErrorAction SilentlyContinue
        if($null -ne $onboardInfo) {
            $onboardInfoObj = ConvertFrom-Json $onboardInfo.OnboardedInfo
            $onboardInfoBody = ConvertFrom-Json $onboardInfoObj.body

            $myObj.GlobalLocation = $onboardInfoBody.vortexGeoLocation
            $myObj.DataCenter = $onboardInfoBody.datacenter
        }
        else {
            $myObj.GlobalLocation = "Unable to read OnboardedInfo Property from 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection'"
        }

        $status = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status"
        if($null -ne $status) {
            $isOnboarded = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status" -Name OnboardingState -ErrorAction SilentlyContinue
            if($null -ne $isOnboarded) {
                if($isOnboarded.OnboardingState) {
                    $myObj.Onboarded = "This device IS onboarded!"
                    $myObj.IsOnboarded = $true
                }
            }
            else {
                $myObj.Onboarded = "Unable to read OnboardingState Property from 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status'"
            }

            $lastConnected = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status" -Name LastConnected -ErrorAction SilentlyContinue
            if($null -ne $lastConnected){
                $myObj.LastConnected = [datetime]::FromFileTime($lastConnected.LastConnected)
            }
            else {
                $myObj.LastConnected = "Unable to read LastConnected Property from 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status'"
            }

            $orgId = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status" -Name OrgId -ErrorAction SilentlyContinue
            if($null -ne $orgId) {
                $myObj.TenantId = $orgId.OrgId
            }
            else {
                $myObj.TenantId = "Unable to read OrgId Property from 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status'"
            }
        }
        else {
            $myObj.Onboarded = "MDE Status Registry Key could not be found or you don't have permissions to read this."
        }
    }
    else {
        $myObj.Onboarded = "MDE Registry Key could not be found or you don't have permissions to read this."
    }

    Write-Host $myObj.Onboarded
    if($myObj.IsOnboarded) {
        Write-Host "    Last Connection with MDE:" $myObj.LastConnected
        Write-Host "    Onboarded To Tenant:" $myObj.TenantId
        Write-Host "    Data Center Location:" $myObj.GlobalLocation
        Write-Host "    Global Location:"$myObj.DataCenter
    }

}