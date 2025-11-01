# Releases & Deployment

## Overview

Creating production releases involves compiling your application into a self-contained package that can be deployed without requiring Elixir or Mix on the target system.

## Mix Releases

Elixir 1.9+ includes built-in release functionality.

### Creating a Release

```bash
# Build release
MIX_ENV=prod mix release

# Release is created in _build/prod/rel/my_app/
```

### Release Configuration

```elixir
# mix.exs
def project do
  [
    app: :my_app,
    version: "1.0.0",
    releases: releases()
  ]
end

defp releases do
  [
    my_app: [
      include_executables_for: [:unix],
      applications: [runtime_tools: :permanent],
      steps: [:assemble, :tar]
    ]
  ]
end
```

### Runtime Configuration

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  database_url = System.fetch_env!("DATABASE_URL")
  
  config :my_app, MyApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base = System.fetch_env!("SECRET_KEY_BASE")
  
  config :my_app, MyAppWeb.Endpoint,
    http: [port: String.to_integer(System.get_env("PORT") || "4000")],
    secret_key_base: secret_key_base
end
```

## Deploying Releases

### Running the Release

```bash
# Start in foreground
_build/prod/rel/my_app/bin/my_app start

# Start as daemon
_build/prod/rel/my_app/bin/my_app daemon

# Stop
_build/prod/rel/my_app/bin/my_app stop

# Remote console
_build/prod/rel/my_app/bin/my_app remote

# Run migrations
_build/prod/rel/my_app/bin/my_app eval "MyApp.Release.migrate()"
```

### Systemd Service

```ini
# /etc/systemd/system/my_app.service
[Unit]
Description=My App
After=network.target

[Service]
Type=simple
User=my_app
Group=my_app
WorkingDirectory=/opt/my_app
Environment="PORT=4000"
Environment="DATABASE_URL=ecto://..."
ExecStart=/opt/my_app/bin/my_app start
ExecStop=/opt/my_app/bin/my_app stop
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl enable my_app
sudo systemctl start my_app

# Check status
sudo systemctl status my_app

# View logs
sudo journalctl -u my_app -f
```

## Docker Deployment

### Multi-Stage Dockerfile

```dockerfile
# Build stage
FROM elixir:1.15-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy source
COPY lib lib
COPY config config

# Compile and build release
RUN mix compile
RUN mix release

# Runtime stage
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs libstdc++

WORKDIR /app

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/my_app ./

# Create user
RUN adduser -D my_app
USER my_app

EXPOSE 4000

CMD ["/app/bin/my_app", "start"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "4000:4000"
    environment:
      - DATABASE_URL=ecto://postgres:postgres@db:5432/my_app
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=my_app
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

## Kubernetes Deployment

### Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: myregistry/my-app:1.0.0
        ports:
        - containerPort: 4000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: my-app-secrets
              key: database-url
        - name: SECRET_KEY_BASE
          valueFrom:
            secretKeyRef:
              name: my-app-secrets
              key: secret-key-base
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 4000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 4000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 4000
  type: LoadBalancer
```

## Hot Upgrades

Hot code swapping allows updating without stopping:

```elixir
# Create appup file
# rel/my_app.appup
{"1.0.1",
  [{"1.0.0", [{:update, MyApp.Worker, {:advanced, []}}]}],
  [{"1.0.0", [{:update, MyApp.Worker, {:advanced, []}}]}]
}

# Build upgrade release
MIX_ENV=prod mix release --upgrade
```

```bash
# Apply upgrade
bin/my_app upgrade "1.0.1"
```

## CI/CD Pipeline

### GitHub Actions

```yaml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Elixir
      uses: erlef/setup-beam@v1
      with:
        elixir-version: '1.15'
        otp-version: '26'
    
    - name: Restore dependencies cache
      uses: actions/cache@v3
      with:
        path: deps
        key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
    
    - name: Install dependencies
      run: mix deps.get
    
    - name: Run tests
      run: mix test

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build and push Docker image
      run: |
        docker build -t myregistry/my-app:${{ github.sha }} .
        docker push myregistry/my-app:${{ github.sha }}
    
    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/my-app \
          my-app=myregistry/my-app:${{ github.sha }}
```

## Monitoring Deployments

```elixir
defmodule MyApp.Release do
  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(:my_app)
    Application.fetch_env!(:my_app, :ecto_repos)
  end
end
```

## Key Takeaways

1. **Mix releases**: Self-contained packages
2. **Docker**: Containerized deployments
3. **Kubernetes**: Orchestrated scaling
4. **CI/CD**: Automated pipelines
5. **Hot upgrades**: Zero-downtime updates

## Additional Resources

- [Mix Release Documentation](https://hexdocs.pm/mix/Mix.Tasks.Release.html)
- [Distillery (alternative)](https://hexdocs.pm/distillery/)
- [Elixir in Production](https://dashbit.co/ebooks/elixir-in-production)

