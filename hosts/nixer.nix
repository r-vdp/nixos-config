{ lib, config, pkgs, ...}:

with lib;

let
  bridge_interface = "br0";
  lan1_interface = "enp1s0";
  lan2_interface = "enp2s0";
  #local_ip = "10.0.7.252";
  #upstream_gateway = "10.0.7.254";
  nameservers = [
    "2620:fe::fe#dns.quad9.net"
    "2620:fe::9#dns.quad9.net"
#    "9.9.9.9#dns.quad9.net"
#    "149.112.112.112#dns.quad9.net"
  ];
in

{
  environment.systemPackages = with pkgs; [
    stack
    ghc
    haskellPackages.haskell-language-server
    nixos-option
  ];

  programs.neovim = {
    enable = true;
    configure = {
      customRC = ''
        set nocompatible            " disable compatibility to old-time vi
        set mouse=v                 " middle-click paste with
        set mouse=a                 " enable mouse click

        colorscheme jellybeans

        set encoding=utf-8
        set scrolloff=3
        set backspace=indent,eol,start
        set undofile

        set list
        set listchars=tab:▸\ ,eol:¬,trail:·

        set termguicolors

        set hlsearch                " highlight search
        set incsearch               " incremental search
        set ignorecase              " case insensitive
        set smartcase
        set showmatch               " show matching

        set tabstop=2               " number of columns occupied by a tab
        set softtabstop=2           " see multiple spaces as tabstops so <BS> does the right thing
        set expandtab               " converts tabs to white space
        set shiftwidth=2            " width for autoindents
        "set autoindent              " indent a new line the same amount as the line just typed

        " remove trailing whitespace
        autocmd BufWritePre * :%s/\s\+$//e

        set ruler
        set cursorline
        set number relativenumber
        set laststatus=2
        set cc=80                   " set an 80 column border for good coding style
        set cmdheight=2             " height of the command window on the bottom

        set wildmenu
        set wildmode=list:longest   " get bash-like tab completions

        filetype plugin indent on   " allow auto-indenting depending on file type
        syntax on                   " syntax highlighting
        set clipboard=unnamedplus   " using system clipboard
        filetype plugin on

        set ttyfast                 " Speed up scrolling in Vim

        silent !mkdir ~/.cache/vim > /dev/null 2>&1
        set backupdir=~/.cache/vim " Directory to store backup files.

        set updatetime=150

        autocmd BufReadPost *
          \ if line("'\"") >= 1 && line("'\"") <= line("$") |
          \   exe "normal! g`\"" |
          \ endif

        " Airline
        let g:airline_theme = 'bubblegum'
        let g:airline_powerline_fonts = 1
        let g:airline#extensions#tabline#enabled = 1
        let g:airline#extensions#tabline#left_sep = ' '
        let g:airline#extensions#tabline#left_alt_sep = '|'

        " unicode symbols
        if !exists('g:airline_symbols')
          let g:airline_symbols = {}
        endif

        let g:airline_left_sep = '»'
        "let g:airline_left_sep = '▶'
        let g:airline_right_sep = '«'
        "let g:airline_right_sep = '◀'
        "let g:airline_symbols.linenr = '␊'
        "let g:airline_symbols.linenr = '␤'
        "let g:airline_symbols.linenr = '¶'
        let g:airline_symbols.linenr = '⮃'
        let g:airline_symbols.colnr = '⮀'
        let g:airline_symbols.branch = '⎇'
        let g:airline_symbols.paste = 'ρ'
        "let g:airline_symbols.paste = 'Þ'
        "let g:airline_symbols.paste = '∥'
        let g:airline_symbols.whitespace = 'Ξ'

        " Open files in new tabs
        let NERDTreeCustomOpenArgs={'file':{'where': 't'}}

        " Keybindings
        let mapleader = ","

        " F1 opens NERDTree
        nnoremap <F1> :NERDTreeToggle<CR>
        " Use double-<space> to save the file
        nnoremap <space><space> :w<cr>
        " Remap jj to Esc.
        inoremap jj <Esc>
        " Remove search highlighting
        nnoremap <leader><space> :noh<cr>
        " Tab jumps to matching bracket
        nnoremap <tab> %
        " Tab jumps to matching bracket
        vnoremap <tab> %

        luafile ${../nvim.lua}
      '';
      packages.nix = with pkgs.vimPlugins; {
        start = [
          (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
          vim-nix
          haskell-vim
          dracula-vim
          vim-airline
          vim-airline-themes
          vim-colorschemes
          indentLine
          nerdtree
          nvim-lspconfig
          nvim-cmp
          cmp-nvim-lsp
        ];
        opt = [];
      };
    };
    withRuby    = false;
    withPython3 = false;
    withNodeJs  = false;
  };

  time.timeZone = "Europe/Brussels";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Only safe on single-user machines
  programs.ssh.startAgent = mkForce true;

  system.autoUpgrade.rebootWindow = mkForce { lower = "10:00"; upper = "21:00"; };

  settings = {
    network.host_name = "nixer";
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto = {
      encrypted_opt.enable = true;
      mounts = let
        ext_disk_wd = "ext_disk_wd";
      in {
        ${ext_disk_wd} = {
          enable = true;
          device = "/dev/disk/by-partlabel/${ext_disk_wd}";
          device_units = [ "dev-disk-by\\x2dpartlabel-ext_disk_wd.device" ];
          mount_point   = "/run/${ext_disk_wd}";
          mount_options = "acl,noatime,nosuid,nodev";
        };
      };
    };
    maintenance.nixos_upgrade.startAt = [ "Fri 18:00" ];
    docker.enable = true;
    services = {
      traefik.enable = true;
    };
  };

  networking = {
    useNetworkd = false;
    firewall = {
      extraCommands = ''
        function append_rule() {
          append_rule4 "''${1}"
          append_rule6 "''${1}"
        }

        function append_rule4() {
          do_append_rule "''${1}" "iptables"
        }

        function append_rule6() {
          do_append_rule "''${1}" "ip6tables"
        }

        function do_append_rule() {
          rule="''${1}"
          iptables="''${2}"
          if [ $(''${iptables} -C ''${rule} 2>/dev/null; echo $?) -ne "0" ]; then
            ''${iptables} -A ''${rule}
          fi
        }

        # Accept incoming DHCPv4 traffic
        #append_rule4 "nixos-fw --protocol udp --dport 67:68 --jump nixos-fw-accept"

        # Forward all outgoing traffic on the bridge belonging to existing connections
        append_rule  "FORWARD --out-interface ${bridge_interface} --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT"
        # Accept all outgoing traffic to the external interface of the bridge
        append_rule  "FORWARD --out-interface ${bridge_interface} --match physdev --physdev-out ${lan1_interface} --jump ACCEPT"
        # Accept DHCPv4
        append_rule4 "FORWARD --out-interface ${bridge_interface} --protocol udp --dport 67:68 --sport 67:68 --jump ACCEPT"
        # IPv6 does not work without ICMPv6
        append_rule6 "FORWARD --out-interface ${bridge_interface} --protocol icmpv6 --jump ACCEPT"
        # Do not forward by default
        ip46tables --policy FORWARD DROP
      '';
    };
    useDHCP = mkForce false;
    bridges.${bridge_interface}.interfaces = [ lan1_interface lan2_interface ];
    interfaces.${bridge_interface} = {
      useDHCP = true;
      tempAddress = "default";
#      #ipv4.addresses = [ { address = local_ip; prefixLength = 22; } ];
    };
#    #defaultGateway = { address = upstream_gateway; interface = bridge_interface; };
    inherit nameservers;
  };

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.use_tempaddr" = "2";
    "net.ipv6.conf.${bridge_interface}.use_tempaddr" = mkForce "2";
  };

  systemd.network = {
    enable = false;

    netdevs.${bridge_interface} = {
      enable = true;
      netdevConfig = {
        Name = bridge_interface;
        Kind = "bridge";
      };
    };

    networks = {
      ${lan1_interface} = {
        enable = true;
        matchConfig = { Name = lan1_interface; };
        bridge = [ bridge_interface ];
      };
      ${lan2_interface} = {
        enable = true;
        matchConfig = { Name = lan2_interface; };
        bridge = [ bridge_interface ];
      };
      ${bridge_interface} = {
        enable = true;
        matchConfig = { Name = bridge_interface; };
        DHCP = "yes";
        dhcpV6Config       = { UseDNS = false; };
        ipv6AcceptRAConfig = { UseDNS = false; };
        dhcpV4Config       = { UseDNS = false; };
        networkConfig      = { IPv6PrivacyExtensions = "kernel"; };
      };
    };
  };

  services = {

    resolved = {
      enable = true;
      domains = [ "~." ];
      dnssec = "false";
      extraConfig = ''
        DNS=${concatStringsSep " " nameservers}
        DNSOverTLS=true
      '';
    };

    openssh = {
      ports = [ 22 2443 ];
    };

    avahi = {
      interfaces = [ bridge_interface ];
    };

    ddclient = {
      enable = true;
      username = "none";
      passwordFile = config.settings.system.secrets.dest_directory + "/dynv6_token";
      use = ''web, web=https://api6.ipify.org'';
      server = "dynv6.com";
      protocol = "dyndns2";
      ipv6 = true;
      domains = [ "ramses.dynv6.net" ];
    };

    dhcpd4 = {
      enable = false;
      interfaces = [ bridge_interface ];
      extraConfig = ''
        option subnet-mask 255.255.252.0;
        option routers ${upstream_gateway};
        option domain-name-servers ${concatStringsSep ", " nameservers};
        min-lease-time ${toString (2 * 60 * 60)};
        default-lease-time ${toString (4 * 60 * 60)};
        max-lease-time ${toString (4 * 60 * 60)};
        subnet 10.0.4.0 netmask 255.255.252.0 {
          range 10.0.4.1 10.0.6.254;
        }
      '';
    };
  };
}

