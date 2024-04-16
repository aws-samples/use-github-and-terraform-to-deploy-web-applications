# Use the official .NET Core runtime image for Linux as the base image
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy the contents of your .NET web application to the container's working directory
COPY . .

# Expose port for the web application
EXPOSE 8080

# Set the entry point to run the web application when the container starts
ENTRYPOINT ["dotnet", "mswebapp.dll"]