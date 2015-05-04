Configuration IaaSExpJenkins
{
	#Install the IIS Role
	WindowsFeature IIS
	{
	  Ensure = “Present”
	  Name = “Web-Server”
	}

	#Install .NET 3.5
	WindowsFeature NET-Framework-Core
	{
	  Ensure = “Present”
	  Name = “NET-Framework-Core”
	}

	#Install .NET 4.5
	WindowsFeature NET-Framework-45-Core
	{
	  Ensure = “Present”
	  Name = “NET-Framework-45-Core”
	}

	#Install .NET 4.5
	WindowsFeature NET-Framework-45-ASPNET
	{
	  Ensure = “Present”
	  Name = “NET-Framework-45-ASPNET”
	}

	#Install Web server ASP.NET 4.5 Application Development ASP.NET 4.5
	WindowsFeature ASP
	{
	  Ensure = “Present”
	  Name = “Web-Asp-Net45”
	}

	Import-DscResource -Module xWebAdministration 

	# Stop the default website 
	MSFT_xWebsite DefaultSite  
	{  
		Ensure          = "Present"  
		Name            = "Default Web Site"  
		State           = "Stopped"  
		PhysicalPath    = "C:\inetpub\wwwroot"  
		DependsOn       = "[WindowsFeature]IIS"  
	}

	Import-DscResource -Module xRemoteDesktopAdmin, xNetworking

	xRemoteDesktopAdmin RemoteDesktopSettings
	{
		Ensure = 'Present'
		UserAuthentication = 'Secure'
	}

	MSFT_xFirewall AllowRDP
	{
		Name = 'DSC - Remote Desktop Admin Connections'
		DisplayGroup = "Remote Desktop"
		Ensure = 'Present'
		State = 'Enabled'
		Access = 'Allow'
		Profile = 'Domain'
	}

	# Add Port 80, 443 and 8080 (Jenkins website) and Port 49175 (Jenkins JNLP - for Java WebStart)
	MSFT_xFirewall Firewall
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


	Import-DSCResource -Module xSystemSecurity -Name xIEEsc 

	# Disable IE Enhanced Security 
	xIEEsc DisableIEEsc 
	{ 
		IsEnabled = $false 
		UserRole = "Administrators" 
	} 

	#Install Chrome
	Import-DscResource -module xChrome 
	Import-DscResource -module xPSDesiredStateConfiguration

	MSFT_xChrome chrome 
	{ 
		
	} 

	#Download and install Reverse proxy
	MSFT_xRemoteFile Downloader
	{
		Uri = "https://github.com/azure/iisnode/releases/download/v0.2.11/iisnode-full-v0.2.11-x64.msi" 
		DestinationPath = "$env:SystemDrive\Windows\DtlDownloads\iisnode-full-v0.2.11-x64.msi"
	}

	MSFT_xPackageResource Installer
	{
		Ensure = "Present"
		Path = "$env:SystemDrive\Windows\DtlDownloads\iisnode-full-v0.2.11-x64.msi"
		Name = "iisnode for iis 7.x (x64) full"
		ProductId = 'E6141C88-1E55-4453-B0F0-72AF015AEF92'
		DependsOn = "[MSFT_xRemoteFile]Downloader"
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
		  choco install -y java.jdk
		  choco install -y urlrewrite
		  choco install -y sourcetree
		  choco install -y jenkins
		}
		
	}
} 