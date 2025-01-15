FROM mcr.microsoft.com/dotnet/sdk:9.0-windowsservercore-ltsc2022 AS build-env
WORKDIR /app

# Copy everything
COPY . ./
RUN  dotnet restore 

# Build and publish a release
RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:9.0-nanoserver-ltsc2022   

WORKDIR /app
COPY --from=build-env /app/out .
EXPOSE 5100
USER ContainerUser
ENTRYPOINT ["helpdotnet.exe"]
