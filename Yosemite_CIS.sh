#!/bin/bash
########################################################################
# CIS Level 1 Benchmark Settings 1.1.0
# Yosemite (10.10)
# Kris Payne
########################################################################

# Log and log archive location
log_location="/var/log/cis_install.log"
archive_log_location="/var/log/cis_install-`date +%Y-%m-%d-%H-%M-%S`.log"

# 1 Install Updates, Patches and Additional Security Software
softwareUpdates() {

    ScriptLogging "1 Install Updates, Patches, and Additional Security Software"
    ScriptLogging "  -------------------  "

    # 1.1 Verify all Apple provided software is current (Scored)
    local softwareUpdateChecl
    softwareUpdateCheck="$( /usr/sbin/softwareupdate -l | grep -ic "No new software available." )"
    if [[ "$softwareUpdateCheck" -eq 0 ]]; then
        ScriptLogging "  No new software available."
    else
        ScriptLogging "  Installing Software Updates."
        /usr/sbin/softwareupdate -i -a 2>&1 >> ScriptLogging
    fi

    # 1.2 Enable Auto Update
    # Checks to see if computer is polling automatically for updates from Apple

    if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled)" = 1 ]]; then
        ScriptLogging "  Automatic Update Check already enabled."
    else
        /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -int 1 2>&1 >> ScriptLogging
    fi

    # SWU managed via policy in Casper

    # 1.3 Enable app update installs
    # Sets Mac App Store auto-update for installed apps.

    if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.commerce AutoUpdate)" = "1" ]]; then
        ScriptLogging "  Auto Update Apps already enabled."
    else
        /usr/bin/defaults write /Library/Preferences/com.apple.storeagent AutoUpdate -bool TRUE 2>&1 >> ScriptLogging
    fi

    # Policies via AutoPKG and Casper

    # 1.4 Enable system data files and security update installs

    if [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate | grep ConfigDataInstall)" = "ConfigDataInstall = 1;" ]]; then
        ScriptLogging "  ConfigDataInstall is 1."
    elif [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate | grep CriticalUpdateInstall)" = "CriticalUpdateInstall = 1;" ]]; then
        printf "  ConfigDataInstall is 1.\n"
    else
        ScriptLogging "  Enabling system data files and security updates."
        /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true 2>&1 >> ScriptLogging
        /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true 2>&1 >> ScriptLogging
    fi

    # Policy in Casper

    # 1.5 Enable OS X update installs

    if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired)" = "1" ]]; then
        ScriptLogging "  OS X is set to auto update."
    else
        ScriptLogging "  Setting OS X to auto update."
        /usr/bin/defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool TRUE 2>&1 >> ScriptLogging
    fi
    # Policy in Casper
sleep 5
}

