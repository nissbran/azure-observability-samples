FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["BookingProcessor.csproj", "."]
RUN dotnet restore "./BookingProcessor.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "BookingProcessor.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "BookingProcessor.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /ap
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "BookingProcessor.dll"]