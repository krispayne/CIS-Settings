#!/bin/bash
########################################################################
# CIS Benchmark Settings 1.1.0
# El Capitan (10.10)
# Kris Payne
#
# Run as root
# Usage: scriptname.sh [-l|--level] [1,2,1.5]
# 1 = All Scored Level 1 benchmarks (default)
# 2 = All Scored Level 1 and 2 benchmarks (coming someday)
# 1.5 = All Scored Level 1 benchmarks with sensible secure recommendations as well as some Level 2
########################################################################

softwareUpdates() {
# 1 Install Updates, Patches and Additional Security Software
    ScriptLogging "1 Install Updates, Patches, and Additional Security Software"

    # 1.1 Verify all Apple provided software is current
    # Level 1 Scored
    ScriptLogging "  Checking for software updates from Apple..."
    local SoftwareUpdateCommand
    SoftwareUpdateCommand="$(/usr/sbin/softwareupdate -l | wc -l)"
    if [[ ${SoftwareUpdateCommand} -eq 4 ]]; then
        ScriptLogging "  All available software updates have been installed."
    else
        ScriptLogging "  Installing Software Updates."
        /usr/sbin/softwareupdate -i -a
        ScriptLogging "  All available software updates have been installed."
    fi

    # 1.2 Enable Auto Update
    # Level 1 Scored
    local AutoSoftwareUpdateCheck
    AutoSoftwareUpdateCheck="$(/usr/bin/defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled)"
    if [[ ${AutoSoftwareUpdateCheck} = "1" ]]; then
        ScriptLogging "  Automatic Update Check enabled."
    else
        ScriptLogging "  Automatic Update Check NOT enabled. Enabling..."
        /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled -bool TRUE
        /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload -bool TRUE
        /usr/sbin/softwareupdate --schedule on
        ScriptLogging "  Automatic Update Check enabled."
    fi

    # 1.3 Enable app update installs
    # Level 1 Scored
    local AppAutoUpdate
    AppAutoUpdate="$(/usr/bin/defaults read /Library/Preferences/com.apple.commerce AutoUpdate)"
    if [[ ${AppAutoUpdate} = "1" ]]; then
        ScriptLogging "  Auto Update Apps enabled."
    else
        ScriptLogging "  Auto Update Apps NOT enabled. Enabling..."
        /usr/bin/defaults write /Library/Preferences/com.apple.commerce.plist AutoUpdate -bool TRUE
        ScriptLogging "  Auto Update Apps enabled."
    fi

    # 1.4 Enable system data files and security update installs
    # Level 1 Scored
    local ConfigDataInstall
    local CriticalUpdateInstall
    ConfigDataInstall="$(/usr/bin/defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist | grep "ConfigDataInstall" | awk '{ print $3 }')"
    CriticalUpdateInstall="$(/usr/bin/defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist | grep "CriticalUpdateInstall" | awk '{ print $3 }')"

    if [[ ${ConfigDataInstall} = "1;" ]]; then
        ScriptLogging "  Configuration Data updates enabled."
    else
        ScriptLogging "  Configuration Data updates NOT enabled. Enabling..."
        /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist ConfigDataInstall -bool TRUE
        ScriptLogging "  Configuration Data updates enabled."
    fi

    if [[ ${CriticalUpdateInstall} = "1;" ]]; then
        ScriptLogging "  Critical security updates enabled."
    else
        ScriptLogging "  Critical security updates NOT enabled. Enabling..."
        /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall -bool TRUE
        ScriptLogging "  Critical security updates enabled."
    fi

    # 1.5 Enable OS X update installs
    # Level 1 Scored
    local AutoRestartReq
    AutoRestartReq="$(/usr/bin/defaults read /Library/Preferences/com.apple.commerce.plist AutoUpdateRestartRequired)"
    if [[ ${AutoRestartReq} = "1" ]]; then
        ScriptLogging "  OS X Auto Updates enabled."
    else
        ScriptLogging "  OS X Auto Updates NOT enabled. Enabling..."
        /usr/bin/defaults write /Library/Preferences/com.apple.commerce.plist AutoUpdateRestartRequired -bool TRUE
        ScriptLogging "  OS X Auto Updates enabled."
    fi
}