# 2 System Preferences
systemPreferences() {

    ScriptLogging "2 System Preferences"
    ScriptLogging "  -------------------  "

        ScriptLogging "  2.1 Bluetooth"
        # 2.1 Bluetooth

        # 2.1.1 Turn off Bluetooth, if no paired devices exist (Scored)
        ScriptLogging "    Turn off Bluetooth, if no paired devices exist."
        if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState)" = "1" ]]; then
            ScriptLogging "  Bluetooth ControllerPowerState is 1."

            if [[ "$(system_profiler | grep "Bluetooth:" -A 20 | grep Connectable | awk '{ print $2 }')" = "Yes" ]]; then
                ScriptLogging "    Bluetooth ControllerPowerState is 1 and there are paired devices.\n"
            elif [[ "$(system_profiler | grep "Bluetooth:" -A 20 | grep Connectable | awk '{ print $2 }')" = "No" ]]; then
                ScriptLogging "    Bluetooth ControllerPowerState is 1 and there are no paired devices. Turning off Bluetooth."
                /usr/bin/defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0 2>&1 >> ScriptLogging
            fi

        elif [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState)" = "0" ]]; then
            ScriptLogging "    Bluetooth ControllerPowerState is 0."
        else
        /usr/bin/defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0 2>&1 >> ScriptLogging
        fi

        # 2.1.2 Turn off Bluetooth "Discoverable" mode when not pairing devices
        # Starting with OS X (10.9) Bluetooth is only set to Discoverable when the Bluetooth System Preference
        # is selected. To ensure that the computer is not Discoverable do not leave that preference open.

        if [[ "$(/usr/sbin/system_profiler SPBluetoothDataType | grep -i discoverable | awk '{ print $2 }')" = "Off" ]]; then
            ScriptLogging "    Bluetooth Discoverable is off."
        fi

        # uuid=`/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | cut -c22-57`
        # /usr/bin/defaults write /Users/$@/Library/Preferences/ByHost/com.apple.Bluetooth.$uuid DiscoverableState -bool no
        # /usr/sbin/chown $@ /Users/$@/Library/Preferences/ByHost/com.apple.Bluetooth.$uuid.plist
        # Stolen from http://krypted.com/mac-security/disabling-bluetooth-discoverable-mode/
        # Need to test.

        # 2.1.3 Show Bluetooth status in menu bar (Scored)
        if [[ "$(/usr/bin/defaults read com.apple.systemuiserver menuExtras | grep Bluetooth.menu)" = "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" ]]; then
           ScriptLogging "    Bluetooth shown in menu bar."
        else
            /usr/bin/defaults write com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" 2>&1 >> ScriptLogging
        fi

        # 2.2 Date & Time
            ScriptLogging "  2.2 Date & Time"

        # 2.2.1 Enable "Set time and date automatically" (Scored)
        if [[ "$(/usr/sbin/systemsetup -getusingnetworktime | awk '{ print $3 }')" = "On" ]]; then
            ScriptLogging "    NetworkTime already on. Ensuring server is time.apple.com."

            if [[ "$(/usr/sbin/systemsetup -getnetworktimeserver | awk '{ print $4 }')" = "time.apple.com" ]]; then
                ScriptLogging "    NetworkTime is set and is set to time.apple.com."
            fi

        else
            if [[ ! -e /etc/ntp.conf ]]; then
                ScriptLogging "    Create '/etc/ntp.conf'"
                /usr/bin/touch /etc/ntp.conf 2>&1 >> ScriptLogging
            fi

            ScriptLogging "    Set NetworkTime to time.apple.com."
            /usr/sbin/systemsetup -setnetworktimeserver time.apple.com
            ScriptLogging "    Ensure NetworkTime is on."
            /usr/sbin/systemsetup -setusingnetworktime on 2>&1 >> ScriptLogging

        fi

        # 2.2.2 Ensure time set is within appropriate limits
        /usr/sbin/ntpdate -sv time.apple.com 2>&1 >> ScriptLogging

        # 2.3 Desktop & Screen Saver
        ScriptLogging "  2.3 Desktop & Screen Saver"

        # 2.3.1 Set an inactivity interval of 20 minutes or less for the screen saver
        /usr/bin/defaults -currentHost write com.apple.screensaver idleTime 600 2>&1 >> ScriptLogging
        # going to move this to a user based configuration profile

        # 2.3.2 Secure screen saver corners
        # going to move this to a user based configuration profile

        # 2.3.3 Verify Display Sleep is set to a value larger than the Screen Saver (Not Scored)
        /usr/bin/pmset -a displaysleep 15 2>&1 >> ScriptLogging

        # 2.3.4 Set a screen corner to Start Screen Saver
        #/usr/bin/defaults write ~/Library/Preferences/com.apple.dock wvous-tl-corner 5

        # 2.4 Sharing
        ScriptLogging "  2.4 Sharing"

        # 2.4.1 Disable Remote Apple Events (Scored)
        if [[ "$(/usr/sbin/systemsetup -getremoteappleevents | awk '{ print $4 }')" = "Off" ]]; then
            ScriptLogging "  Remote Apple Events already set to off."
        else
            /usr/sbin/systemsetup -setremoteappleevents off 2>&1 >> ScriptLogging
        fi

        # 2.4.2 Disable Internet Sharing (Scored)
        # Internet Sharing is off by default. Running these commands without checking
        # first will send the machine into a downward sprial of doom and depair.
        # It's your funeral if you uncomment. Left in for remediation/completeness sake.
        # /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict Enabled -int 0
        # /bin/launchctl unload -w /System/Library/LaunchDaemons/ com.apple.InternetSharing.plist


        # 2.4.3 Disable Screen Sharing (Scored)
        # Screen sharing controlled by Remote Management Preferences

        # 2.4.4 Disable Printer Sharing (Scored)
        /usr/sbin/cupsctl --no-share-printers

        # 2.4.5 Disable Remote Login (Scored)
        # Controlled at Firewall
        # Also, open only for one user on systems. Defined in Casper

        # 2.4.6 Disable DVD or CD Sharing (Scored)
        # Devices do not have Optical Drives

        # 2.4.7 Disable Bluetooth Sharing
        # Needs work.

        # 2.4.8 Disable File Sharing (Scored)
        # Handled in netShareOff.sh

        # 2.4.9 Disable Remote Management (Scored)
        # Used in our environment. Disabling not preferred. Limited to one user, defined in Casper.

        # 2.5 Energy Saver
        ScriptLogging "  2.5 Energy Saver"

        # 2.5.1 Disable "Wake for network access"
        /usr/bin/pmset -a womp 0

        # 2.5.2 Disable sleeping the computer when connected to power
        /usr/bin/pmset -c sleep 0

        # 2.6 Security & Privacy
        ScriptLogging "  2.6 Security & Privacy"

        # 2.6.1 Enable FileVault (Scored)
        # We do not use FileVault in our environment

        # 2.6.2 Enable Gatekeeper (Scored)
        /usr/sbin/spctl --master-enable

        # 2.6.3 Enable Firewall (Scored)
        /usr/bin/defaults write /Library/Preferences/com.apple.alf globalstate -int 1

        # 2.6.4 Enable Firewall Stealth Mode
        local stealthMode
        stealthMode="$( /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode | grep -ic "Stealth mode enabled" )"
        if [[ "$stealthMode" -eq 0 ]]; then
            ScriptLogging "  Firewall Stealth Mode enabled."
        else
            ScriptLogging "  Enabling Firewall Stealth Mode."
            /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on  2>&1 >> ScriptLogging
        fi

        # 2.6.5 Review Application Firewall Rules
        # Needs work.

        # 2.7 iCloud
        # printf "2.7 iCloud"
        # this section is currently only set for Recommendations, not Published standards.

        # 2.8 Pair the remote control infrared receiver if enabled (Scored)
        # Disable:
        /usr/bin/defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled 0 2>&1 >> ScriptLogging

        # 2.9 Enable Secure Keyboard Entry in terminal.app (Scored)
        /usr/bin/defaults write -app Terminal SecureKeyboardEntry 1 2>&1 >> ScriptLogging

        # 2.10 Java 6 is not the default Java runtime

        # 2.11 Securely delete files as needed (Recommended)
        # Need to re-work this into either configuration profile or User Template.
        # /usr/bin/defaults write ~/Library/Preferences/com.apple.finder EmptyTrashSecurely 1
