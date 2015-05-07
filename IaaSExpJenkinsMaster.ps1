Configuration IaaSExpJenkins
{
    Import-DscResource -module PSDesiredStateConfiguration, xWebAdministration,xRemoteDesktopAdmin, xNetworking, xSystemSecurity
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
			Test-Path "$env:ProgramFiles(x86)\Atlassian\SourceTree\SourceTree.exe"
		}
		SetScript ={
		  #install chocolatey
		  iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
          choco install -y jre8
		  choco install -y java.jdk
		  choco install -y urlrewrite
		  choco install -y sourcetree
		  choco install -y jenkins
          choco install -y googlechrome
		}
		
	}
} 