systemPreferences() {
# 2 System Preferences
    ScriptLogging "2 System Preferences"

    # 2.1 Bluetooth
        # 2.1.1 Turn off Bluetooth, if no paired devices exist
        # Level 1 Scored
        # TODO
        # Getting errors in STDOUT
        # Could be related to Server.app
        # 2016-06-22 12:54:21.315 system_profiler[77638:1038574] httpdEnabled is deprecated !!
        # 2016-06-22 12:54:30.842 system_profiler[77675:1038866] __agent_connection_block_invoke_2: Connection error - Connection invalid

        local BTControllerPowerState
        BTControllerPowerState="$(/usr/bin/defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState)"
        local BTSysPaired
        BTSysPaired="$(/usr/sbin/system_profiler | grep "Bluetooth:" -A 20 | grep Connectable | awk '{ print $2 }' 2>/dev/null)"
        if [[ ${BTControllerPowerState} = "0" ]]; then
            ScriptLogging "  Bluetooth is powered off."
        elif [[ ${BTControllerPowerState} = "1" ]]; then
            ScriptLogging "  Bluetooth is powered on. Searching for paired devices..."
            if [[ ${BTSysPaired} = "Yes" ]]; then
                ScriptLogging "  Bluetooth has found a paired device."
            elif [[ ${BTSysPaired} = "No" ]]; then
                ScriptLogging "  Bluetooth has NOT found a paired device. Turning off Bluetooth..."
                /usr/bin/defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0
                ScriptLogging "  Bluetooth is powered off."
            fi
        fi

        # 2.1.2 Turn off Bluetooth "Discoverable" mode when not pairing devices
        # Level 1 Scored
        # Starting with OS X (10.9) Bluetooth is only set to Discoverable when the Bluetooth System Preference
        # is selected. To ensure that the computer is not Discoverable do not leave that preference open.

        if [[ "$(/usr/sbin/system_profiler SPBluetoothDataType | grep -i discoverable | awk '{ print $2 }')" = "Off" ]]; then
            ScriptLogging "  Bluetooth is not discoverable."
        else
            ScriptLogging "  Bluetooth is discoverable, please close System Preferences."
        fi

        # 2.1.3 Show Bluetooth status in menu bar
        # Level 1 Scored
        # TODO: Test new audit/remidiate
        # This possibly may not work anymore.

        local BluetoothMenuStatus
        BluetoothMenuStatus="$(/usr/bin/defaults read com.apple.systemuiserver menuExtras | grep Bluetooth.menu)"
        if [[ "${BluetoothMenuStatus}" = "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" ]]; then
           ScriptLogging "  Bluetooth shown in menu bar."
        else
            ScriptLogging "  Bluetooth Not shown in menu bar. Enabling..."
            user_template com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
            ScriptLogging "  Bluetooth shown in menu bar."
        fi

    # 2.2 Date & Time
        # 2.2.1 Enable "Set time and date automatically"
        # no need to remediate, just set.
        # If you want to remediate first, please feel free to fork and pull
        # Level 2 Not Scored, Level 1.5 Not Scored
        if [[ ${CISLEVEL} = "1.5" ]]; then
            if [[ ! -e /etc/ntp.conf ]]; then
                    ScriptLogging "  Create '/etc/ntp.conf'"
                    /usr/bin/touch /etc/ntp.conf
            fi

            ScriptLogging "  Ensure NetworkTime is on."
            /usr/sbin/systemsetup -setusingnetworktime on

            ScriptLogging "  Set NetworkTime to time.apple.com."
            /usr/sbin/systemsetup -setnetworktimeserver time.apple.com
        fi

        # 2.2.2 Ensure time set is within appropriate limits
        # Level 1 Scored
        ScriptLogging "  Checking time.apple.com skew..."
        /usr/sbin/ntpdate -sv time.apple.com

    # 2.3 Desktop & Screen Saver
        # 2.3.1 Set an inactivity interval of 20 minutes or less for the screen saver
        # Level 1 Scored
        # User configuration profiles are more useful here.
        # Make sure what is set in the config profile is less than section 2.3.3
        # This will also set this as root, not the actual user.
        # Could do User Template like as in 2.3.2, however this has not been tested.
        #/usr/bin/defaults -currentHost write com.apple.screensaver idleTime 600

        # 2.3.2 Secure screen saver corners
        # Level 2 Scored, Level 1.5 Not Scored
        # Take a "clear-all" approach here, as 2.3.4 sets an active corner for enabling screensaver.
        if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
            ScriptLogging "  Setting all corners to '1'..."
            user_template com.apple.dock wvous-tl-corner 1
            user_template com.apple.dock wvous-tr-corner 1
            user_template com.apple.dock wvous-bl-corner 1
            user_template com.apple.dock wvous-br-corner 1
        fi

        # 2.3.3 Verify Display Sleep is set to a value larger than the Screen Saver
        # Level 1 Not Scored, Level 1.5
        if [[ ${CISLEVEL} = "1.5" ]]; then
            ScriptLogging "  Setting Display Sleep to 15 minutes..."
            /usr/bin/pmset -a displaysleep 15
        fi

        # 2.3.4 Set a screen corner to Start Screen Saver
        # Level 1 Scored
        # Not currently setting.
        # TODO
        #ScriptLogging "  Setting bottom right corner to enable screensaver..."
        #user_template com.apple.dock wvous-br-corner 5
        #user_template com.apple.dock wvous-br-modifier 0

    # 2.4 Sharing
        # 2.4.1 Disable Remote Apple Events
        # Level 1 Scored
        if [[ "$(/usr/sbin/systemsetup -getremoteappleevents | awk '{ print $4 }')" = "Off" ]]; then
            ScriptLogging "  Remote Apple Events disabled."
        else
            ScriptLogging "  Remote Apple Events NOT disabled. Disabling..."
            /usr/sbin/systemsetup -setremoteappleevents off
            ScriptLogging "  Remote Apple Events disabled."
        fi

        # 2.4.2 Disable Internet Sharing
        # Level 1 Scored

        # Internet Sharing is off by default. Running these commands without checking
        # first will send the machine into a downward sprial of doom and depair.
        # It's your funeral if you uncomment. Left in for remediation/completeness sake.

        # if [[ ! -e "/Library/Preferences/SystemConfiguration/com.apple.nat" ]]; then
        #     ScriptLogging "  No 'com.apple.nat' file present. Internet Sharing Disabled."
        # else
        #     ScriptLogging "  'com.apple.nat' file present. Internet Sharing Enabled. Disabling..."
        #     /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict Enabled -int 0
        #     /bin/launchctl unload -w /System/Library/LaunchDaemons/ com.apple.InternetSharing.plist
        #     ScriptLogging "  Internet Sharing Disabled."
        # fi

        # 2.4.3 Disable Screen Sharing
        # Level 1 Scored
        local ScreenSharing
        ScreenSharing="$(/usr/bin/defaults read /System/Library/LaunchDaemons/com.apple.screensharing.plist | grep "Disabled" | awk '{ print $3 }')"
        if [[ ${ScreenSharing} = "1;" ]]; then
            ScriptLogging "  Screen Sharing Disabled."
        else
            ScriptLogging "  Screen Sharing Enabled. Disabling..."
            /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -configure -access -off
            ScriptLogging "  Screen Sharing Disabled."
        fi

        # 2.4.4 Disable Printer Sharing
        # Level 1 Scored
        # No need to audit, just remediate.
        ScriptLogging "  Disabling printer sharing..."
        /usr/sbin/cupsctl --no-share-printers

        # 2.4.5 Disable Remote Login
        # Level 1 Scored
        # Only open to administrator accounts. Best practice is for service accounts only.
        local RemoteLogin
        RemoteLogin="$(/usr/sbin/systemsetup -getremotelogin | awk '{ print $3 }')"
        if [[ ${RemoteLogin} = "Off" ]]; then
            ScriptLogging "  Remote Login disabled."
        elif [[ ${RemoteLogin} = "administrator" ]]; then
            ScriptLogging "  Remote Login enabled for Administrators. Consider removing if not needed."
        else
            ScriptLogging "  Remote Login enabled. Disabling..."
            /usr/sbin/systemsetup -setremotelogin off
            ScriptLogging "  Remote Login disabled."
        fi

        # 2.4.6 Disable DVD or CD Sharing
        # Level 1 Scored
        # Newer devices do not have Optical Drives
        # TODO Test. New audit/remediation written.
        local OpticalSharingAudit
        OpticalSharingAudit=$(/bin/launchctl list | egrep ODSAgent)
        if [[ ${OpticalSharingAudit} -ge 0 ]]; then
            ScriptLogging "  Optical Drive Sharing is disabled."
        else
            ScriptLogging "  Optical Drive Sharing is NOT disabled. Disabling..."
            /bin/launchctl unload -w /System/Library/LaunchDaemons/com.apple.ODSAgent.plist
            ScriptLogging "  Optical Drive Sharing is disabled."
        fi

        # 2.4.7 Disable Bluetooth Sharing
        # Level 1 Scored
        #TODO: Test. New audit/remediation written.

        #local BTSharing
        #BTSharing="$(/usr/sbin/system_profiler SPBluetoothDataType | grep State)"
        #if [[ ${BTSharing} = "Disabled\nDisabled\nDisabled" ]]; then
        #    ScriptLogging "  Bluetooth Sharing disabled."
        #else
        #    local hardwareUUID
        #    hardwareUUID=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | awk -F ": " '{print $2}')
        #    ScriptLogging "  Bluetooth Sharing disabling..."
        #   for USER_HOME in /Users/*
        #        do
        #            USER_UID=$(basename "${USER_HOME}")
        #                if [ ! "${USER_UID}" = "Shared" ]; then
        #                    if [ ! -d "${USER_HOME}"/Library/Preferences ]; then
        #                        /bin/mkdir -p "${USER_HOME}"/Library/Preferences
        #                        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library
        #                        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
        #                    fi
        #                    if [ ! -d "${USER_HOME}"/Library/Preferences/ByHost ]; then
        #                        /bin/mkdir -p "${USER_HOME}"/Library/Preferences/ByHost
        #                        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library
        #                        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
        #                        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/ByHost
        #                    fi
        #                    if [ -d "${USER_HOME}"/Library/Preferences/ByHost ]; then
        #                        /usr/bin/defaults write "$USER_HOME"/Library/Preferences/ByHost/com.apple.Bluetooth.$hardwareUUID.plist PrefKeyServicesEnabled -bool false
        #                        #/usr/libexec/PlistBuddy -c "Delete :PrefKeyServicesEnabled"  "$USER_HOME"/Library/Preferences/ByHost/com.apple.Bluetooth.$hardwareUUID.plist
        #                        #/usr/libexec/PlistBuddy -c "Add :PrefKeyServicesEnabled bool false"  "$USER_HOME"/Library/Preferences/ByHost/com.apple.Bluetooth.$hardwareUUID.plist
        #                        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/ByHost/com.apple.Bluetooth.$hardwareUUID.plist
        #                    fi
        #                fi
        #    done
        #fi

        # 2.4.8 Disable File Sharing
        # Level 1 Scored
        #TODO: Test. New audit/remediation written.

        local AppleFileServerAudit
        AppleFileServerAudit="$(/bin/launchctl list | egrep AppleFileServer)"
        if [[ "${AppleFileServerAudit}" -ge 0 ]]; then
            ScriptLogging "  AFP is disabled."
        else
            ScriptLogging "  AFP is NOT disabled. Disabling..."
            /bin/launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
            ScriptLogging "  AFP is disabled."
        fi

        local SMBAudit
        SMBAudit="$(/bin/launchctl list | egrep smbd)"
        if [[ ${SMBAudit} -ge 0 ]]; then
            ScriptLogging "  SMB is disbled."
        else
            ScriptLogging "  SMB is NOT disabled. Disabling..."
            /bin/launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist
            ScriptLogging "  SMB is disbled."
        fi

        # 2.4.9 Disable Remote Management
        # Level 1 Scored
        # TODO: Test. New audit/remediation written.

        local ARDAgentAudit
        ARDAgentAudit="$(ps -ef | egrep ARDAgent)"
        if [[ ${ARDAgentAudit} -ge 0 ]]; then
            ScriptLogging "  Remote Management is disabled."
        else
            ScriptLogging "  Remote Management is NOT disabled. Disabling..."
            /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop
            ScriptLogging "  Remote Management is disabled."
        fi

     # 2.5 Energy Saver
        # 2.5.1 Disable "Wake for network access"
        # Level 2 Scored, Level 1.5 Not Scored
        # Take a "clear-all" approach here
        if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
            ScriptLogging "  Wake for network Access disabling."
            /usr/bin/pmset -a womp 0
            ScriptLogging "  Wake for network Access disabled."
        fi

        # 2.5.2 Disable sleeping the computer when connected to power
        # Level 2 Scored, Level 1.5 Not Scored
        # Take a "clear-all" approach here
        if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
            ScriptLogging "  Sleep when connected to power disabling."
            /usr/bin/pmset -c sleep 0
            ScriptLogging "  Sleep when connected to power disabled."
        fi

    # 2.6 Security & Privacy
        # 2.6.1 Enable FileVault
        # Level 1 Scored
        # This should be handled by an MDM with personal/institutional keys.
        # audit is `diskutil cs list | grep -i encryption`

        # 2.6.2 Enable Gatekeeper
        # Level 1 Scored
        if [[ "$(/usr/sbin/spctl --status)" = "assessments disabled" ]]; then
            ScriptLogging "  Gatekeeper is disabled. Enabling..."
            /usr/sbin/spctl --master-enable
            ScriptLogging "  Gatekeeper is enabled."
        else
            ScriptLogging "  Gatekeeper is enabled."
        fi

        # 2.6.3 Enable Firewall
        # Level 1 Scored
        local SysFirewall
        SysFirewall="$(/usr/bin/defaults read /Library/Preferences/com.apple.alf globalstate)"
        if [[ ${SysFirewall} -ge 1 ]]; then
            ScriptLogging "  Firewall enabled."
        else
            ScriptLogging "  Firewall NOT enabled. Enabling..."
            /usr/bin/defaults write /Library/Preferences/com.apple.alf globalstate -int 1
            ScriptLogging "  Firewall enabled."
        fi

        # 2.6.4 Enable Firewall Stealth Mode
        # Level 1 Scored
        local SysFirewallStealth
        SysFirewallStealth="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode | grep -ic "Stealth mode enabled")"
        if [[ ${SysFirewallStealth} -ge 1 ]]; then
            ScriptLogging "  Firewall Stealth Mode enabled."
        else
            ScriptLogging "  Firewall Stealth Mode NOT enabled. Enabling..."
            /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
            ScriptLogging "  Firewall Stealth Mode enabled."
        fi

        # 2.6.5 Review Application Firewall Rules
        # Level 1 Scored
        local AppFirewall
        AppFirewall="$(/usr/libexec/ApplicationFirewall/socketfilterfw --listapps | grep "ALF" | awk '{ print $7 }')"
        if [[ ${AppFirewall} -lt 10 ]]; then
            ScriptLogging "  Application Firewall exception list is less than 10."
        else
            ScriptLogging "***** Application Firewall exception list is greater than 10, please investigate! *****"
        fi

        # 2.7 iCloud
        # This section has moved from Recommendations over to Subsections, however, no audit or remidiation guideleins are given.
        # General thought (mine, not CIS) is that if you are Level 1, these can be left alone. Anything above (1.5+) should be audited,
        # Level 2 Not Scored
        # 2.7.1 iCloud configuration
        # 2.7.2 iCloud keychain
        # 2.7.3 iCloud Drive

        # 2.8 Pair the remote control infrared receiver if enabled
        # Level 1 Scored
        #TODO: Getting errors in STDOUT.
        #./Yosemite_CIS.sh: line 507: [[: Jun 22, 2016, 11:53:31 AM CIS_SETTINGS[74183]:   No IR Receiver present.
        #Jun 22 11:53:31 kvoleon CIS_SETTINGS[74183]:   No IR Receiver present.: syntax error in expression (error token is "22, 2016, 11:53:31 AM CIS_SETTINGS[74183]:   No IR Receiver present.
        #Jun 22 11:53:31 kvoleon CIS_SETTINGS[74183]:   No IR Receiver present.")
        #./Yosemite_CIS.sh: line 509: [[: Jun 22, 2016, 11:53:31 AM CIS_SETTINGS[74183]:   No IR Receiver present.
        #Jun 22 11:53:31 kvoleon CIS_SETTINGS[74183]:   No IR Receiver present.: syntax error in expression (error token is "22, 2016, 11:53:31 AM CIS_SETTINGS[74183]:   No IR Receiver present.
        #Jun 22 11:53:31 kvoleon CIS_SETTINGS[74183]:   No IR Receiver present.")

        # These errors are because system_profiler is searching the system.log and this script has already been run.
        # Need to find a way to grep/sed out the system.log output

        local SysProfIRReciever
        SysProfIRReciever="$(/usr/sbin/system_profiler 2>/dev/null | egrep "IR Receiver")"
        local AppleIRController
        AppleIRController="$(/usr/bin/defaults read /Library/Preferences/com.apple.driver.AppleIRController | grep "DeviceEnabled" | awk '{ print $3 }')"
        if [[ ${SysProfIRReciever} -eq 0 ]]; then
            ScriptLogging "  No IR Receiver present."
        elif [[ ${SysProfIRReciever} -gt 0 ]]; then
            ScriptLogging "  IR Receiver present. Checking status..."
            if [[ ${AppleIRController} = "0;" ]]; then
                ScriptLogging "  IR Receiever disabled."
            else
                ScriptLogging "  IR Receiever enabled. Disabling..."
                /usr/bin/defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled 0
                ScriptLogging "  IR Receiever disabled."
            fi
        fi

        # 2.9 Enable Secure Keyboard Entry in terminal.app
        # Level 1 Scored
        # Let's not audit, let's just force it.
        ScriptLogging "  Enabling secure text entry in Terminal.app..."
        user_template com.apple.Terminal.plist SecureKeyboardEntry 1

        # 2.10 Java 6 is not the default Java runtime
        # Level 2 Scored
        # Java is the devil, installing it means you're a bad person.

        # 2.11 Configure Secure Empty Trash
        # Level 2 Scored, Level 1.5 Not Scored
        # Can be secured more appropriately with a configuration profile.
        # Issues with config profile, especially if they are not user removable, in the event that a large file has been
        # trashed, productivity can be hindered when emptying the trash. (only speaking from experience.) Gather requirements!
        # If configured here through the script, the user can easily enable/disable at will in Finder Preferences.

        if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
            ScriptLogging "  Enabling Secure Empty Trash..."
            user_template com.apple.finder EmptyTrashSecurely 1
            ScriptLogging "  Secure Empty Trash enabled."
        fi
}

