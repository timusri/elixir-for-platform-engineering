# Mix Projects & Dependencies

## Overview

Mix is Elixir's build tool and project management system. It handles dependencies, compilation, testing, and more.

## Creating a New Project

```bash
# Create a new project
mix new my_project

# Create a supervised application
mix new my_app --sup

# Create without git
mix new my_project --no-git
```

Project structure:

```
my_project/
├── lib/
│   └── my_project.ex
├── test/
│   ├── my_project_test.exs
│   └── test_helper.exs
├── mix.exs
├── README.md
└── .formatter.exs
```

## Mix.exs - Project Configuration

```elixir
defmodule MyProject.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_project,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MyProject.Application, []}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
```

## Managing Dependencies

### Adding Dependencies

Edit `mix.exs`:

```elixir
defp deps do
  [
    # Hex package
    {:httpoison, "~> 2.0"},
    
    # Git repository
    {:my_lib, git: "https://github.com/user/my_lib.git"},
    
    # Specific branch
    {:my_lib, git: "https://github.com/user/my_lib.git", branch: "develop"},
    
    # Specific tag
    {:my_lib, git: "https://github.com/user/my_lib.git", tag: "v1.0.0"},
    
    # Local path
    {:my_lib, path: "../my_lib"},
    
    # Optional dependency
    {:optional_lib, "~> 1.0", optional: true},
    
    # Only for dev/test
    {:ex_doc, "~> 0.29", only: :dev, runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
  ]
end
```

### Version Requirements

```elixir
{:plug, "~> 1.14"}   # >= 1.14.0 and < 2.0.0
{:plug, ">= 1.14.0"} # >= 1.14.0
{:plug, "== 1.14.2"} # Exactly 1.14.2
{:plug, "~> 1.14.2"} # >= 1.14.2 and < 1.15.0
```

### Dependency Commands

```bash
# Get dependencies
mix deps.get

# Update dependencies
mix deps.update --all
mix deps.update httpoison

# Check for outdated
mix hex.outdated

# Clean dependencies
mix deps.clean --all
```

## Common Mix Commands

```bash
# Compilation
mix compile
mix compile --force

# Running code
mix run
mix run script.exs
mix run -e "IO.puts('Hello')"

# Interactive shell with project
iex -S mix

# Testing
mix test
mix test test/specific_test.exs
mix test test/specific_test.exs:42  # Specific line

# Code formatting
mix format
mix format --check-formatted

# Documentation
mix docs

# Create release
mix release
```

## Environments

Elixir has three environments: `:dev`, `:test`, `:prod`

```elixir
# In mix.exs
def project do
  [
    start_permanent: Mix.env() == :prod
  ]
end

# In code
if Mix.env() == :dev do
  # Dev-only code
end
```

Run with specific environment:

```bash
MIX_ENV=prod mix compile
MIX_ENV=test mix test
```

## Configuration

### Config Files

```
config/
├── config.exs        # Base config
├── dev.exs           # Development
├── test.exs          # Testing
└── prod.exs          # Production
```

### config/config.exs

```elixir
import Config

config :my_app, MyApp.Repo,
  database: "my_app_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :my_app,
  port: 4000,
  secret_key: "dev_secret"

# Import environment specific config
import_config "#{config_env()}.exs"
```

### config/prod.exs

```elixir
import Config

config :my_app, MyApp.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :my_app,
  port: String.to_integer(System.get_env("PORT") || "4000")
```

### Runtime Configuration (config/runtime.exs)

```elixir
import Config

if config_env() == :prod do
  config :my_app,
    port: String.to_integer(System.get_env("PORT") || "4000"),
    secret: System.fetch_env!("SECRET_KEY")
end
```

### Accessing Config

```elixir
# Get config
port = Application.get_env(:my_app, :port)
port = Application.get_env(:my_app, :port, 4000)  # With default

# Get all config
config = Application.get_all_env(:my_app)

# Put config (runtime)
Application.put_env(:my_app, :port, 8080)
```

## Platform Engineering Project Example

