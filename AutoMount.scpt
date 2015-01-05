/**
 * Javascript (JXA) script for mounting network drives (MacOs X Yosemite), for
 * example from NAS, using smb or afp. If network is over wifi, the script
 * will try to connect for some time before it gives up.
 */

////////////////////////////////////////////////////////////////////////////////
//Settings//

//host name or IP address
var host = 'XXX.XXX.XXX.XXX';
//volumes to be mounted, replace 'Volume Name'
var volumes = ['Volume Name', 'Volume Name', 'Volume Name', 'Volume Name', 'Volume Name'];
//network drive user name, save password in keychain
var user = 'UserName';
//Check for network interval in seconds
var interval = 2;
//Maximum waiting time for network in seconds
var maxTime = 30;
//protocol, afp or smb
var prot = 'afp';

////////////////////////////////////////////////////////////////////////////////

//current waiting time in seconds
var waitTime = 0;

var app = Application.currentApplication();
app.includeStandardAdditions = true;

//get the password from keychain
function getPw (hostName) {
    var pw;
    
    try {
        pw = app.doShellScript('security find-internet-password -g -s ' +
            hostName + ' -a ' + user + ' | grep -n password');
    } catch (err) {
        if (err.toString().indexOf('could not be found') > 0) {
            //new keychain entry
            app.displayAlert('No keychain entry for host ' + hostName +
                ' - please mount in Finder first and save credentials ' +
                'in keychain.');
        } else {
            //Allow access dialog
            pw = err.toString();
        }
    }
    if (pw) {
        pw = pw.slice(pw.indexOf('\"') + 1, pw.lastIndexOf('\"'));
    }
    return pw;
}



//mount commands
function mnt (vol) {
    var msg = ' mounted';
    var pass = getPw(host);
    
    var mountCommand = 'mount';
    
    if (prot === 'afp') {
        mountCommand += ' -t afp afp://';
    } else {
        mountCommand += ' -t smbfs smb://';
    }
    
    try {
        app.doShellScript('mkdir /Volumes/' + vol);
        app.doShellScript(
            mountCommand +
            user + ':' +
            pass +
            '@' + host + '/' + vol +
            ' /Volumes/' + vol);
    } catch (err) {
        msg = ' mount failed: ' + err;
    }
        
    //Uncomment to show mount notification
    app.displayNotification(vol + msg, { timeout: 0 });
    
}


(function checkAndMount () {
    var i;
    
    try {
        //check if network drive host is available
        app.doShellScript('ping -t 1 -c 1 ' + host);
        
        for (i = 0; i < volumes.length; i++) {
            if (volumes[i] !== 'Volume Name') {
                mnt(volumes[i]);
            }
        }

    } catch (err) {
        delay(interval);
        waitTime += interval;
        if (waitTime <= maxTime) {
            checkAndMount();
        }
    }
})();
