# ============================================
# Dockerfile cho PCM.Backend (Vợt Thủ Phố Núi)
# ============================================
# LƯU Ý: Project đang dùng .NET 10, nhưng Docker chưa có image .NET 10
# Giải pháp: Đổi TargetFramework trong .csproj về net8.0 trước khi build
# Hoặc sử dụng .NET 9.0 preview nếu có

# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj và restore dependencies
COPY ["PCM.Backend.csproj", "./"]
RUN dotnet restore "PCM.Backend.csproj"

# Copy toàn bộ source code
COPY . .

# Build project
RUN dotnet build "PCM.Backend.csproj" -c Release -o /app/build

# Stage 2: Publish
FROM build AS publish
RUN dotnet publish "PCM.Backend.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 3: Runtime (image nhẹ, chỉ chứa runtime)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Tạo thư mục cho database SQLite
RUN mkdir -p /app/data

# Copy file đã publish
COPY --from=publish /app/publish .

# Expose port
EXPOSE 8080

# Biến môi trường
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

# Chạy ứng dụng
ENTRYPOINT ["dotnet", "PCM.Backend.dll"]
