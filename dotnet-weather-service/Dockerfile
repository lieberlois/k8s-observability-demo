FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine AS build
WORKDIR /src

COPY ./src .
RUN dotnet restore
RUN dotnet publish -c release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:6.0-alpine 
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "dotnet-weather-service.dll"]