loggingAndAuditing() {
# 3 Logging and Auditing
    ScriptLogging "3 Logging and Audting"

    # 3.1 Configure asl.conf
        # 3.1.1 Retain system.log for 90 or more days
        # Level 1 Scored
        # Contributed by John Oliver on CIS forums
        # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
        ScriptLogging "  Setting system.log to be kept for 90 Days..."
        /usr/bin/sed -i.bak 's/^>\ system\.log.*/>\ system\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=90/' /etc/asl.conf

        # 3.1.2 Retain appfirewall.log for 90 or more days
        # Level 1 Scored
        # Contributed by John Oliver on CIS forums
        # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
        ScriptLogging "  Setting appfirewall.log to be kept for 90 Days..."
        /usr/bin/sed -i.bak 's/^\?\ \[=\ Facility\ com.apple.alf.logging\]\ .*/\?\ \[=\ Facility\ com.apple.alf.logging\]\ file\ appfirewall.log\ rotate=seq\ ttl=90/' /etc/asl.conf

        # 3.1.3 Retain authd.log for 90 or more days
        # Level 1 Scored
        # Contributed by John Oliver on CIS forums
        # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
        ScriptLogging "  Setting authd.log to be kept for 90 Days..."
        /usr/bin/sed -i.bak 's/^\*\ file\ \/var\/log\/authd\.log.*/\*\ file\ \/var\/log\/authd\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=90/' /etc/asl/com.apple.authd

    # 3.2 Enable security auditing
    # Level 1 Scored
    local AuditD
    AuditD="$(/bin/launchctl list | grep -i auditd | awk '{ print $3 }')"
    if [[ ${AuditD} = "com.apple.auditd" ]]; then
        ScriptLogging "  Security Auditing enabled."
    else
        ScriptLogging "  Security Auditing NOT enabled."
        /bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist
        ScriptLogging "  Security Auditing enabled."
    fi

    # 3.3 Configure Security Auditing Flags
    # Level 2 Scored, Level 1.5 Not Scored
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
        /usr/bin/sed -i '' 's/^flags:.*/flags:ad,aa,lo/' /etc/security/audit_control
        /usr/bin/sed -i '' 's/^expire-after:.*/expire-after:90d\ AND\ 1G/' /etc/security/audit_control
    fi

    # 3.4 Enable remote logging for Desktops on trusted networks
    # Level 2 Not Scored
    # Audit procedure is not listed. Seems nearly impossible to audit this in an automated general way.

    # 3.5 Retain install.log for 365 or more days
    # Level 1 Scored
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    ScriptLogging "  Setting install.log to be kept for 365 Days..."
    /usr/bin/sed -i.bak 's/^\*\ file\ \/var\/log\/install\.log.*/\*\ file\ \/var\/log\/install\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=365/' /etc/asl/com.apple.install
}

