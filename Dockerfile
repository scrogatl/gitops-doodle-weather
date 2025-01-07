FROM mcr.microsoft.com/dotnet/framework/runtime:4.8.1-20231114-windowsservercore-ltsc2022 AS build-env

# Copy everything
COPY . ./

# Restore as distinct layers
RUN dotnet restore

# Build and publish a release
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/framework/runtime:4.8.1-20231114-windowsservercore-ltsc2022

# Download the New Relic .NET agent installer
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;\
 Invoke-WebRequest "https://download.newrelic.com/dot_net_agent/latest_release/NewRelicDotNetAgent_x64.msi"\
 -UseBasicParsing -OutFile "NewRelicDotNetAgent_x64.msi"

# Install the New Relic .NET agent
RUN Start-Process -Wait -FilePath msiexec -ArgumentList /i, "NewRelicDotNetAgent_x64.msi", /qn,\
 NR_LICENSE_KEY=12c7dcd093dace50b700d4d3af375553FFFFNRAL

# Remove the New Relic .NET agent installer
RUN Remove-Item "NewRelicDotNetAgent_x64.msi"

ENV NEW_RELIC_APP_NAME=doodle-weather

WORKDIR /App
COPY --from=build-env /App/out .
EXPOSE 5100
ENTRYPOINT ["dotnet", "helpdotnet.dll"]
