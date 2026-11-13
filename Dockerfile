# One Dockerfile, two images. Pick the flavor with --target:
#   plain     no agent
#   newrelic  New Relic .NET agent (CLR profiler)

# Build the app once
FROM mcr.microsoft.com/dotnet/sdk:8.0@sha256:35792ea4ad1db051981f62b313f1be3b46b1f45cadbaa3c288cd0d3056eefb83 AS build-env
# Optional: trust an extra CA (for local builds behind TLS inspection). Pass it with
#   docker build --secret id=extra_ca,src=ca.pem ...
# Does nothing when the secret is absent, so CI builds are unaffected.
RUN --mount=type=secret,id=extra_ca \
    if [ -s /run/secrets/extra_ca ]; then \
      cp /run/secrets/extra_ca /usr/local/share/ca-certificates/extra-ca.crt && update-ca-certificates; \
    fi
WORKDIR /App
COPY . ./
RUN dotnet restore
RUN dotnet publish -c Release -o out

# Shared runtime base
FROM mcr.microsoft.com/dotnet/aspnet:8.0@sha256:6c4df091e4e531bb93bdbfe7e7f0998e7ced344f54426b7e874116a3dc3233ff AS base
RUN --mount=type=secret,id=extra_ca \
    if [ -s /run/secrets/extra_ca ]; then \
      cp /run/secrets/extra_ca /usr/local/share/ca-certificates/extra-ca.crt && update-ca-certificates; \
    fi
WORKDIR /App
EXPOSE 5100

FROM base AS plain
COPY --from=build-env /App/out .
ENTRYPOINT ["dotnet", "weather.dll"]

FROM base AS newrelic
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates gnupg \
 && wget -qO- https://download.newrelic.com/548C16BF.gpg | gpg --dearmor -o /usr/share/keyrings/newrelic.gpg \
 && echo 'deb [signed-by=/usr/share/keyrings/newrelic.gpg] http://apt.newrelic.com/debian/ newrelic non-free' > /etc/apt/sources.list.d/newrelic.list \
 && apt-get update && apt-get install -y newrelic-dotnet-agent \
 && rm -rf /var/lib/apt/lists/*
ENV CORECLR_ENABLE_PROFILING=1 \
    CORECLR_PROFILER={36032161-FFC0-4B61-B559-F6C5D41BAE5A} \
    CORECLR_NEWRELIC_HOME=/usr/local/newrelic-dotnet-agent \
    CORECLR_PROFILER_PATH=/usr/local/newrelic-dotnet-agent/libNewRelicProfiler.so \
    NEW_RELIC_APP_NAME=doodle-weather
COPY --from=build-env /App/out .
ENTRYPOINT ["dotnet", "weather.dll"]