networkConfigurations() {
# 4 Network Configurations
    ScriptLogging "4 Network Configurations"

    # 4.1 Disable Bonjour advertising service
    # Level 2 Scored, Level 1.5 Not Scored
    #TODO: Test. New audit/remediation written.

    if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
        local checkBonjourAdvertising
        checkBonjourAdvertising="$(/usr/bin/defaults read /Library/Preferences/com.apple.alf globalstate)"
        if [ "$checkBonjourAdvertising" = "1" ] || [ "$checkBonjourAdvertising" = "2" ]; then
            ScriptLogging "  Bonjour Advertising is disabled."
        else
            ScriptLogging "  Bonjour Advertising is enabled. Disabling..."
            /usr/bin/defaults write /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist ProgramArguements -array-add '{-NoMulticastAdvertisements;}'
            ScriptLogging "  Bonjour Advertising is disabled."
        fi
    fi

    # 4.2 Enable "Show Wi-Fi status in menu bar"
    # Level 1 Scored
    ScriptLogging "  Ensuring Wi-Fi is shown in MenuBar..."
    user_template com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Airport.menu"
    ScriptLogging "  Wi-Fi is shown in MenuBar."

    # 4.3 Create network specific locations
    # Level 2 Not Scored
    # TODO

    # 4.4 Ensure http server is not running
    # Level 1 Scored
    if /bin/launchctl list | egrep httpd > /dev/null; then
        ScriptLogging "  HTTP server is enabled. Disabling..."
        /usr/sbin/apachectl stop && /usr/bin/defaults write /System/Library/LaunchDaemons/org.apache.httpd Disabled -bool true
        ScriptLogging "  HTTP server disabled."
    else
        ScriptLogging "  HTTP server disabled."
    fi

    # 4.5 Ensure ftp server is not running
    # Level 1 Scored
    if /bin/launchctl list | egrep ftp > /dev/null; then
        ScriptLogging "  FTP server is enabled. Disabling..."
        /usr/sbin/launchctl unload -w /System/Library/LaunchDaemons/ftp.plist
        ScriptLogging "  FTP server disabled."
    else
        ScriptLogging "  FTP server disabled."
    fi

    # 4.6 Ensure nfs server is not running
    # Level 1 Scored
    if /bin/launchctl list | egrep nfsd > /dev/null; then
        ScriptLogging "  NFS server is enabled. Disabling..."
        /sbin/nfsd disable
        ScriptLogging "  NFS server disabled."
    elif [[ -e /etc/exports ]]; then
        rm /etc/export
    else
        ScriptLogging "  NFS server disabled."
    fi
}

