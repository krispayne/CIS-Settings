#!/bin/bash
########################################################################
# CIS Level 1 Benchmark Settings 1.2.0
# Yosemite (10.10)
# Kris Payne
#
# Run as root
#
# # Usage: scriptname.sh -l [1,2,1.5]
# 1 = All Scored Level 1 benchmarks (default)
# 2 = All Scored Level 1 and 2 benchmarks
# 1.5 = All Scored Level 1 benchmarks with sensible secure recommendations as well as some Level 2
########################################################################


# ScriptLogging
ScriptLogging() { logger -t CIS_SETTINGS "$@"; echo "$@"; }

# Set up args

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

ScriptLogging "    CIS LEVEL = ${CISLEVEL}"

# 1 Install Updates, Patches and Additional Security Software
softwareUpdates() {

    ScriptLogging "1 Install Updates, Patches, and Additional Security Software"
    ScriptLogging "  "

    # 1.1 Verify all Apple provided software is current
    # Level 1 Scored
    if [[ "$(/usr/sbin/softwareupdate -l | grep -ic "No new software available.")" -eq 0 ]]; then
        ScriptLogging "  No new software available."
    else
        ScriptLogging "  Installing Software Updates."
        /usr/sbin/softwareupdate -i -a > ScriptLogging 2>&1
    fi

    # 1.2 Enable Auto Update
    # Level 1 Scored
    if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled)" = 1 ]]; then
        ScriptLogging "  Automatic Update Check already enabled."
    else
        /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -int 1 > ScriptLogging 2>&1
    fi

    # 1.3 Enable app update installs
    # Level 1 Scored
    if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.commerce AutoUpdate)" = "1" ]]; then
        ScriptLogging "  Auto Update Apps already enabled."
    else
        /usr/bin/defaults write /Library/Preferences/com.apple.storeagent AutoUpdate -bool TRUE > ScriptLogging 2>&1
    fi

    # 1.4 Enable system data files and security update installs
    # Level 1 Scored
    if [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate | egrep '(ConfigDataInstall)')" = "ConfigDataInstall = 1;" ]]; then
        ScriptLogging "  ConfigDataInstall is 1."
    elif [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate | egrep '(CriticalUpdateInstall)')" = "CriticalUpdateInstall = 1;" ]]; then
        ScriptLogging "  CriticalUpdateInstall is 1."
    else
        ScriptLogging "  Enabling system data files and security updates."
        /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true > ScriptLogging 2>&1
        /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true > ScriptLogging 2>&1
    fi

    # 1.5 Enable OS X update installs
    # Level 1 Scored
    if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired)" = "1" ]]; then
        ScriptLogging "  OS X is set to auto update."
    else
        ScriptLogging "  Setting OS X to auto update."
        /usr/bin/defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool TRUE > ScriptLogging 2>&1
    fi
}

