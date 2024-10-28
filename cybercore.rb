require 'msf/core/plugin'

module Msf
  class Plugin::CyberCore < Msf::Plugin

    # Command Dispatcher for the plugin
    class ConsoleCommandDispatcher
      include Msf::Ui::Console::CommandDispatcher

      def name
        'CyberCore'
      end

      def commands
        {
          'cybercore' => 'Manage command aliases for a target IP using -a to add and -r to remove',
          'list_aliases' => 'List currently loaded aliases'
        }
      end

      # Method to load or remove aliases based on the provided flag (-a to add, -r to remove)
      def cmd_cybercore(*args)
        ip = nil
        action = nil

        # Parse arguments for the -a (add) or -r (remove) flag
        args.each_with_index do |arg, index|
          if arg == '-a'
            action = 'add'
            ip = args[index + 1] # Get the next argument as IP
          elsif arg == '-r'
            action = 'remove'
            ip = args[index + 1] # Get the next argument as IP
          end
        end

        # Validate that the IP address is provided
        if ip.nil? || ip.empty?
          print_error("Please provide an IP address with the -a or -r flag.")
          return
        end

        # Handle adding or removing aliases
        case action
        when 'add'
          add_aliases(ip)
        when 'remove'
          remove_aliases(ip)
        else
          print_error("Invalid option. Use -a to add or -r to remove aliases.")
        end
      end

      # Helper method to add aliases
      def add_aliases(ip)
        aliases = {
          'hip' => "hosts #{ip}",
          'sip' => "services #{ip}",
          'rip' => "set rhosts #{ip}",
          'crd' => "creds #{ip}",
          'nt'  => "notes #{ip}",
          'vul' => "vulns #{ip}",
          'service_enum' => "db_nmap -sV -sC -v -T4 #{ip}"
        }

        if driver
          print_status("Loading aliases for IP: #{ip}")
          driver.run_single('unload alias')
          driver.run_single('load alias')
          print_status("Adding host: #{ip}")
          driver.run_single("hosts -a #{ip}")

          aliases.each do |alias_name, command|
            driver.run_single("alias #{alias_name} '#{command}'")
          end

          print_status("All aliases added for IP: #{ip}")
          driver.run_single("alias")
        else
          print_error("No active console found.")
        end
      end

      # Helper method to remove aliases
      def remove_aliases(_ip)
        aliases = %w[hip sip rip crd nt vul]
        
        if driver
          aliases.each do |alias_name|
            driver.run_single("alias -r #{alias_name}")
            print_good("Alias '#{alias_name}' removed.")
          end
          print_good("All aliases removed.")
        else
          print_error("No active console found.")
        end
      end

      # Method to list currently loaded aliases
      def cmd_list_aliases
        if driver
          print_status("Currently loaded aliases:")
          driver.run_single('alias')
        else
          print_error("No active console found.")
        end
      end
    end

    # Constructor for the plugin
    def initialize(framework, opts)
      super
      add_console_dispatcher(ConsoleCommandDispatcher)
      print_status('CyberCore plugin loaded. Use cybercore -a to add aliases or -r to remove aliases based on an IP address.')
    end

    # Cleanup routine for the plugin
    def cleanup
      remove_console_dispatcher('CyberCore')
    end

    # Short name for the plugin
    def name
      'CyberCore'
    end

    # Brief description of the plugin
    def desc
      'Manage command aliases for a target IP address using cybercore commands.'
    end
  end
end