systemAccess() {
# 5 System Access, Authentication and Authorization
    ScriptLogging "5 System Access, Authenticationn and Authorization"

    # 5.1 File System Permissions and Access Controls
        # 5.1.1 Secure Home Folders
        # Level 1 Scored
        # This script is intended to run BEFORE a system is deployed. Maybe a umask here, but not sure how to implement it.

        # 5.1.2 Repair permissions regularly to ensure binaries and other System files have appropriate permissions
        # Level 1 Not Scored
        # Can either set this in the weekly cron, or use the MDM to control this. MDM is prefered, as it is more maleable to timing/editing.

        # 5.1.3 Check System Wide Applications for appropriate permissions
        # Level 1 Scored
        # This should be checked prior to deployment within your apps/packages. Can also be run as a weekly cron or use MDM.

        # 5.1.4 Check System folder for world writable files
        # Level 1 Scored
        # So long as you do not introduce this into your environment through bad packaging, there's no need to remediate this. Can also be run as a weekly cron or use MDM.

        # 5.1.5 Check Library folder for world writable files
        # Level 2 Scored
        # GarageBand looks to be a culprit here. Should be removed/repackaged on systems through imaging/MDM.

    # 5.2 Password Management
    # TODO
    # Need to find a way to set the pwpolicy for users that don't yet exist in the system. The remediation procedure is for a logged in user.
    # It might be that this should be configured via Configuration Policy instead
    # See Section 8.1 and 8.2 for possible plist that can be packaged and deployed.

        # 5.2.1 Configure account lockout threshold
        # Level 1 Scored
        # pwpolicy -getaccountpolicies | grep -A 1 '<key>policyAttributeMaximumFailedAuthentications</key>' | tail -1 | cut -d'>' -f2 | cut -d '<' -f1
        #  pwpolicy -setaccountpolicies

        # 5.2.2 Set a minimum password length
        # Level 1 Scored

        # 5.2.3 Complex passwords must contain an Alphabetic Character
        # Level 1 Scored

        # 5.2.4 Complex passwords must contain a Numeric Character
        # Level 1 Scored

        # 5.2.5 Complex passwords must contain a Special Character
        # Level 1 Scored

        # 5.2.6 Complex passwords must [contain] uppercase and lowercase letters
        # Level 1 Scored

        # 5.2.7 Password Age
        # Level 1 Scored

        # 5.2.8 Password History
        # Level 1 Scored

    # 5.3 Reduce the sudo timeout period
    # Level 1 Scored
    if [[ "$(< /etc/sudoers | grep timestamp)" -eq 0 ]]; then
        echo "No sudo timeout modification present. Default is 5 minutes."
    else
        echo "sudo timeout modification present."
    fi

    # 5.4 Automatically lock the login keychain for inactivity
    # Level 2 Scored
    # User specific. Check to see if can be implemented via config profile. Default is 'no limit.'

    # 5.5 Ensure login keychain is locked when the computer sleeps
    # Level 2 Scored
    # User specific. Check to see if can be implemented via config profile. Default is 'no limit.'

    # 5.6 Enable OCSP and CRL certificate checking
    # Level 2 Scored

    # 5.7 Do not enable the "root" account
    # Level 1 Scored
    #TODO: Test. New audit/remediation written.
    # this is requiring expected statements. will look into expect

    #if [[ "$(/usr/bin/dscl . -read /Users/root AuthenticationAuthority)" = "No such key: AuthenticationAuthority" ]]; then
    #    ScriptLogging "  Root user is disabled."
    #else
    #    ScriptLogging "  Root user is enabled. Disabling..."
    #    /usr/sbin/dsenableroot -d
    #    ScriptLogging "  Root user is disabled."
    #fi

    # 5.8 Disable automatic login
    # Level 1 Scored
    #TODO: Test. New audit/remediation written.

    if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.loginwindow | grep autoLoginUser > /dev/null)" -eq 0 ]]; then
        ScriptLogging "  Auto login is disabled."
    else
        ScriptLogging "  Auto login enabled. Disabling..."
        /usr/bin/defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser
        ScriptLogging "  Auto login is disabled."
    fi

    # 5.9 Require a password to wake the computer from sleep or screen saver
    # Level 1 Scored
    #TODO: Test. New audit/remediation written.

    if [[ "$(/usr/bin/defaults read com.apple.screensaver askForPassword)" = "1" ]]; then
        ScriptLogging "  Password required to wake from sleep or screensaver."
    else
        ScriptLogging "  Password NOT required to wake from sleep or screensaver. Enabling..."
        /usr/bin/defaults write com.apple.screensaver askForPassword -int 1
        ScriptLogging "  Password required to wake from sleep or screensaver."
    fi

    # 5.10 Require an administrator password to access system-wide preferences
    # Level 1 Scored
    #TODO: Test. New audit/remediation written.

    if [[ "$(/usr/bin/security authorizationdb read system.preferences 2> /dev/null | grep -A1 shared | grep -E '(true|false)')" = "        <false/>" ]]; then
        ScriptLogging "  Password required to access system-wide preferences."
    else
        ScriptLogging "  Password NOT required to access system-wide preferences. Enabling..."
        /usr/bin/security authorizationdb read system.preferences > /tmp/system.preferences.plist
        /usr/bin/defaults write /tmp/system.preferences.plist shared -bool false
        /usr/bin/security authorizationdb write system.preferences < /tmp/system.preferences.plist
        rm /tmp/system.preferences.plist
        ScriptLogging "  Password required to access system-wide preferences."
    fi

    # 5.11 Disable ability to login to another user's active and locked session
    # Level 1 Scored
    # Need sed here to edit /etc/pam.d/screensaver
    # I believe this is off by default.

    # 5.12 Create a custom message for the Login Screen
    # Level 1 Scored
    if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.loginwindow.plist | grep LoginwindowText 2> /dev/null)" ]]; then
        ScriptLogging "  Login Message set."
    else
        ScriptLogging "  Login Message not set. Setting..."
        /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "This system is reserved for authorized use only. The use of this system may be monitored."
        ScriptLogging "  Login Message set."
    fi

    # 5.13 Create a Login window banner
    # Level 2 Scored
    #TODO: Test. New audit/remediation written.
    if [[ ${CISLEVEL} = "2" ]]; then
        if [[ ! -e /Library/Security/PolicyBanner.txt ]]; then
            ScriptLogging "  'PolicyBanner.txt' not found."
            echo "This system is reserved for authorized use only. The use of this system may be monitored." > /Library/Security/PolicyBanner.txt
            ScriptLogging "  Login Window banner set."
        else
            ScriptLogging "  Login Window banner set."
        fi
    fi

    # 5.14 Do not enter a password-related hint
    # Level 1 Scored
    # TODO
    # Per user. for/while in USER_TEMPLATE

    # 5.15 Disable Fast User Switching
    # Level 2 Not Scored
    # Level 1.5 Not Scored
    #TODO: Test. New audit/remediation written.

    if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
        if [[ "$(/usr/bin/defaults read /Library/Preferences/.GlobalPreferences.plist MultipleSessionEnabled)" = "0" ]]; then
            ScriptLogging "  Fast User Switching disabled."
        else
            ScriptLogging "  Fast User Switching enabled. Disabling..."
            /usr/bin/defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool NO
            ScriptLogging "  Fast User Switching disabled."
        fi
    fi

    # 5.16 Secure individual keychain items
    # Level 2 Not Scored

    # 5.17 Create specialized keychains for different purposes
    # Level 2 Not Scored

    # 5.18 Install an approved tokend for smartcard authentication
    # Level 2 Scored
    # TODO
}

