# FROM mcr.microsoft.com/dotnet/sdk:9.0-windowsservercore-ltsc2022 AS build-env
# WORKDIR /app

# # Copy everything
# COPY . ./
# RUN  dotnet restore 

# # Build and publish a release
# RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:9.0-windowsservercore-ltsc2022
# FROM mcr.microsoft.com/dotnet/aspnet:9.0-nanoserver-ltsc2022   

# Download the New Relic .NET agent installer
RUN powershell.exe [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;\
 Invoke-WebRequest "https://download.newrelic.com/dot_net_agent/latest_release/NewRelicDotNetAgent_x64.msi"\
 -UseBasicParsing -OutFile "NewRelicDotNetAgent_x64.msi"

# Install the New Relic .NET agent
RUN powershell.exe Start-Process -Wait -FilePath msiexec -ArgumentList /i, "NewRelicDotNetAgent_x64.msi", /qn,\
 NR_LICENSE_KEY=12c7dcd093dace50b700d4d3af375553FFFFNRAL

# Remove the New Relic .NET agent installer
RUN powershell.exe Remove-Item "NewRelicDotNetAgent_x64.msi"

# Enable the agent
ENV CORECLR_ENABLE_PROFILING=1

# Set your application name
ENV NEW_RELIC_APP_NAME=doodle-weather-win

WORKDIR /app
COPY --from=build-env /app/out .
EXPOSE 5100
USER ContainerUser
ENTRYPOINT ["helpdotnet.exe"]