# 2 System Preferences
systemPreferences() {

    ScriptLogging "2 System Preferences"
    ScriptLogging " "

        ScriptLogging "  2.1 Bluetooth"
        # 2.1 Bluetooth

        # 2.1.1 Turn off Bluetooth, if no paired devices exist
        # Level 1 Scored
        ScriptLogging "    Turn off Bluetooth, if no paired devices exist."
        if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState)" = "1" ]]; then
            ScriptLogging "  Bluetooth ControllerPowerState is 1."

            if [[ "$(system_profiler | grep "Bluetooth:" -A 20 | grep Connectable | awk '{ print $2 }')" = "Yes" ]]; then
                ScriptLogging "    Bluetooth ControllerPowerState is 1 and there are paired devices.\n"
            elif [[ "$(system_profiler | grep "Bluetooth:" -A 20 | grep Connectable | awk '{ print $2 }')" = "No" ]]; then
                ScriptLogging "    Bluetooth ControllerPowerState is 1 and there are no paired devices. Turning off Bluetooth."
                /usr/bin/defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0 > ScriptLogging 2>&1
            fi

        elif [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState)" = "0" ]]; then
            ScriptLogging "    Bluetooth ControllerPowerState is 0."
        else
        /usr/bin/defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0 > ScriptLogging 2>&1
        fi

        # 2.1.2 Turn off Bluetooth "Discoverable" mode when not pairing devices
        # Level 1 Scored
        # Starting with OS X (10.9) Bluetooth is only set to Discoverable when the Bluetooth System Preference
        # is selected. To ensure that the computer is not Discoverable do not leave that preference open.

        if [[ "$(/usr/sbin/system_profiler SPBluetoothDataType | grep -i discoverable | awk '{ print $2 }')" = "Off" ]]; then
            ScriptLogging "    Bluetooth is not discoverable."
        fi

        # 2.1.3 Show Bluetooth status in menu bar
        # Level 1 Scored
        # This is user level. This script is not run at user level.
        if [[ "$(/usr/bin/defaults read com.apple.systemuiserver menuExtras | grep Bluetooth.menu)" = "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" ]]; then
           ScriptLogging "    Bluetooth shown in menu bar."
        else
            /usr/bin/defaults write com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" > ScriptLogging 2>&1
        fi


        ScriptLogging "  2.2 Date & Time"
        # 2.2 Date & Time

        # 2.2.1 Enable "Set time and date automatically"
        # Level 2 Not Scored
        # Level 1.5 Not Scored
        if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
            if [[ "$(/usr/sbin/systemsetup -getusingnetworktime | awk '{ print $3 }')" = "On" ]]; then
                ScriptLogging "    NetworkTime on. Ensuring server is time.apple.com."

                if [[ "$(/usr/sbin/systemsetup -getnetworktimeserver | awk '{ print $4 }')" = "time.apple.com" ]]; then
                    ScriptLogging "    NetworkTime is on and set to time.apple.com."
                fi

            else
                if [[ ! -e /etc/ntp.conf ]]; then
                    ScriptLogging "    Create '/etc/ntp.conf'"
                    /usr/bin/touch /etc/ntp.conf > ScriptLogging 2>&1
                fi

                ScriptLogging "    Set NetworkTime to time.apple.com."
                /usr/sbin/systemsetup -setnetworktimeserver time.apple.com > ScriptLogging 2>&1
                ScriptLogging "    Ensure NetworkTime is on."
                /usr/sbin/systemsetup -setusingnetworktime on > ScriptLogging 2>&1

            fi
        fi

        # 2.2.2 Ensure time set is within appropriate limits
        # Level 1 Scored
        /usr/sbin/ntpdate -sv time.apple.com > ScriptLogging 2>&1


        ScriptLogging "  2.3 Desktop & Screen Saver"
        # 2.3 Desktop & Screen Saver

        # 2.3.1 Set an inactivity interval of 20 minutes or less for the screen saver
        # Level 1 Scored
        # User configuration profiles are more useful here.
        # Make sure what is set in the config profile is smaller than section 2.3.3

        #/usr/bin/defaults -currentHost write com.apple.screensaver idleTime 600

        # 2.3.2 Secure screen saver corners
        # Level 2 Scored
        # Level 1.5 Not Scored
        # Take a "clear-all" approach here, as 2.3.4 sets an active corner for enabling screensaver.

        # Set in User Template
        if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
            for USER_TEMPLATE in "/System/Library/User Template"/*
                do
                    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.dock wvous-tl-corner 1 > ScriptLogging 2>&1
                    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.dock wvous-tr-corner 1 > ScriptLogging 2>&1
                    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.dock wvous-bl-corner 1 > ScriptLogging 2>&1
                    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.dock wvous-br-corner 1 > ScriptLogging 2>&1
            done

            # Set for already created users
            for USER_HOME in /Users/*
                do
                    USER_UID=$(basename "${USER_HOME}")
                    if [ ! "${USER_UID}" = "Shared" ]; then
                        if [ ! -d "${USER_HOME}"/Library/Preferences ]; then
                            /bin/mkdir -p "${USER_HOME}"/Library/Preferences > ScriptLogging 2>&1
                            /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library > ScriptLogging 2>&1
                            /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences > ScriptLogging 2>&1
                        fi
                        if [ -d "${USER_HOME}"/Library/Preferences ]; then
                            /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.dock wvous-tl-corner 1 > ScriptLogging 2>&1
                            /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.dock wvous-tr-corner 1 > ScriptLogging 2>&1
                            /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.dock wvous-bl-corner 1 > ScriptLogging 2>&1
                            /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.dock wvous-br-corner 1 > ScriptLogging 2>&1
                        fi
                    fi
            done
        fi

        # 2.3.3 Verify Display Sleep is set to a value larger than the Screen Saver
        # Level 1 Not Scored
        # Level 1.5
        if [[ ${CISLEVEL} = "1.5" ]]; then
            /usr/bin/pmset -a displaysleep 15 > ScriptLogging 2>&1
        fi

        # 2.3.4 Set a screen corner to Start Screen Saver
        # Level 1 Scored
        /usr/bin/defaults write ~/Library/Preferences/com.apple.dock wvous-br-corner 5 > ScriptLogging 2>&1


        ScriptLogging "  2.4 Sharing"
        # 2.4 Sharing
        # Level 1

        # 2.4.1 Disable Remote Apple Events
        # Level 1 Scored
        if [[ "$(/usr/sbin/systemsetup -getremoteappleevents | awk '{ print $4 }')" = "Off" ]]; then
            ScriptLogging "  Remote Apple Events set to off."
        else
            /usr/sbin/systemsetup -setremoteappleevents off > ScriptLogging 2>&1
            ScriptLogging "  Remote Apple Events set to off."
        fi

        # 2.4.2 Disable Internet Sharing
        # Level 1 Scored

        #TODO: Test. New audit/remediation written.

        # Internet Sharing is off by default. Running these commands without checking
        # first will send the machine into a downward sprial of doom and depair.
        # It's your funeral if you uncomment. Left in for remediation/completeness sake.
        # if [[ ! -e "/Library/Preferences/SystemConfiguration/com.apple.nat" ]]; then
        #     ScriptLogging "  No 'com.apple.nat' file present. Internet Sharing Disabled."
        # else
        #     /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict Enabled -int 0 > ScriptLogging 2>&1
        #     /bin/launchctl unload -w /System/Library/LaunchDaemons/ com.apple.InternetSharing.plist > ScriptLogging 2>&1
        # fi

        # 2.4.3 Disable Screen Sharing
        # Level 1 Scored

        #TODO: Test. New audit/remediation written.

        if [[ "$(/bin/launchctl load /System/Library/LaunchDaemons/com.apple.screensharing.plist)" = "/System/Library/LaunchDaemons/com.apple.screensharing.plist: Service is disabled" ]]; then
            ScriptLogging "  Screen Sharing Disabled."
        else
            /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -configure -access -off > ScriptLogging 2>&1
        fi

        # 2.4.4 Disable Printer Sharing
        # Level 1 Scored
        # No need to audit, just remediate.
        /usr/sbin/cupsctl --no-share-printers > ScriptLogging 2>&1

        # 2.4.5 Disable Remote Login
        # Level 1 Scored
        # Only open to service accounts.

        #TODO: Test. New audit/remediation written.

        if [[ "$(/usr/sbin/systemsetup -getremotelogin | awk '{ print $3 }')" = "Off" ]]; then
            ScriptLogging "  Remote Login Disabled."
        else
            /usr/sbin/systemsetup -setremotelogin off > ScriptLogging 2>&1
            ScriptLogging "  Remote Login Disabled."
        fi

        # 2.4.6 Disable DVD or CD Sharing
        # Level 1 Scored
        # Devices do not have Optical Drives

        # TODO design audit/remediate for older devices

        # 2.4.7 Disable Bluetooth Sharing
        # Level 1 Scored

        #TODO: Test. New audit/remediation written.

        if [[ "$(/usr/sbin/system_profiler SPBluetoothDataType | grep State)" = "Disabled\nDisabled\nDisabled" ]]; then
            ScriptLogging "  Bluetooth Sharing Disabled."
        else
            local hardwareUUID
            hardwareUUID=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | awk -F ": " '{print $2}')
            for USER_HOME in /Users/*
                do
                    USER_UID=$(basename "${USER_HOME}")
                        if [ ! "${USER_UID}" = "Shared" ]; then
                            if [ ! -d "${USER_HOME}"/Library/Preferences ]; then
                                /bin/mkdir -p "${USER_HOME}"/Library/Preferences > ScriptLogging 2>&1
                                /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library > ScriptLogging 2>&1
                                /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences > ScriptLogging 2>&1
                            fi
                            if [ ! -d "${USER_HOME}"/Library/Preferences/ByHost ]; then
                                /bin/mkdir -p "${USER_HOME}"/Library/Preferences/ByHost > ScriptLogging 2>&1
                                /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library > ScriptLogging 2>&1
                                /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences > ScriptLogging 2>&1
                                /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/ByHost > ScriptLogging 2>&1
                            fi
                            if [ -d "${USER_HOME}"/Library/Preferences/ByHost ]; then
                                /usr/bin/defaults write "$USER_HOME"/Library/Preferences/ByHost/com.apple.Bluetooth.$hardwareUUID.plist PrefKeyServicesEnabled -bool false > ScriptLogging 2>&1
                                #/usr/libexec/PlistBuddy -c "Delete :PrefKeyServicesEnabled"  "$USER_HOME"/Library/Preferences/ByHost/com.apple.Bluetooth.$hardwareUUID.plist
                                #/usr/libexec/PlistBuddy -c "Add :PrefKeyServicesEnabled bool false"  "$USER_HOME"/Library/Preferences/ByHost/com.apple.Bluetooth.$hardwareUUID.plist
                                /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/ByHost/com.apple.Bluetooth.$hardwareUUID.plist > ScriptLogging 2>&1
                            fi
                        fi
            done
        fi

        # 2.4.8 Disable File Sharing
        # Level 1 Scored

        #TODO: Test. New audit/remediation written.

        if [[ "$(/bin/launchctl list | egrep AppleFileServer)" -eq 0 ]]; then
            ScriptLogging "  AFP is enabled. Disabling..."
            echo "Disable AFP..."
        else
            ScriptLogging "  AFP is Disabled."
        fi

        if [[ "$(/bin/launchctl list | egrep smbd)" -eq 0 ]]; then
            ScriptLogging "  SMB is enabled. Disabling..."
            echo "Disable SMB..."
        else
            ScriptLogging "  SMB is Disbled."
        fi

        # 2.4.9 Disable Remote Management
        # Level 1 Scored

        # TODO
        # design audit/remediate


        ScriptLogging "  2.5 Energy Saver"
        # 2.5 Energy Saver

        # 2.5.1 Disable "Wake for network access"
        # Level 2 Scored
        # Level 1.5 Not Scored
        # Take a "clear-all" approach here
        if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
            /usr/bin/pmset -a womp 0 > ScriptLogging 2>&1
        fi

        # 2.5.2 Disable sleeping the computer when connected to power
        # Level 2 Scored
        # Level 1.5 Not Scored
        # Take a "clear-all" approach here
        if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
            /usr/bin/pmset -c sleep 0 > ScriptLogging 2>&1
        fi


        ScriptLogging "  2.6 Security & Privacy"
        # 2.6 Security & Privacy

        # 2.6.1 Enable FileVault
        # Level 1 Scored
        # This should be handled by an MDM with institutional keys.
        # audit is `diskutil cs list | grep -i encryption`

        # 2.6.2 Enable Gatekeeper
        # Level 1 Scored

        #TODO: Test. New audit/remediation written.

        if [[ "$(/usr/sbin/spctl --status)" = "assessments disabled" ]]; then
            ScriptLogging "  Gatekeeper is disabled. Enabling..."
            /usr/sbin/spctl --master-enable > ScriptLogging 2>&1
        else
            ScriptLogging "  Gatekeeper is enabled."
        fi

        # 2.6.3 Enable Firewall
        # Level 1 Scored

        #TODO: Test. New audit/remediation written.

        if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.alf globalstate)" -ge 1 ]]; then
            ScriptLogging "  Firewall enabled."
        else
            /usr/bin/defaults write /Library/Preferences/com.apple.alf globalstate -int 1 > ScriptLogging 2>&1
            ScriptLogging "  Firewall enabled."
        fi

        # 2.6.4 Enable Firewall Stealth Mode
        # Level 1 Scored

        #TODO: Test. New audit/remediation written.

        if [[ "$( /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode | grep -ic "Stealth mode enabled" )" -eq 0 ]]; then
            ScriptLogging "  Firewall Stealth Mode enabled."
        else
            ScriptLogging "  Enabling Firewall Stealth Mode."
            /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on > ScriptLogging 2>&1
            ScriptLogging "  Firewall Stealth Mode enabled."
        fi

        # 2.6.5 Review Application Firewall Rules
        # Level 1 Scored

        #TODO: Test. New audit/remediation written.

        if [[ "$(/usr/libexec/ApplicationFirewall/socketfilterfw --listapps | grep "ALF" | awk '{ print $7 }')" -lt 10 ]]; then
            ScriptLogging "  Number of apps is less than 10."
        else
            ScriptLogging "***** Number of apps is greater than 10, please investigate! *****"
        fi

        # 2.7 iCloud
        # This section has moved from Recommendations over to Subsections, however, no audit or remidiation guideleins are given.
        # Level 2 Not Scored
        # 2.7.1 iCloud configuration
        # 2.7.2 iCloud keychain
        # 2.7.3 iCloud Drive

        # 2.8 Pair the remote control infrared receiver if enabled
        # Level 1 Scored

        #TODO: Test. New audit/remediation written.

        if [[ "$(/usr/sbin/system_profiler 2>/dev/null | egrep "IR Receiver")" -eq 0 ]]; then
            ScriptLogging "  No IR Receiver present."
        elif [[ "$(/usr/sbin/system_profiler 2>/dev/null | egrep "IR Receiver")" -gt 0 ]]; then
            ScriptLogging "  IR Receiver present. Check to see if the interface is enabled."
            if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.driver.AppleIRController | awk '{ print $3 }')" = "0" ]]; then
                ScriptLogging "  IR Receiever Disabled."
            else
                /usr/bin/defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled 0 > ScriptLogging 2>&1
                ScriptLogging "  IR Receiever Disabled."
            fi
        fi

        # 2.9 Enable Secure Keyboard Entry in terminal.app
        # Level 1 Scored
        # Let's not audit, let's just force it.
        /usr/bin/defaults write -app Terminal SecureKeyboardEntry 1 > ScriptLogging 2>&1

        # 2.10 Java 6 is not the default Java runtime
        # Level 2 Scored
        # Java is the devil, installing it means you're a bad person.

        # 2.11 Configure Secure Empty Trash
        # Level 2 Scored
        # Level 1.5 Not Scored
        # Can be secured more appropriately with a configuration profile.
        # Issues with config profile, especially if they are not user removable, in the event that a large file has been
        # trashed, productivity can be hindered when emptying the trash. (only speaking from experience.) Gather requirements!
        # If configured here through the script, the user can easily enable/disable at will in Finder Preferences.

        if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
            for USER_TEMPLATE in "/System/Library/User Template"/*
                do
                    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder EmptyTrashSecurely 1 > ScriptLogging 2>&1
            done

            # Set for already created users
            for USER_HOME in /Users/*
                do
                    USER_UID=$(basename "${USER_HOME}")
                    if [ ! "${USER_UID}" = "Shared" ]; then
                        if [ ! -d "${USER_HOME}"/Library/Preferences ]; then
                            /bin/mkdir -p "${USER_HOME}"/Library/Preferences > ScriptLogging 2>&1
                            /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library > ScriptLogging 2>&1
                            /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences > ScriptLogging 2>&1
                        fi
                        if [ -d "${USER_HOME}"/Library/Preferences ]; then
                            /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder EmptyTrashSecurely 1 > ScriptLogging 2>&1
                        fi
                    fi
            done
        fi
}

# 3 Logging and Auditing
loggingAndAuditing() {

    ScriptLogging "3 Logging and Audting"
    ScriptLogging "  "


    ScriptLogging "  Configure asl.conf"
    # 3.1 Configure asl.conf

        # 3.1.1 Retain system.log for 90 or more days
        # Level 1 Scored
        # Contributed by John Oliver on CIS forums
        # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
        /usr/bin/sed -i.bak 's/^>\ system\.log.*/>\ system\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=90/' /etc/asl.conf > ScriptLogging 2>&1

        # 3.1.2 Retain appfirewall.log for 90 or more days
        # Level 1 Scored
        # Contributed by John Oliver on CIS forums
        # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
        /usr/bin/sed -i.bak 's/^\?\ \[=\ Facility\ com.apple.alf.logging\]\ .*/\?\ \[=\ Facility\ com.apple.alf.logging\]\ file\ appfirewall.log\ rotate=seq\ ttl=90/' /etc/asl.conf > ScriptLogging 2>&1

        # 3.1.3 Retain authd.log for 90 or more days
        # Level 1 Scored
        # Contributed by John Oliver on CIS forums
        # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
        /usr/bin/sed -i.bak 's/^\*\ file\ \/var\/log\/authd\.log.*/\*\ file\ \/var\/log\/authd\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=90/' /etc/asl/com.apple.authd > ScriptLogging 2>&1

    # 3.2 Enable security auditing
    # Level 1 Scored
    if [[ "$(/bin/launchctl list | grep -i auditd | awk '{ print $3 }')" = "com.apple.auditd" ]]; then
        ScriptLogging "  Security Auditing enabled."
    else
        /bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist > ScriptLogging 2>&1
    fi

    # 3.3 Configure Security Auditing Flags
    # Level 2 Scored
    # Level 1.5 Not Scored
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
        /usr/bin/sed -i '' 's/^flags:.*/flags:ad,aa,lo/' /etc/security/audit_control > ScriptLogging 2>&1
        /usr/bin/sed -i '' 's/^expire-after:.*/expire-after:90d\ AND\ 1G/' /etc/security/audit_control > ScriptLogging 2>&1
    fi

    # 3.4 Enable remote logging for Desktops on trusted networks
    # Level 2 Not Scored
    # Audit procedure is not listed. Seems nearly impossible to audit this in an automated general way.

    # 3.5 Retain install.log for 365 or more days
    # Level 1 Scored
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^\*\ file\ \/var\/log\/install\.log.*/\*\ file\ \/var\/log\/install\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=365/' /etc/asl/com.apple.install > ScriptLogging 2>&1
}