userEnvironment() {
# 6 User Accounts and Environment
    ScriptLogging "6 User Accounts and Environment"

    # 6.1 Accounts Preferences Action Items
        # 6.1.1 Display login window as name and password
        # Level 1 Scored
        # No audit, just do it.
        # If using FileVault 2, this does not matter and should be commented out.
        ScriptLogging "  Setting LoginWindow to display as username and password..."
        /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool yes

        # 6.1.2 Disable "Show password hints"
        # Level 1 Scored
        # No audit, just do it.
        ScriptLogging "  Disabling password hints..."
        /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0

        # 6.1.3 Disable guest account login
        # Level 1 Scored
        # No audit, just do it.
        ScriptLogging "  Disabling the Guest account..."
        /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool NO

        # 6.1.4 Disable "Allow guests to connect to shared folders"
        # Level 1 Scored
        # No audit, just do it.
        ScriptLogging "  Disabling Guests from connecting to Shared folders..."
        /usr/bin/defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool no
        /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool no

    # 6.2 Turn on filename extensions
    # Level 1 Scored
    # No audit, just do it.
    ScriptLogging "  Enabling file extensions..."
    /usr/bin/defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # 6.3 Disable the automatic run of safe files in Safari (Scored)
    # Level 1 Scored
    # No audit, just do it.
    ScriptLogging "  Disabling auto-run of safe files in Safari..."
    /usr/bin/defaults write com.apple.Safari AutoOpenSafeDownloads -boolean no

    # 6.4 Use parental controls for systems that are not centrally managed
    # Level 2 Not Scored
}

