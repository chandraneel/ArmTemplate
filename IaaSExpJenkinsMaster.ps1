Configuration IaaSExpJenkins
{
    Import-DscResource -module xWebAdministration,xRemoteDesktopAdmin, xNetworking, xSystemSecurity
	#Install the IIS Role
	WindowsOptionalFeature IIS
	{
	  Ensure = “Enable”
	  Name = “Web-Server”
	}

	#Install .NET 3.5
	WindowsOptionalFeature NET-Framework-Core
	{
	  Ensure = “Enable”
	  Name = “NET-Framework-Core”
	}

	#Install .NET 4.5
	WindowsOptionalFeature NET-Framework-45-Core
	{
	  Ensure = “Enable”
	  Name = “NET-Framework-45-Core”
	}

	#Install .NET 4.5
	WindowsOptionalFeature NET-Framework-45-ASPNET
	{
	  Ensure = “Enable”
	  Name = “NET-Framework-45-ASPNET”
	}

	#Install Web server ASP.NET 4.5 Application Development ASP.NET 4.5
	WindowsOptionalFeature ASP
	{
	  Ensure = “Enable”
	  Name = “Web-Asp-Net45”
	}

	# Stop the default website 
	xWebsite DefaultSite  
	{  
		Ensure          = "Present"  
		Name            = "Default Web Site"  
		State           = "Stopped"  
		PhysicalPath    = "C:\inetpub\wwwroot"  
		DependsOn       = "[WindowsOptionalFeature]IIS"  
	}

	xRemoteDesktopAdmin RemoteDesktopSettings
	{
		Ensure = 'Present'
		UserAuthentication = 'Secure'
	}

	xFirewall AllowRDP
	{
		Name = 'DSC - Remote Desktop Admin Connections'
		DisplayGroup = "Remote Desktop"
		Ensure = 'Present'
		State = 'Enabled'
		Access = 'Allow'
		Profile = 'Domain'
	}

	# Add Port 80, 443 and 8080 (Jenkins website) and Port 49175 (Jenkins JNLP - for Java WebStart)
	xFirewall Firewall
	{
		Name                  = "JenkinsIaaSRule"
		DisplayName           = "Firewall Rules for Jenkins"
		DisplayGroup          = "Jenkins Master"
		Ensure                = "Present"
		Access                = "Allow"
		State                 = "Enabled"
		Profile               = ("Domain", "Private")
		Direction             = "InBound"
		LocalPort             = ("80", "443", "8080", "49175")         
		Protocol              = "TCP"
		Description           = "Firewall Rules for Jenkins"  
	}

	# Disable IE Enhanced Security 
	xIEEsc DisableIEEsc 
	{ 
		IsEnabled = $false 
		UserRole = "Administrators" 
	} 

	Script InstallCustomApps
	{
	  GetScript = {
			@{
				Result = ""
			}
		}
		TestScript = {
			Test-Path "$env:ProgramFiles(x86)\Jenkins\jenkins.exe"
			Test-Path "$env:ProgramFiles\Java"
		}
		SetScript ={
            #install chocolatey
		    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
            choco install -y jre8
		    choco install -y java.jdk
            choco install -y jenkins
		    choco install -y urlrewrite
		    choco install -y sourcetree
            choco install -y googlechrome
		}		
	}
    
    Script InstallJenkinsPlugins
	{
	  GetScript = {
			@{
				Result = ""
			}
		}
		TestScript = {
			Test-Path "$env:ProgramFiles(x86)\Jenkins\plugins\ws-cleanup.hpi"
		}
		SetScript ={
            net stop jenkins
            Write-Output "Downloading jenkins plugins"
            $prgmsPath = ${env:ProgramFiles(x86)}
            $jenkinsPath = [System.IO.Path]::Combine($prgmsPath, "Jenkins\plugins\") 
	        $jenkinsPlugins = get-content "C:\Program Files\WindowsPowerShell\Modules\xWebAdministration\jenkinsPlugins.txt" 
			$clnt = New-Object System.Net.WebClient

            foreach($url in $jenkinsPlugins) 
            { 
	            #Get the filename 
	            $filename = [System.IO.Path]::GetFileName($url) 
 
	            #Create the output path 
	            $file = [System.IO.Path]::Combine($jenkinsPath, $filename) 
 
	            Write-Host -NoNewline "Getting ""$url""... "
 
	            #Download the file using the WebClient
                try { 
	                $clnt.DownloadFile($url, $file)
                } catch {
                    Write-Host $_.Exception.InnerException            
                }

                net start jenkins
	            Write-Host "done." 
            }
		}		
	}
} 