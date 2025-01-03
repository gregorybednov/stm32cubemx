{
  description = "STM32CubeMX configurator";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };

      iconame = "STM32CubeMX";
      stm32cubemx = pkgs.stdenv.mkDerivation rec {
        pname = "stm32cubemx";
        version = "6.11.1";
        src = builtins.fetchTarball {
          url = "http://kafpi.local/stm32cubemx_v${
          builtins.replaceStrings [ "." ] [ "" ] version
          }-lin.tar.gz";
          sha256 = "1aq35pmn6201dcaprdqj126b4mzfkga70gil36iqp84bhg7jq6zb";
          #stripRoot = false;
        };

        nativeBuildInputs = with pkgs; [
          fdupes
          icoutils
          imagemagick
        ];
    
    desktopItem = pkgs.makeDesktopItem {
      name = "STM32CubeMX";
      exec = "stm32cubemx";
      desktopName = "STM32CubeMX";
      categories = [ "Development" ];
      icon = "stm32cubemx";
      comment = "A graphical tool for configuring STM32 microcontrollers and microprocessors";
      terminal = false;
      startupNotify = false;
      mimeTypes = [
        "x-scheme-handler/sgnl"
        "x-scheme-handler/signalcaptcha"
      ];
    };

    buildCommand = ''
      mkdir -p $out/{bin,opt/STM32CubeMX,share/applications}

      cp -r $src/MX/. $out/opt/STM32CubeMX/
      chmod +rx $out/opt/STM32CubeMX/STM32CubeMX

      cat << EOF > $out/bin/${pname}
      #!${pkgs.stdenvNoCC.shell}
      ${pkgs.jdk17}/bin/java -jar $out/opt/STM32CubeMX/STM32CubeMX
      EOF
      chmod +x $out/bin/${pname}

      icotool --extract $out/opt/STM32CubeMX/help/${iconame}.ico
      fdupes -dN . > /dev/null
      ls
      for size in 16 24 32 48 64 128 256; do
        mkdir -pv $out/share/icons/hicolor/"$size"x"$size"/apps
        if [ $size -eq 256 ]; then
          mv ${iconame}_*_"$size"x"$size"x32.png \
            $out/share/icons/hicolor/"$size"x"$size"/apps/${pname}.png
        else
          convert -resize "$size"x"$size" ${iconame}_*_256x256x32.png \
            $out/share/icons/hicolor/"$size"x"$size"/apps/${pname}.png
        fi
      done;

      cp ${desktopItem}/share/applications/*.desktop $out/share/applications
    '';

        fhsEnv = pkgs.buildFHSEnv {
          name = "${pname}-fhs-env";
          targetPkgs = p: with p; [
            alsa-lib
            at-spi2-atk
            cairo
            cups
            dbus
            expat
            glib
            gtk3
            libdrm
            libGL
            libudev0-shim
            libxkbcommon
            mesa
            nspr
            nss
            pango
            xorg.libX11
            xorg.libxcb
            xorg.libXcomposite
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXrandr         
          ];
          runScript = "${src}/bin/mmain";
        };

        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          cp ${fhsEnv}/bin/${pname}-fhs-env $out/bin/stm32cubemx
          runHook postInstall
        '';
      };
    in {
      packages.x86_64-linux.stm32cubemx = stm32cubemx;
      defaultPackage.x86_64-linux = stm32cubemx;
    };
}