additionalConsiderations() {
# 7 Appendix: Additional Considerations
# These have been removed from the mainScript () to be cleaner, since they don't do anything.
# Leaving the function as a "completionist"
    ScriptLogging "7 Appendix: Additional Considerations"
    ScriptLogging "  Please see the Benchmark documentation for Additional Considerations."

    # 7.1 Wireless technology on OS X
    # Level 2 Not Scored

    # 7.2 iSight Camera Privacy and Confidentiality Concerns
    # Level 2 Not Scored

    # 7.3 Computer Name Considerations
    # Level 2 Not Scored

    # 7.4 Software Inventory Considerations
    # Level 2 Not Scored

    # 7.5 Firewall Consideration
    # Level 2 Not Scored

    # 7.6 Automatic Actions for Optical Media
    # Level 1 Not Scored
    # No optical media drives on any new endpoints.

    # 7.7 App Store Automatically download apps purchased on other Macs Considerations
    # Level 2 Not Scored

    # 7.8 Extensible Firmware Interface (EFI) password
    # Level 2 Not Scored
    # Implement via your MDM/Imaging solution. If at all. FV2 mitigates much of the need.

    # 7.9 Apple ID password reset
    # Level 2 Not Scored
}

artifacts() {
# 8 Artifacts
# These have been removed from the mainScript() to be cleaner, since they don't do anything.
# Leaving the function as a "completionist"
    ScriptLogging "8 Artifacts"
    ScriptLogging "  Please see the Benchmark documentation for Artifacts."

    # 8.1 Password Policy Plist generated through OS X Server
    # Level 1 Not Scored
    # No Rationale, Audit or remediation provided by CIS
    # plist file is provided

    # 8.2 Password Policy Plist from man page
    # Level 1 Not Scored
    # No Rationale, Audit or remediation provided by CIS
    # plist file is provided
}

