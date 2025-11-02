{
  description = "Tools for reverse engineering cubin files";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    denvdis = {
      url = "github:redplait/denvdis";
      flake = false;
    };
    dwarfdump = {
      url = "github:redplait/dwarfdump";
      flake = false;
    };
    # `pkgs.elfio` should also work
    elfio = {
      url = "github:serge1/ELFIO";
      flake = false;
    };
    fp16 = {
      url = "github:Maratyszcza/FP16";
      flake = false;
    };
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      denvdis,
      dwarfdump,
      elfio,
      fp16,
      ...
    }:
    (flake-utils.lib.eachSystem nixpkgs.lib.platforms.linux) (
      system:
      let
        # `pkgs.perlPackages.buildPerlPackage` overwrites `CC` set by `Makefile.PL`, so I'm using `pkgs.stdenv.mkDerivation` instead.
        # See: https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/perl-modules/generic/builder.sh
        inherit (pkgs.stdenv) mkDerivation;
        inherit (pkgs.perlPackages) makePerlPath;
        allowUnfree = true;
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = allowUnfree;
            allowBroken = true; # TODO: Remove when `cudaPackages.cuda_cuobjdump` and `cudaPackages.cuda_nvdisasm` aren't broken!
          };
        };
        Elf-Reader = mkDerivation {
          pname = "Elf-Reader";
          version = "0.01";
          src = "${dwarfdump}/perl/Elf-Reader";
          buildInputs = [ pkgs.perl ];
          nativeBuildInputs = [ pkgs.perl ];
          patches = [ ./Elf-Reader.patch ];
          postPatch = ''
            substituteInPlace Makefile.PL --replace-fail "-I/home/redp/disc/ELFIO" "-I${dwarfdump}/perl/Elf-Reader -I${elfio}"
            # substituteInPlace t/Elf-Reader.t --replace-fail "/bin/ls" "${pkgs.perl}/bin/perl"
          '';
          preConfigure = ''perl Makefile.PL PREFIX=$out INSTALLDIRS=site --skipdeps'';
          preInstall = ''cp ${./autosplit.ix} blib/lib/auto/Elf/Reader/autosplit.ix''; # TODO: Autosplit is not generated for some reason, investigate!!!
          doCheck = false; # TODO: Test currently fail, must patch `t/Elf-Reader.t`
        };
        Elf-FatBinary = mkDerivation {
          pname = "Elf-FatBinary";
          version = "0.01";
          src = "${dwarfdump}/perl/Elf-FatBinary";
          buildInputs = [
            pkgs.perl
            Elf-Reader
          ];
          nativeBuildInputs = with pkgs; [
            perl
            zstd
          ];
          postPatch = ''
            test -d ${makePerlPath [ Elf-Reader ]}/5.40.0/x86_64-linux-thread-multi/auto/Elf/Reader # TODO
            substituteInPlace Makefile.PL --replace-fail "-L\$Config{'sitearch'}/auto/Elf/Reader" "-L${makePerlPath [ Elf-Reader ]}/5.40.0/x86_64-linux-thread-multi/auto/Elf/Reader"
            substituteInPlace Makefile.PL --replace-fail "-I. -I/home/redp/disc/ELFIO" "-I${dwarfdump}/perl/Elf-FatBinary -I${elfio}"
            # substituteInPlace t/Elf-FatBinary.t --replace-fail "/home/redp/disc/src/cuda-ptx/src/cuda_latency_benchmark/cuda_task_queue.cpython-38-x86_64-linux-gnu.so" "${pkgs.perl}/bin/perl"
          '';
          preConfigure = ''perl Makefile.PL PREFIX=$out INSTALLDIRS=site --skipdeps'';
          preInstall = ''cp ${./autosplit.ix} blib/lib/auto/Elf/FatBinary/autosplit.ix''; # TODO: Autosplit is not generated for some reason, investigate!!!
          doCheck = false; # TODO: Test currently fail, must patch `t/Elf-FatBinary.t`
        };
        Cubin-Attrs = mkDerivation {
          pname = "Cubin-Attrs";
          version = "0.01";
          src = "${dwarfdump}/perl/Cubin-Attrs";
          buildInputs = [
            pkgs.perl
            Elf-Reader
          ];
          nativeBuildInputs = with pkgs; [
            perl
            perlPackages.LWP
          ];
          postPatch = ''
            test -d ${makePerlPath [ Elf-Reader ]}/5.40.0/x86_64-linux-thread-multi/auto/Elf/Reader # TODO
            substituteInPlace Makefile.PL --replace-fail "-L\$Config{'sitearch'}/auto/Elf/Reader" "-L${makePerlPath [ Elf-Reader ]}/5.40.0/x86_64-linux-thread-multi/auto/Elf/Reader"
            substituteInPlace Makefile.PL --replace-fail "-I. -I/home/redp/disc/ELFIO" "-I${dwarfdump}/perl/Cubin-Attrs -I${elfio}"
            # substituteInPlace t/Cubin-Attrs.t --replace-fail "/home/redp/disc/src/cuda-ptx/src/denvdis/test/cv/libcvcuda.so.0.15.13.sm_70.cubin" "${pkgs.perl}/bin/perl"
          '';
          preConfigure = ''
            cp ${denvdis}/test/eiattrs.inc .
            perl Makefile.PL PREFIX=$out INSTALLDIRS=site --skipdeps
          '';
          preInstall = ''cp ${./autosplit.ix} blib/lib/auto/Cubin/Attrs/autosplit.ix''; # TODO: Autosplit is not generated for some reason, investigate!!!
          doCheck = false; # TODO: Test currently fail, must patch `t/Cubin-Attrs.t`
        };
        Cubin-Ced = mkDerivation {
          pname = "Cubin-Ced";
          version = "0.01";
          src = "${denvdis}/test/Cubin-Ced";
          buildInputs = [
            pkgs.perl
            Elf-Reader
          ];
          nativeBuildInputs = with pkgs; [
            perl
            perlPackages.LWP
          ];
          postPatch = ''
            substituteInPlace Ced.xs --replace-fail "snap->pr_size" "sizeof(snap->pr) / sizeof(snap->pr[0])"
            test -d ${makePerlPath [ Elf-Reader ]}/5.40.0/x86_64-linux-thread-multi/auto/Elf/Reader # TODO
            substituteInPlace Makefile.PL --replace-fail "-L\$Config{'sitearch'}/auto/Elf/Reader" "-L${makePerlPath [ Elf-Reader ]}/5.40.0/x86_64-linux-thread-multi/auto/Elf/Reader"
            substituteInPlace Makefile.PL --replace-fail "-I. -I.. -I../../scripts -I../../../FP16/include/ -I/home/redp/disc/ELFIO" "-I${denvdis}/test -I${denvdis}/scripts -I${elfio} -I${fp16}/include"
            substituteInPlace t/Cubin-Ced.t --replace-fail "cudatest.6.sm_61.cubin" "${./cubin/cudatest.6.sm_61.cubin}"
          '';
          preConfigure = ''
            cp ${dwarfdump}/perl/elf.inc .
            cp ${./cubin/cudatest.6.sm_61.cubin} cudatest.6.sm_61.cubin
            perl Makefile.PL PREFIX=$out INSTALLDIRS=site --skipdeps
          '';
          preInstall = ''cp ${./autosplit.ix} blib/lib/auto/Cubin/Ced/autosplit.ix''; # TODO: Autosplit is not generated for some reason, investigate!!!
        };
        denvdis-scripts = mkDerivation {
          pname = "denvdis-scripts";
          version = "unstable"; # TODO
          src = denvdis;
          buildInputs = [
            pkgs.perl
            Elf-Reader
            Cubin-Attrs
            Cubin-Ced
          ];
          nativeBuildInputs = [ pkgs.makeWrapper ]; # https://wiki.nixos.org/wiki/Perl#Wrappers_for_installed_programs
          dontBuild = true;
          # TODO: Should $src be used?
          installPhase = ''
            mkdir -p $out/bin
            cp $src/scripts/*.pl $out/bin
            chmod +x $out/bin/*.pl
            # dg.pl
            wrapProgram $out/bin/dg.pl --prefix PERL5LIB : "${
              makePerlPath [
                Elf-Reader
                Cubin-Attrs
                Cubin-Ced
              ]
            }"
            # dump.pl
            cp $src/sht.txt $out
            cp $src/sm_version.txt $out
            substituteInPlace $out/bin/dump.pl --replace-fail "../sht.txt" $out/sht.txt
            substituteInPlace $out/bin/dump.pl --replace-fail "../sm_version.txt" $out/sm_version.txt
            wrapProgram $out/bin/dump.pl --prefix PERL5LIB : "${makePerlPath [ Elf-Reader ]}"
            # hd.pl
            wrapProgram $out/bin/hd.pl --prefix PERL5LIB : "${makePerlPath [ Elf-Reader ]}"
            # ead.pl, fixio.pl and pas.pl
            # Nothing
          '';
        };
        denvdis-binaries = mkDerivation {
          pname = "denvdis-binaries";
          version = "unstable"; # TODO
          src = "${denvdis}/test";
          nativeBuildInputs = with pkgs; [
            perl
            readline
          ];
          postPatch = ''
            substituteInPlace Makefile --replace-fail "IFLAGS=-I ../scripts" "IFLAGS=-I${denvdis}/scripts"
            substituteInPlace Makefile --replace-fail "ELFIO=-I ../../../../../ELFIO/" "ELFIO=-I${elfio}"
            substituteInPlace Makefile --replace-fail "FP16=-I ../../FP16/include" "FP16=-I${fp16}/include"
            substituteInPlace Makefile --replace-fail "EAD=../scripts/ead.pl" "EAD=${denvdis}/scripts/ead.pl"
            sed -i "1i #include <cstdio>" ina.cc
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp ina $out/bin
            cp nvd $out/bin
            cp pa $out/bin
            cp ced $out/bin
          '';
        };
        denvdis-fatbin = mkDerivation {
          pname = "denvdis-fatbin";
          version = "unstable"; # TODO
          src = "${denvdis}/fb";
          buildInputs = [
            pkgs.perl
            Elf-Reader
            Elf-FatBinary
          ];
          nativeBuildInputs = with pkgs; [
            perl
            zstd
            makeWrapper
          ];
          postPatch = ''substituteInPlace Makefile --replace-fail "ELFIO=-I ../../../../../ELFIO/" "ELFIO=-I${elfio}"'';
          buildPhase = ''make fb'';
          installPhase = ''
            mkdir -p $out/bin
            cp fb $out/bin
            cp fb.pl $out/bin
            chmod +x $out/bin/fb.pl
            wrapProgram $out/bin/fb.pl --prefix PERL5LIB : "${
              makePerlPath [
                Elf-Reader
                Elf-FatBinary
              ]
            }"
          '';
        };
        denvdis-decryptors = mkDerivation {
          pname = "denvdis-decryptors";
          version = "unstable"; # TODO
          src = denvdis;
          buildInputs = [ pkgs.cudaPackages.cuda_nvdisasm ];
          nativeBuildInputs = [ pkgs.lz4 ];
          postPatch = ''
            substituteInPlace Makefile --replace-fail "ELFIO=-I ../../../../ELFIO" "ELFIO=-I${elfio}"
            substituteInPlace Makefile --replace-fail "-I ../lz4/lib" ""
            substituteInPlace Makefile --replace-fail "../lz4/lib/liblz4.a" "-llz4"
            substituteInPlace denv.cc --replace-fail "./nvdisasm" "${pkgs.cudaPackages.cuda_nvdisasm}/bin/nvdisasm"
            substituteInPlace ptxas.cc --replace-fail "./nvdisasm" "${pkgs.cudaPackages.cuda_nvdisasm}/bin/nvdisasm"
            # substituteInPlace ptxas12.cc --replace-fail "./nvdisasm" "${pkgs.cudaPackages.cuda_nvdisasm}/bin/nvdisasm"
            substituteInPlace cic12.cc --replace-fail "./nvdisasm" "${pkgs.cudaPackages.cuda_nvdisasm}/bin/nvdisasm"
            substituteInPlace denv12.cc --replace-fail "./nvdisasm" "${pkgs.cudaPackages.cuda_nvdisasm}/bin/nvdisasm"
          '';
          buildPhase = ''
            make denv
            make deptx
            # make deptx12
            make cic12
            make denv12
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp denv $out/bin
            cp deptx $out/bin
            # cp deptx12 $out/bin
            cp cic12 $out/bin
            cp denv12 $out/bin
          '';
        };
      in
      {
        devShells.default = pkgs.mkShellNoCC {
          packages =
            with pkgs;
            [
              binutils # For readelf
              denvdis-scripts # For dg.pl, dump.pl, ead.pl, fixio.pl, hd.pl and pas.pl
              denvdis-binaries # For ina, nvd, pa and ced
              denvdis-fatbin # For fb and fb.pl
              ghidra
            ]
            ++ lib.optionals allowUnfree [
              denvdis-decryptors # For denv, deptx, cic12 and denv12
              cudaPackages.cuda_cuobjdump
              cudaPackages.cuda_nvdisasm
              binaryninja-free
            ];
          NIX_ENFORCE_NO_NATIVE = 0;
        };
        formatter = pkgs.nixfmt-tree;
      }
    );
}