sleep 5
}

# 3 Logging and Auditing
loggingAndAuditing() {

    ScriptLogging "3 Logging and Audting"
    ScriptLogging "  -------------------  "

    # Test implementation with SumoLogic: http://www.sumologic.com/applications/mac-osx/

    # 3.1 Configure asl.conf
    ScriptLogging "  Configure asl.conf"

    # 3.1.1 Retain system.log for 90 or more days (Scored)
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^>\ system\.log.*/>\ system\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=90/' /etc/asl.conf 2>&1 >> ScriptLogging

    # 3.1.2 Retain appfirewall.log for 90 or more days (Scored)
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^\?\ \[=\ Facility\ com.apple.alf.logging\]\ .*/\?\ \[=\ Facility\ com.apple.alf.logging\]\ file\ appfirewall.log\ rotate=seq\ ttl=90/' /etc/asl.conf 2>&1 >> ScriptLogging

    # 3.1.3 Retain authd.log for 90 or more days (Scored)
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^\*\ file\ \/var\/log\/authd\.log.*/\*\ file\ \/var\/log\/authd\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=90/' /etc/asl/com.apple.authd 2>&1 >> ScriptLogging

    # 3.2 Enable security auditing (Scored)
    if [[ "$(/bin/launchctl list | grep -i auditd | awk '{ print $3 }')" = "com.apple.auditd" ]]; then
        ScriptLogging "  Security Auditing enabled."
    else
        /bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist 2>&1 >> ScriptLogging
    fi

    # 3.3 Configure Security Auditing Flags
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i '' 's/^flags:.*/flags:ad,aa,lo/' /etc/security/audit_control 2>&1 >> ScriptLogging
    /usr/bin/sed -i '' 's/^expire-after:.*/expire-after:90d\ AND\ 1G/' /etc/security/audit_control 2>&1 >> ScriptLogging

    # 3.4 Enable remote logging for Desktops on trusted networks
    # Needs work. Do not have remote logging server setup in my environment to test.

    # 3.5 Retain install.log for 365 or more days
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^\*\ file\ \/var\/log\/install\.log.*/\*\ file\ \/var\/log\/install\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=365/' /etc/asl/com.apple.install 2>&1 >> ScriptLogging
sleep 5
}