# 4 Network Configurations
networkConfigurations() {

    ScriptLogging "4 Network Configurations"
    ScriptLogging "  "

    # 4.1 Disable Bonjour advertising service
    # Level 2 Scored
    # Level 1.5 Not Scored

    #TODO: Test. New audit/remediation written.

    if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
        local checkBonjourAdvertising
        checkBonjourAdvertising="$(/usr/bin/defaults read /Library/Preferences/com.apple.alf globalstate)"
        if [ "$checkBonjourAdvertising" = "1" ] || [ "$checkBonjourAdvertising" = "2" ]; then
            ScriptLogging "  Bonjour Advertising is off."
        else
            ScriptLogging "  Bonjour Advertising is on. Shut it down."
            defaults write /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist ProgramArguements -array-add '{-NoMulticastAdvertisements;}' > ScriptLogging 2>&1
            ScriptLogging "  Bonjour Advertising is off."
        fi
    fi

    # 4.2 Enable "Show Wi-Fi status in menu bar"
    # Level 1 Scored
    # This is user level. This script is not run at user level.

    #TODO: Test. New audit/remediation written.

    if [[ "$(/usr/bin/defaults read com.apple.systemuiserver menuExtras | grep AirPort.menu)" = "/System/Library/CoreServices/Menu Extras/AirPort.menu" ]]; then
       ScriptLogging "    Airport shown in menu bar."
    else
        /usr/bin/defaults write com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/AirPort.menu" > ScriptLogging 2>&1
    fi

    # 4.3 Create network specific locations
    # Level 2 Not Scored

    # 4.4 Ensure http server is not running
    # Level 1 Scored
    # TODO
    #if /bin/ps -ef | grep -i httpd > /dev/null; then
    #    ScriptLogging "  HTTP server is running. Shut it down."
    #    /usr/sbin/apachectl stop && /usr/bin/defaults write /System/Library/LaunchDaemons/org.apache.httpd Disabled -bool true > ScriptLogging 2>&1
    #else
    #    ScriptLogging "  HTTP server not enabled."
    #fi

    # 4.5 Ensure ftp server is not running
    # Level 1 Scored
    # TODO
    #if /bin/launchctl list | egrep ftp > /dev/null; then
    #    ScriptLogging "  FTP server is running. Shut it down."
    #    /usr/sbin/launchctl unload -w /System/Library/LaunchDaemons/ftp.plist > ScriptLogging 2>&1
    #else
    #    ScriptLogging "  FTP server not enabled."
    #fi

    # 4.6 Ensure nfs server is not running
    # Level 1 Scored
    # TODO
    #if /bin/ps -ef | grep -i nfsd > /dev/null; then
    #    ScriptLogging "  NFS server is running. Shut it down."
    #    /sbin/nfsd disable > ScriptLogging 2>&1
    #elif [[ -e /etc/exports ]]; then
    #    rm /etc/export
    #else
    #    ScriptLogging "  NFS server not enabled."
    #fi
}

