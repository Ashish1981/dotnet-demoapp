# =======================================================
# Stage 1 - Build/compile app using container
# =======================================================

#ARG IMAGE_BASE=6.0-alpine

# Build image has SDK and tools (Linux)
#FROM mcr.microsoft.com/dotnet/sdk:$IMAGE_BASE as build
#FROM localhost/ashish1981/dotnet-60
FROM registry.redhat.io/rhel8/dotnet-60 as build
#WORKDIR /build
WORKDIR /opt/app-root
# Copy project source files
COPY src ./src
USER root
# Restore, build & publish
WORKDIR /opt/app-root/src
RUN dotnet restore
RUN dotnet publish --no-restore --configuration Release

# =======================================================
# Stage 2 - Assemble runtime image from previous stage
# =======================================================

# Base image is .NET Core runtime only (Linux)
#FROM mcr.microsoft.com/dotnet/aspnet:$IMAGE_BASE
FROM registry.redhat.io/rhel8/dotnet-60-runtime
# Metadata in Label Schema format (http://label-schema.org)
LABEL org.label-schema.name    = ".NET Core Demo Web App" \
      org.label-schema.version = "1.5.0" \
      org.label-schema.vendor  = "Ashish Sahoo" \
      org.opencontainers.image.source = "https://github.com/Ashish1981/dotnet-demoapp"
# USER root
# Seems as good a place as any
WORKDIR /opt/app-root/app

# Copy already published binaries (from build stage image)
COPY --from=build /opt/app-root/src/bin/Release/net6.0/publish/ .

# Expose port 5000 from Kestrel webserver
EXPOSE 5000 
# Tell Kestrel to listen on port 5000 and serve plain HTTP
ENV ASPNETCORE_URLS http://*:5000
ENV ASPNETCORE_ENVIRONMENT Production
# This is critical for the Azure AD signin flow to work in Kubernetes and App Service
ENV ASPNETCORE_FORWARDEDHEADERS_ENABLED=true

# Run the ASP.NET Core app
ENTRYPOINT dotnet dotnet-demoapp.dll