# 4 Network Configurations
networkConfigurations() {

    ScriptLogging "4 Network Configurations"
    ScriptLogging "  -------------------  "

    # 4.1 Disable Bonjour advertising service
    export checkBonjourAdvertising
    checkBonjourAdvertising="$(defaults read /Library/Preferences/com.apple.alf globalstate)"
    if [ "$checkBonjourAdvertising" = "1" ] || [ "$checkBonjourAdvertising" = "2" ]; then
        ScriptLogging "  Bonjour Advertising is off."
    else
        # need to work this section out. Editing a plist.
        ScriptLogging "  Bonjour Advertising is on. Shut it down."
    fi

    # 4.2 Enable "Show Wi-Fi status in menu bar" (Scored)
    # Set via script and policy in Casper

    # 4.3 Create network specific locations

    # 4.4 Ensure http server is not running
    # TODO
    # Getting an error here
    # HTTP server is running. Shut it down.
    # /System/Library/LaunchDaemons/org.apache.httpd.plist: Could not find specified service
    if /bin/ps -ef | grep -i httpd > /dev/null; then
        ScriptLogging "  HTTP server is running. Shut it down."
        /usr/sbin/apachectl stop && /usr/bin/defaults write /System/Library/LaunchDaemons/org.apache.httpd Disabled -bool true 2>&1 >> ScriptLogging
    else
        ScriptLogging "  HTTP server not enabled."
    fi

    # 4.5 Ensure ftp server is not running
    if /bin/launchctl list | egrep ftp > /dev/null; then
        ScriptLogging "  FTP server is running. Shut it down."
        /usr/sbin/launchctl unload -w /System/Library/LaunchDaemons/ftp.plist 2>&1 >> ScriptLogging
    else
        ScriptLogging "  FTP server not enabled."
    fi

    # 4.6 Ensure nfs server is not running
    if /bin/ps -ef | grep -i nfsd > /dev/null; then
        ScriptLogging "  NFS server is running. Shut it down."
        /sbin/nfsd disable 2>&1 >> ScriptLogging
    elif [[ -e /etc/exports ]]; then
        rm /etc/export
    else
        ScriptLogging "  NFS server not enabled."
    fi
sleep 5
}

# 5 System Access, Authentication and Authorization
systemAccess() {

    ScriptLogging "5 System Access, Authenticationn and Authorization"
    ScriptLogging "  -------------------  "

    # 5.1 File System Permissions and Access Controls
    ScriptLogging "  5.1 File System Permissions and Access Controls"

    # 5.1.1 Secure Home Folders (Scored)
    # Home folders are owned by the user only by default

    # 5.1.2 Check System Wide Applications for appropriate permissions
    # TODO

    # 5.1.3 Check System folder for world writable files (Scored)
    # TODO

    # 5.1.4 Check Library folder for world writable files (Scored)
    # TODO

    # 5.2 Password Management
    ScriptLogging "  5.2 Password Management"

    # TODO
    # This is set by AD in our environment, but doesn't account for local-only users
    # Need to find a way to set the pwpolicy for users that don't yet exist in the system. The remidiation procedure is for a logged in user.
    # It might be that this should be configured via Configuration Policy instead

    # 5.2.1 Configure account lockout threshold
    # Audit:
    # pwpolicy -getaccountpolicies | grep -A 1 '<key>policyAttributeMaximumFailedAuthentications</key>' | tail -1 | cut -d'>' -f2 | cut -d '<' -f1
    # Remediation
    #  pwpolicy -setaccountpolicies

    # 5.2.2 Set a minimum password length
    # 5.2.3 Complex passwords must contain an Alphabetic Character
    # 5.2.4 Complex passwords must contain a Numeric Character
    # 5.2.5 Complex passwords must contain a Special Character
    # 5.2.6 Complex passwords must uppercase and lowercase letters
    # 5.2.7 Password Age
    # 5.2.8 Password History


    # 5.3 Reduce the sudo timeout period
    # listed as issue on github : https://github.com/krispayne/CIS-Settings/issues/2

    # 5.4 Automatically lock the login keychain for inactivity
    # Cannot be easily implmented in our environment

    # 5.5 Ensure login keychain is locked when the computer sleeps
    # 5.6 Enable OCSP and CRL certificate checking
    # 5.7 Do not enable the "root" account (Scored)
    # Disabled by default

    # 5.8 Disable automatic login (Scored)

    if /usr/bin/defaults read /Library/Preferences/com.apple.loginwindow | grep autoLoginUser > /dev/null; then
        ScriptLogging "  Auto login is disabled."
    else
        ScriptLogging "  Auto login enabled. Disabling."
        /usr/bin/defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>&1 >> ScriptLogging
    fi

    # 5.9 Require a password to wake the computer from sleep or screen saver (Scored)
    # /usr/bin/defaults write com.apple.screensaver askForPassword -int 1

    # 5.10 Require an administrator password to access system-wide preferences (Not Scored)
    # Set via script sysPrefAdmin.sh

    # 5.11 Disable ability to login to another user's active and locked session (Scored)

    # 5.12 Create a custom message for the Login Screen

    # 5.13 Create a Login window banner
    /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "This system is reserved for authorized use only. The use of this system may be monitored."

    # 5.14 Do not enter a password-related hint
    # 5.15 Disable Fast User Switching
    # 5.16 Secure individual keychain items
    # 5.17 Create specialized keychains for different purposes
    # 5.18 System Integrity Protection status
    # 5.19 Install an approved tokend for smartcard authentication
sleep 5
}