# 5 System Access, Authentication and Authorization
systemAccess() {

    ScriptLogging "5 System Access, Authenticationn and Authorization"
    ScriptLogging "  "

    # 5.1 File System Permissions and Access Controls
    ScriptLogging "  5.1 File System Permissions and Access Controls"

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
        # GarageBand looks to be a culprit here. Should be removed/repackaged.

    # 5.2 Password Management
    ScriptLogging "  5.2 Password Management"

    # TODO
    # Need to find a way to set the pwpolicy for users that don't yet exist in the system. The remidiation procedure is for a logged in user.
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
        echo "Change sudo timeout."
    fi
    # listed as issue on github : https://github.com/krispayne/CIS-Settings/issues/2

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


    if [[ "$(/usr/bin/dscl . -read /Users/root AuthenticationAuthority)" = "No such key: AuthenticationAuthority" ]]; then
        ScriptLogging "  'root' is disabled."
    else
        ScriptLogging "  'root' is enabled. Disabling..."
        /usr/sbin/dsenableroot -d > ScriptLogging 2>&1
        ScriptLogging "  'root' is disabled."
    fi

    # 5.8 Disable automatic login
    # Level 1 Scored

    #TODO: Test. New audit/remediation written.

    if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.loginwindow | grep autoLoginUser > /dev/null)" -eq 0 ]]; then
        ScriptLogging "  Auto login is disabled."
    else
        ScriptLogging "  Auto login enabled. Disabling..."
        /usr/bin/defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser > ScriptLogging 2>&1
        ScriptLogging "  Auto login is disabled."
    fi

    # 5.9 Require a password to wake the computer from sleep or screen saver
    # Level 1 Scored

    #TODO: Test. New audit/remediation written.

    if [[ "$(/usr/bin/defaults read com.apple.screensaver askForPassword)" = "1" ]]; then
        ScriptLogging "  Password required to wake from sleep or screensaver."
    else
        ScriptLogging "  Password NOT required to wake from sleep or screensaver. Fixing..."
        /usr/bin/defaults write com.apple.screensaver askForPassword -int 1 > ScriptLogging 2>&1
        ScriptLogging "  Password required to wake from sleep or screensaver."
    fi

    # 5.10 Require an administrator password to access system-wide preferences
    # Level 1 Scored

    #TODO: Test. New audit/remediation written.

    if [[ "$(/usr/bin/security authorizationdb read system.preferences 2> /dev/null | grep -A1 shared | grep -E '(true|false)')" = "<false/>" ]]; then
        ScriptLogging "  Password required to access system-wide preferences."
    else
        ScriptLogging "  Password NOT required to access system-wide preferences. Fixing..."
        /usr/bin/security authorizationdb read system.preferences > /tmp/system.preferences.plist
        /usr/bin/defaults write /tmp/system.preferences.plist shared -bool false
        /usr/bin/security authorizationdb write system.preferences < /tmp/system.preferences.plist
        ScriptLogging "  Password required to access system-wide preferences."
    fi

    # 5.11 Disable ability to login to another user's active and locked session
    # Level 1 Scored
    # Need sed here to edit /etc/pam.d/screensaver

    # 5.12 Create a custom message for the Login Screen
    # Level 1 Scored
    if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.loginwindow.plist | grep LoginwindowText)" -eq 0 ]]; then
        ScriptLogging "  Login Message not set. Setting..."
        /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "This system is reserved for authorized use only. The use of this system may be monitored." > ScriptLogging 2>&1
        ScriptLogging "  Login Message set."
    else
        ScriptLogging "  Login Message set."
    fi

    # 5.13 Create a Login window banner
    # Level 2 Scored

    #TODO: Test. New audit/remediation written.
    if [[ ${CISLEVEL} = "2" ]] || [[ ${CISLEVEL} = "1.5" ]]; then
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
            /usr/bin/defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool NO > ScriptLogging 2>&1
            ScriptLogging "  Fast User Switching disabled."
        fi
    fi

    # 5.16 Secure individual keychain items
    # Level 2 Not Scored

    # 5.17 Create specialized keychains for different purposes
    # Level 2 Not Scored

    # 5.18 Install an approved tokend for smartcard authentication
    # Level 2 Scored
}

