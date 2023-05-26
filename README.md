# icinga2-sms

Sending Icinga 2 notifications via SMS with SPRYNG!

## About
Derived from Gabriel Ulici's work at https://github.com/GabrielUlici/icinga2-sms

## Examples

The phone numbers have to be international format, e.g. +3212345678. For a contact there is the possibility to add multiple numbers as a comma separated list.

'+XXXX'

'+XXXX, ‭+XXXX‬, +XXXX‬'

## Authentication file

Via argument `-a` you reference an external authenticaion file holding your credentials for SPRYNG. This prevents you from saving these secrets within the script file itself, or within Icinga.

The authentication file structure should be as follows:
```ini
ORIGINATOR="NAME"
ROUTE="0000"
BEARERTOKEN=ab12cd34ef56gh78ij90kl...
```

### Testing a notification

```bash
$ sudo -u nagios ./host-by-sms.sh \
  -a spryng.auth \
  -d 'LONGDATE' \
  -l 'HOSTALIAS' \
  -n 'HOSTDISPLAYNAME' \
  -o 'HOSTOUTPUT' \
  -r '+XXXX' \
  -s 'HOSTSTATE' \
  -t 'NOTIFICATIONTYPE'
```

```text
Output SMS : [PROBLEM] Host host-display-name is WARNING!
```

```bash
$ sudo -u nagios ./service-by-sms.sh \
  -a spryng.auth \
  -d 'LONGDATE' \
  -e 'SERVICENAME' \
  -l 'HOSTALIAS' \
  -n 'HOSTDISPLAYNAME' \
  -o 'HOSTOUTPUT' \
  -r '+XXXX, ‭+XXXX‬, +XXXX‬' \
  -s 'SERVICESTATE' \
  -t 'NOTIFICATIONTYPE' \
  -u 'SERVICEDISPLAYNAME'`
```

```text
Output SMS :  [RECOVERY] processes on host-display-name is OK!
```

### Icinga2 objects
#### Example Command Definitions

```json
object NotificationCommand "Host Alarm By SMS" {
    import "plugin-notification-command"
    command = [ "/usr/lib/nagios/plugins/host-by-sms.sh" ]
    arguments += {
        "-a" = {
            required = true
            value = "$host-by-sms-authfile$"
        }
        "-d" = {
            required = true
            value = "$icinga.long_date_time$"
        }
        "-l" = {
            required = true
            value = "$host.name$"
        }
        "-n" = {
            required = true
            value = "$host.display_name$"
        }
        "-o" = {
            required = true
            value = "$host.output$"
        }
        "-r" = {
            required = true
            value = "$user.pager$"
        }
        "-s" = {
            required = true
            value = "$host.state$"
        }
        "-t" = {
            required = true
            value = "$notification.type$"
        }
        "-v" = "$notification_logtosyslog$"
    }
}
```

```json
object NotificationCommand "Service Alarm By SMS" {
    import "plugin-notification-command"
    command = [ "/usr/lib/nagios/plugins/service-by-sms.sh" ]
    arguments += {
        "-a" = {
            required = true
            value = "$service-by-sms-authfile$"
        }
        "-d" = {
            required = true
            value = "$icinga.long_date_time$"
        }
        "-e" = {
            required = true
            value = "$service.name$"
        }
        "-l" = {
            required = true
            value = "$host.name$"
        }
        "-n" = {
            required = true
            value = "$host.display_name$"
        }
        "-o" = {
            required = true
            value = "$service.output$"
        }
        "-r" = {
            required = true
            value = "$user.pager$"
        }
        "-s" = {
            required = true
            value = "$service.state$"
        }
        "-t" = "$notification.type$"
        "-u" = {
            required = true
            value = "$service.display_name$"
        }
        "-v" = {
            required = false
            value = "$notification_logtosyslog$"
        }
    }
}
```