#  6 User Accounts and Environment
userEnvironment() {

    ScriptLogging "6 User Accounts and Environment"
    ScriptLogging "  -------------------  "

    # 6.1 Accounts Preferences Action Items
    ScriptLogging "  6.1 Accounts Preferences Action Items"

    # 6.1.1 Display login window as name and password (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool yes 2>&1 >> ScriptLogging

    # 6.1.2 Disable "Show password hints" (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0 2>&1 >> ScriptLogging

    # 6.1.3 Disable guest account login (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool NO 2>&1 >> ScriptLogging

    # 6.1.4 Disable "Allow guests to connect to shared folders" (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool no 2>&1 >> ScriptLogging
    /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool no 2>&1 >> ScriptLogging

    # 6.2 Turn on filename extensions (Scored)
    /usr/bin/defaults write NSGlobalDomain AppleShowAllExtensions -bool true 2>&1 >> ScriptLogging

    # 6.3 Disable the automatic run of safe files in Safari (Scored)
    /usr/bin/defaults write com.apple.Safari AutoOpenSafeDownloads -boolean no 2>&1 >> ScriptLogging

    # 6.4 Use parental controls for systems that are not centrally managed
    # Centrally Managed
sleep 5
}

# 7 Additional Considerations
additionalConsiderations() {

    ScriptLogging "7 Appendix: Additional Considerations"
    ScriptLogging "  -------------------  "

    # 7.1 Wireless technology on OS X
    # 7.2 iSight Camera Privacy and Confidentiality Concerns
    # 7.3 Computer Name Considerations
    # 7.4 Software Inventory Considerations
    # 7.5 Firewall Consideration
    # 7.6 Automatic Actions for Optical Media
    # 7.7 App Store Automatically download apps purchased on other Macs Considerations
    # 7.8 Extensible Firmware Interface (EFI) password
    # 7.9 Apple ID password reset
    # 7.10 Repairing permissions is no longer needed with 10.11
    # 7.11 App Store Password Settings
sleep 5
}

# 8 Artifacts
artifacts() {

    ScriptLogging "8 Artifacts"
    ScriptLogging "  -------------------  "

    # 8.1 Password Policy Plist generated through OS X Server
    # 8.2 Password Policy Plist from man page
sleep 5
}

# The Restarts
cleanAndReboot() {

    ScriptLogging "  -------------------  "
    ScriptLogging "Finished! Time to restart..."
    ScriptLogging "  -------------------  "

    #/usr/bin/killall Finder
    #/usr/bin/killall SystemUIServer
    #/usr/bin/killall -HUP blued
    # ^ do we really need this if rebooting?

    ScriptLogging "`date +%Y-%m-%d\ %H:%M:%S`"
    ScriptLogging " "
    /sbin/shutdown -r now
}

ScriptLogging(){

    if [ -n "$1" ]; then
        IN="$1"
    else
        read IN # This reads a string from stdin and stores it in a variable called IN
    fi

    DATE=`date +%Y-%m-%d\ %H:%M:%S`
    LOG="$log_location"

    echo "$DATE" " $IN" >> $LOG
}

mainScript() {

    if [[ -f "$log_location" ]]; then
        /bin/mv $log_location $archive_log_location
    fi

    ScriptLogging "  -------------------  "
    ScriptLogging " Starting CIS Settings "
    ScriptLogging "  -------------------  "
    ScriptLogging " "
    ScriptLogging "`date +%Y-%m-%d\ %H:%M:%S`"
    ScriptLogging " "

    # comment out sections you do not want to run.
    softwareUpdates
    systemPreferences
    loggingAndAuditing
    networkConfigurations
    systemAccess
    userEnvironment
    additionalConsiderations
    artifacts
    cleanAndReboot
}

# Run mainScript
mainScript