#  6 User Accounts and Environment
userEnvironment() {

    ScriptLogging "6 User Accounts and Environment"
    ScriptLogging "  "


    ScriptLogging "  6.1 Accounts Preferences Action Items"
    # 6.1 Accounts Preferences Action Items

        # 6.1.1 Display login window as name and password
        # Level 1 Scored
        # No audit, just do it.
        /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool yes > ScriptLogging 2>&1

        # 6.1.2 Disable "Show password hints"
        # Level 1 Scored
        # No audit, just do it.
        /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0 > ScriptLogging 2>&1

        # 6.1.3 Disable guest account login
        # Level 1 Scored
        # No audit, just do it.
        /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool NO > ScriptLogging 2>&1

        # 6.1.4 Disable "Allow guests to connect to shared folders"
        # Level 1 Scored
        # No audit, just do it.
        /usr/bin/defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool no > ScriptLogging 2>&1
        /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool no > ScriptLogging 2>&1

    # 6.2 Turn on filename extensions
    # Level 1 Scored
    # No audit, just do it.
    /usr/bin/defaults write NSGlobalDomain AppleShowAllExtensions -bool true > ScriptLogging 2>&1

    # 6.3 Disable the automatic run of safe files in Safari (Scored)
    # Level 1 Scored
    # No audit, just do it.
    /usr/bin/defaults write com.apple.Safari AutoOpenSafeDownloads -boolean no > ScriptLogging 2>&1

    # 6.4 Use parental controls for systems that are not centrally managed
    # Level 2 Not Scored
}