```elixir
# mix.exs
defmodule InfraMonitor.MixProject do
  use Mix.Project

  def project do
    [
      app: :infra_monitor,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :httpoison, :ssl, :inets],
      mod: {InfraMonitor.Application, []}
    ]
  end

  defp deps do
    [
      # HTTP client
      {:httpoison, "~> 2.0"},
      
      # JSON
      {:jason, "~> 1.4"},
      
      # Kubernetes client
      {:k8s, "~> 2.0"},
      
      # Telemetry
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      
      # Prometheus metrics
      {:prom_ex, "~> 1.8"},
      
      # Clustering
      {:libcluster, "~> 3.3"},
      
      # Development & Test
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp releases do
    [
      infra_monitor: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent],
        steps: [:assemble, :tar]
      ]
    ]
  end
end
```

## Custom Mix Tasks

Create custom tasks for your project:

```elixir
# lib/mix/tasks/deploy.ex
defmodule Mix.Tasks.Deploy do
  use Mix.Task

  @shortdoc "Deploys the application"
  @moduledoc """
  Deploys the application to production.
  
  ## Usage
  
      mix deploy --env prod
  """

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, 
      switches: [env: :string],
      aliases: [e: :env]
    )
    
    env = Keyword.get(opts, :env, "prod")
    
    Mix.shell().info("Deploying to #{env}...")
    
    # Deployment logic
    build_release()
    upload_release(env)
    restart_services(env)
    
    Mix.shell().info("Deployment complete!")
  end

  defp build_release do
    Mix.shell().cmd("MIX_ENV=prod mix release")
  end

  defp upload_release(env) do
    Mix.shell().info("Uploading to #{env}...")
    # Upload logic
  end

  defp restart_services(env) do
    Mix.shell().info("Restarting services in #{env}...")
    # Restart logic
  end
end
```

Run it:

```bash
mix deploy --env prod
```

## Umbrella Projects

For large projects, use umbrella structure:

```bash
mix new my_umbrella --umbrella

cd my_umbrella/apps
mix new core
mix new web --sup
```

Structure:

```
my_umbrella/
├── apps/
│   ├── core/
│   │   ├── lib/
│   │   └── mix.exs
│   └── web/
│       ├── lib/
│       └── mix.exs
├── config/
└── mix.exs
```

## Project Best Practices

### 1. Code Organization

```
lib/
├── my_app/
│   ├── application.ex
│   ├── core/              # Business logic
│   │   ├── service.ex
│   │   └── worker.ex
│   ├── api/               # External API
│   │   ├── router.ex
│   │   └── handlers/
│   ├── providers/         # Integrations
│   │   ├── aws.ex
│   │   └── kubernetes.ex
│   └── utils/             # Utilities
└── my_app.ex              # Public API
```

### 2. Aliases

Define common workflows:

```elixir
# In mix.exs
def project do
  [
    # ...
    aliases: aliases()
  ]
end

defp aliases do
  [
    setup: ["deps.get", "ecto.setup"],
    "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
    "ecto.reset": ["ecto.drop", "ecto.setup"],
    test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
    quality: ["format --check-formatted", "credo --strict", "dialyzer"]
  ]
end
```

### 3. Development Tools

```elixir
defp deps do
  [
    # Code quality
    {:credo, "~> 1.7", only: [:dev, :test]},
    {:dialyxir, "~> 1.3", only: [:dev]},
    
    # Documentation
    {:ex_doc, "~> 0.29", only: :dev},
    
    # Testing
    {:mock, "~> 0.3", only: :test},
    {:excoveralls, "~> 0.16", only: :test}
  ]
end
```

## Key Takeaways

1. **Mix**: Build tool and project manager
2. **Dependencies**: Use Hex packages and Git repos
3. **Environments**: :dev, :test, :prod
4. **Configuration**: Environment-specific config files
5. **Custom Tasks**: Automate common workflows
6. **Umbrella**: For large, multi-app projects

## What's Next?

- [Testing with ExUnit](05-testing.md)

## Additional Resources

- [Mix Documentation](https://hexdocs.pm/mix)
- [Hex Package Manager](https://hex.pm)
- [Mix Tasks Guide](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html)

