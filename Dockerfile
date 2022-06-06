FROM mcr.microsoft.com/dotnet/aspnet:3.1
COPY dist /app
WORKDIR /app
EXPOSE 80/tcp
ENTRYPOINT exec dotnet ExampleApp.dll