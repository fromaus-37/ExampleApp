FROM mcr.microsoft.com/dotnet/aspnet:5.0
COPY dist /app
COPY node_modules/wait-for-it.sh/bin/wait-for-it /app/wait-for-it.sh
RUN chmod +x /app/wait-for-it.sh
WORKDIR /app
EXPOSE 80/tcp
ENTRYPOINT exec dotnet ExampleApp.dll