# Build stage
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY src/ZavaStorefront.csproj .
RUN dotnet restore "ZavaStorefront.csproj"

# Copy remaining source code
COPY src/ .

# Build the application
RUN dotnet build "ZavaStorefront.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "ZavaStorefront.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS final
WORKDIR /app

# Create a non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy published app
COPY --from=publish /app/publish .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port 8080 (standard for container apps)
EXPOSE 8080

# Set environment variable to listen on port 8080
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
