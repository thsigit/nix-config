{ lib, stdenv, fetchFromGitHub, libmicrohttpd, bash, coreutils, curl
, gawk, gnugrep, gnused, procps, inetutils, kmod, iproute2, iptables, nftables }:

stdenv.mkDerivation rec {
  pname = "opennds";
  version = "11.0.0";

  src = fetchFromGitHub {
    owner = "openNDS";
    repo = "openNDS";
    rev = "v${version}";
    hash = "sha256-yfSUGWaMxrUCQhipcP4Kw9rIzDWH6mWz8jG91t/FFgk=";
  };

  buildInputs = [
    libmicrohttpd
    iptables
    bash
    coreutils
    curl
    gawk
    gnugrep
    gnused
  ];

  preBuild = ''
    substituteInPlace Makefile \
      --replace 'CC?=gcc' 'CC?=cc' \
      --replace 'LDLIBS=-lmicrohttpd' "LDLIBS=-L${libmicrohttpd}/lib -lmicrohttpd"
    export CFLAGS="-I${libmicrohttpd}/include $CFLAGS"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/etc/opennds/htdocs/images
    mkdir -p $out/etc/config
    mkdir -p $out/lib/opennds
    mkdir -p $out/share/opennds

    # Install binaries
    cp opennds $out/bin/.opennds-unwrapped
    cp ndsctl $out/bin/.ndsctl-unwrapped

    # Create wrapper scripts with PATH for shell script dependencies
    cat > $out/bin/opennds << WRAPPER
#!${bash}/bin/bash
export PATH="${lib.makeBinPath [ coreutils gawk gnugrep gnused procps inetutils kmod iproute2 iptables nftables bash curl ]}:\$PATH"
exec $out/bin/.opennds-unwrapped "\$@"
WRAPPER
    chmod +x $out/bin/opennds

    cat > $out/bin/ndsctl << WRAPPER
#!${bash}/bin/bash
export PATH="${lib.makeBinPath [ coreutils ]}:\$PATH"
exec $out/bin/.ndsctl-unwrapped "\$@"
WRAPPER
    chmod +x $out/bin/ndsctl

    # Install splash resources
    cp resources/splash.css $out/etc/opennds/htdocs/
    cp resources/splash.jpg $out/etc/opennds/htdocs/images/

    # Install shell scripts
    for script in forward_authentication_service/binauth/*.sh; do
      name=$(basename "$script")
      cp "$script" $out/lib/opennds/$name
      chmod +x $out/lib/opennds/$name
    done

    for script in forward_authentication_service/libs/*.sh forward_authentication_service/libs/ndscfg; do
      name=$(basename "$script")
      cp "$script" $out/lib/opennds/$name
      chmod +x $out/lib/opennds/$name
    done

    for script in forward_authentication_service/PreAuth/*.sh; do
      name=$(basename "$script")
      cp "$script" $out/lib/opennds/$name
      chmod +x $out/lib/opennds/$name
    done

    cp forward_authentication_service/libs/post-request.php $out/lib/opennds/
    cp forward_authentication_service/fas-aes/*.php $out/etc/opennds/
    cp forward_authentication_service/fas-hid/*.php $out/etc/opennds/

    runHook postInstall
  '';

  meta = with lib; {
    description = "openNDS - open Network Demarcation Service, a high performance Captive Portal";
    homepage = "https://opennds.readthedocs.io/";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
