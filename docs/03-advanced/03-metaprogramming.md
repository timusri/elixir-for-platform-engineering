# Metaprogramming & Macros

## Overview

Metaprogramming in Elixir allows you to write code that writes code. Macros enable you to extend the language and create domain-specific languages (DSLs).

## Understanding Macros

Macros transform code at compile time. They receive AST (Abstract Syntax Tree) and return transformed AST.

### Quote and Unquote

```elixir
# Quote converts code to AST
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}

# Unquote injects values into quoted expressions
iex> value = 42
iex> quote do: unquote(value) + 1
{:+, [context: Elixir, import: Kernel], [42, 1]}
```

### Simple Macro

```elixir
defmodule MyMacros do
  defmacro say_hello(name) do
    quote do
      IO.puts("Hello, #{unquote(name)}!")
    end
  end
end

# Usage
require MyMacros
MyMacros.say_hello("Platform")
# Outputs: Hello, Platform!
```

## Platform Engineering DSL Example: Configuration

```elixir
defmodule ConfigDSL do
  defmacro __using__(_opts) do
    quote do
      import ConfigDSL
      @config %{}
      
      @before_compile ConfigDSL
    end
  end

  defmacro service(name, do: block) do
    quote do
      @config Map.put(@config, unquote(name), %{})
      unquote(block)
    end
  end

  defmacro url(value) do
    quote do
      service_name = get_current_service()
      @config update_in(@config[service_name], &Map.put(&1, :url, unquote(value)))
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def get_config, do: @config
    end
  end
end

# Usage
defmodule MyServices do
  use ConfigDSL

  service :api do
    url "http://api.example.com"
    timeout 5000
  end

  service :database do
    url "postgres://localhost/db"
    pool_size 10
  end
end
```

## Code Generation

Macros can generate repetitive code:

```elixir
defmodule HTTPStatus do
  statuses = [
    {200, :ok, "OK"},
    {201, :created, "Created"},
    {404, :not_found, "Not Found"},
    {500, :internal_server_error, "Internal Server Error"}
  ]

  for {code, atom, message} <- statuses do
    def code_to_atom(unquote(code)), do: unquote(atom)
    def atom_to_code(unquote(atom)), do: unquote(code)
    def atom_to_message(unquote(atom)), do: unquote(message)
  end
end

HTTPStatus.code_to_atom(200)  # :ok
HTTPStatus.atom_to_message(:not_found)  # "Not Found"
```

## Practical Example: Deployment DSL

```elixir
defmodule DeploymentDSL do
  defmacro __using__(_opts) do
    quote do
      import DeploymentDSL
      Module.register_attribute(__MODULE__, :stages, accumulate: true)
      
      @before_compile DeploymentDSL
    end
  end

  defmacro stage(name, opts, do: block) do
    quote do
      @stages {unquote(name), unquote(opts), fn -> unquote(block) end}
    end
  end

  defmacro run(command) do
    quote do
      System.cmd("sh", ["-c", unquote(command)])
    end
  end

  defmacro on_failure(do: block) do
    quote do
      try do
        :ok
      rescue
        e -> unquote(block)
                raise e
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def deploy do
        Enum.each(@stages, fn {name, opts, fun} ->
          IO.puts("Running stage: #{name}")
          fun.()
        end)
      end

      def list_stages do
        Enum.map(@stages, fn {name, opts, _} -> {name, opts} end)
      end
    end
  end
end

# Usage
defmodule MyDeployment do
  use DeploymentDSL

  stage :build, env: :prod do
    run "mix deps.get"
    run "mix compile"
    run "mix release"
  end

  stage :test, env: :prod do
    run "mix test"
    
    on_failure do
      IO.puts("Tests failed! Rolling back...")
    end
  end

  stage :deploy, env: :prod do
    run "scp _build/prod/rel/myapp.tar.gz server:/tmp/"
    run "ssh server 'tar -xzf /tmp/myapp.tar.gz'"
  end
end

MyDeployment.deploy()
```

## Use Sparingly

**When to use macros:**
- Eliminating boilerplate
- Creating DSLs
- Compile-time optimizations

**When NOT to use macros:**
- Can be solved with functions
- Would make code harder to understand
- Runtime computation

## Key Takeaways

1. **Macros**: Transform code at compile time
2. **Quote/Unquote**: Work with AST
3. **DSLs**: Create domain-specific languages
4. **Code generation**: Eliminate boilerplate
5. **Use sparingly**: Functions are usually better

## Additional Resources

- [Elixir Metaprogramming](https://elixir-lang.org/getting-started/meta/quote-and-unquote.html)
- [Metaprogramming Elixir Book](https://pragprog.com/titles/cmelixir/metaprogramming-elixir/)