cleanAndReboot() {
# Reboot function
# left as a function in case you don't want to reboot after running the rest of the script
    ScriptLogging "  Rebooting for CIS Settings "
    /sbin/shutdown -r now
}

mainScript() {
    ScriptLogging " "
    ScriptLogging "  **************************************************  "
    ScriptLogging "            Starting CIS Level ${CISLEVEL} Settings"
    ScriptLogging "  **************************************************  "
    ScriptLogging "                  $(date +%Y-%m-%d\ %H:%M:%S)"

    if [[ ${CISLEVEL} = "1" ]] || [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
        ScriptLogging " "
    else
        ScriptLogging "  OH NO! You picked a CIS Level that doesn't exist. Maybe try again?"
        exit 1;
    fi

    # comment out sections you do not want to run.
    softwareUpdates
    systemPreferences
    loggingAndAuditing
    networkConfigurations
    systemAccess
    userEnvironment

    ScriptLogging " "
    ScriptLogging "   CIS Level ${CISLEVEL} Settings Finished! Time to restart..."
    ScriptLogging "  **************************************************  "
    ScriptLogging "                   $(date +%Y-%m-%d\ %H:%M:%S)"

    #cleanAndReboot
}

ScriptLogging() {
# ScriptLogging
# Dumps to system.log with prefix "CIS_SETTINGS"
    logger -t CIS_SETTINGS "$@"; echo "$@";
}

user_template() {
# Usage: user_template domain key action action action action action
# Ex: user_template com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Airport.menu"

    local PREFERENCE_DOMAIN=$1
    local PREFERENCE_KEY=$2
    PREFERENCE_ARGS=( $3 $4 $5 $6 $7 )

    # Set for user template
    for USER_TEMPLATE in "/System/Library/User Template"/*
        do
            /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/"${PREFERENCE_DOMAIN}" "${PREFERENCE_KEY}" "${PREFERENCE_ARGS[@]}"
    done

    # Set for already created users
    for USER_HOME in /Users/*
        do
            USER_UID=$(basename "${USER_HOME}")
            if [ ! "${USER_UID}" = "Shared" ]; then
                if [ ! -d "${USER_HOME}"/Library/Preferences ]; then
                    /bin/mkdir -p "${USER_HOME}"/Library/Preferences
                    /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library
                    /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
                fi
                if [ -d "${USER_HOME}"/Library/Preferences ]; then
                    /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/"${PREFERENCE_DOMAIN}" "${PREFERENCE_KEY}" "${PREFERENCE_ARGS[@]}"
                fi
            fi
    done
}

# Set up args for level selection
CISLEVEL=""
while [[ $# -gt 1 ]]
    do
        key="$1"

        case $key in
            -l|--level)
            CISLEVEL="$2"
            shift # past argument
            ;;
            --default)
            DEFAULT=YES
            ;;
            *)
            # unknown option
            ;;
        esac
        shift # past argument or value
    done

    if [[ ${CISLEVEL} = "" ]]; then
        CISLEVEL="1"    # Make sure this is a string, not an integer.
    fi
# Run mainScript
mainScript
