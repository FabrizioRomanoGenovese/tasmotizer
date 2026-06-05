{
  description = "Tasmotizer - a dedicated flashing tool for Tasmota";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python3;
          pyqt5WithSerial = python.pkgs.pyqt5.override { withSerialPort = true; };
        in {
          default = python.pkgs.buildPythonApplication {
            pname = "tasmotizer";
            version = "1.2.1";
            src = ./.;

            pyproject = true;
            build-system = with python.pkgs; [ setuptools ];

            dependencies = [ pyqt5WithSerial python.pkgs.pyserial ];

            nativeBuildInputs = [ pkgs.libsForQt5.wrapQtAppsHook ];

            doCheck = false;

            meta = with pkgs.lib; {
              description = "Dedicated flashing tool for Tasmota firmware";
              homepage = "https://github.com/tasmota/tasmotizer";
              license = licenses.gpl3Only;
              platforms = platforms.unix;
              mainProgram = "tasmotizer.py";
            };
          };
        }
      );

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pyqt5WithSerial = pkgs.python3Packages.pyqt5.override { withSerialPort = true; };
          pythonEnv = pkgs.python3.withPackages (ps: [ pyqt5WithSerial ps.pyserial ]);
          qtPluginPath = "${pkgs.libsForQt5.qtbase.bin}/lib/qt-${pkgs.libsForQt5.qtbase.version}/plugins";
        in {
          default = pkgs.mkShell {
            packages = [ pythonEnv ];

            shellHook = ''
              export QT_PLUGIN_PATH="${qtPluginPath}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
              cat > tasmotizer << 'WRAPPER'
#!/bin/sh
exec python3 "$(dirname "$0")/tasmotizer.py" "$@"
WRAPPER
              chmod +x tasmotizer
            '';
          };
        }
      );
    };
}
