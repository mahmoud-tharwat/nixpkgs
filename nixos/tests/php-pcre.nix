
let testString = "can-use-subgroups"; in

import ./make-test.nix ({ ...}: {
  name = "php-httpd-pcre-jit-test";
  machine = { lib, pkgs, ... }: {
    time.timeZone = "UTC";
    services.httpd = {
      enable = true;
      adminAddr = "please@dont.contact";
      extraSubservices = lib.singleton {
        function = f: {
          enablePHP = true;
          phpOptions = "pcre.jit = true";

          extraConfig =
          let
            testRoot = pkgs.writeText "index.php"
            ''
              <?php
                preg_match('/(${testString})/', '${testString}', $result);
                var_dump($result);
              ?>
            '';
          in
            ''
              Alias / ${testRoot}/

              <Directory ${testRoot}>
                Require all granted
              </Directory>
            '';
        };
      };
    };
  };
  testScript = { ... }:
  ''
    $machine->waitForUnit('httpd.service');
    # Ensure php evaluation by matching on the var_dump syntax
    $machine->succeed('curl -vvv -s http://127.0.0.1:80/index.php \
      | grep "string(${toString (builtins.stringLength testString)}) \"${testString}\""');
  '';
})