# 7 Appendix: Additional Considerations
additionalConsiderations() {

    # These have been removed from the mainScript () to be cleaner, since they don't do anything.
    # Leaving the function as a "completionist"

    ScriptLogging "7 Appendix: Additional Considerations"
    ScriptLogging "  Please see the Benchmark documentation for Additional Considerations."
    ScriptLogging "  "

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

# 8 Artifacts
artifacts() {

    # These have been removed from the mainScript () to be cleaner, since they don't do anything.
    # Leaving the function as a "completionist"

    ScriptLogging "8 Artifacts"
    ScriptLogging "  Please see the Benchmark documentation for Artifacts."
    ScriptLogging "  "

    # 8.1 Password Policy Plist generated through OS X Server
    # Level 1 Not Scored
    # No Rationale, Audit or remediation provided by CIS

    # 8.2 Password Policy Plist from man page
    # Level 1 Not Scored
    # No Rationale, Audit or remediation provided by CIS
}

# The Restarts
cleanAndReboot() {

    ScriptLogging " "
    ScriptLogging "CIS Level ${CISLEVEL} Settings Finished! Time to restart..."
    ScriptLogging "  **************************************************  "
    ScriptLogging "              $(date +%Y-%m-%d\ %H:%M:%S)"
    ScriptLogging " Rebooting for CIS Settings "
    /sbin/shutdown -r now
}

mainScript() {

    ScriptLogging "  **************************************************  "
    ScriptLogging "           Starting CIS Level ${CISLEVEL} Settings"
    ScriptLogging "  **************************************************  "
    ScriptLogging " "
    ScriptLogging "             $(date +%Y-%m-%d\ %H:%M:%S)"
    ScriptLogging " "

    # comment out sections you do not want to run.
    #softwareUpdates
    #systemPreferences
    #loggingAndAuditing
    #networkConfigurations
    #systemAccess
    #userEnvironment
    #cleanAndReboot
}

# Run mainScript
mainScript
