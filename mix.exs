defmodule NervesSystemX8664Kiosk.MixProject do
  use Mix.Project

  # Custom Nerves system for the Higole F9B Pro (Intel N95 / Alder Lake-N) kiosk.
  # Forked from nerves-project/nerves_system_x86_64 v1.33.5 (OTP 28 / Linux 6.12).
  # Changes vs. upstream: added real-hardware kernel drivers (i915, MIPI-DSI panel,
  # Intel LPSS I2C + Goodix touch, RTL8125/r8169, RTL8821CE/rtw88), i915 firmware,
  # DSI panel rotation on the kernel cmdline, and a Wayland kiosk browser userland.
  @github_organization "nerves-project"
  @app :nerves_system_x86_64_kiosk
  @source_url "https://github.com/#{@github_organization}/nerves_system_x86_64"
  @version Path.join(__DIR__, "VERSION")
           |> File.read!()
           |> String.trim()

  def project do
    [
      app: @app,
      version: @version,
      # Because we're using OTP 27, we need to enforce Elixir 1.17 or later.
      elixir: "~> 1.17",
      compilers: Mix.compilers() ++ [:nerves_package],
      nerves_package: nerves_package(),
      description: description(),
      package: package(),
      deps: deps(),
      aliases: [loadconfig: [&bootstrap/1]],
      docs: docs()
    ]
  end

  def application do
    []
  end

  defp bootstrap(args) do
    set_target()
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  def cli do
    [preferred_envs: %{docs: :docs, "hex.build": :docs, "hex.publish": :docs}]
  end

  defp nerves_package do
    [
      type: :system,
      # Local fork: no prebuilt artifact exists, so don't advertise a download site —
      # Nerves builds it from source (as a path dependency). Publish + add a site here
      # if you ever host prebuilt artifacts for this custom system.
      artifact_sites: [],
      build_runner_opts: build_runner_opts(),
      platform: Nerves.System.BR,
      platform_config: [
        defconfig: "nerves_defconfig"
      ],
      # The :env key is an optional experimental feature for adding environment
      # variables to the crosscompile environment. These are intended for
      # llvm-based tooling that may need more precise processor information.
      env: [
        {"TARGET_ARCH", "x86_64"},
        {"TARGET_OS", "linux"},
        {"TARGET_ABI", "musl"},
        {"TARGET_GCC_FLAGS", "-m64 -fstack-protector-strong -march=x86-64 -fPIE -pie -Wl,-z,now -Wl,-z,relro"}
      ],
      checksum: package_files()
    ]
  end

  defp deps do
    [
      {:nerves, "~> 1.11", runtime: false},
      {:nerves_system_br, "1.33.9", runtime: false},
      {:nerves_toolchain_x86_64_nerves_linux_musl, "~> 13.2.0", runtime: false},
      {:nerves_system_linter, "~> 0.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false}
    ]
  end

  defp description do
    """
    Nerves System - x86_64
    """
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package do
    [
      files: package_files(),
      licenses: ["GPL-2.0-only", "GPL-2.0-or-later"],
      links: %{
        "GitHub" => @source_url,
        "REUSE Compliance" =>
          "https://api.reuse.software/info/github.com/#{@github_organization}/#{@app}"
      }
    ]
  end

  defp package_files do
    [
      "fwup_include",
      "rootfs_overlay",
      "CHANGELOG.md",
      "fwup-ops.conf",
      "fwup.conf",
      "grub.cfg",
      "LICENSES/*",
      "linux-6.12.defconfig",
      "mix.exs",
      "nerves_defconfig",
      "post-build.sh",
      "post-createfs.sh",
      "README.md",
      "REUSE.toml",
      "VERSION"
    ]
  end

  defp build_runner_opts() do
    # Download source files first to get download errors right away.
    [make_args: primary_site() ++ ["source", "all", "legal-info"]]
  end

  defp primary_site() do
    case System.get_env("BR2_PRIMARY_SITE") do
      nil -> []
      primary_site -> ["BR2_PRIMARY_SITE=#{primary_site}"]
    end
  end

  defp set_target() do
    if function_exported?(Mix, :target, 1) do
      apply(Mix, :target, [:target])
    else
      System.put_env("MIX_TARGET", "target")
    end
  end
end
