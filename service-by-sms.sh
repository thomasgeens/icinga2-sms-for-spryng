#!/usr/bin/env bash
## Created 20191001 / Last updated 20220712
## Thomas Geens <thomas@geens.be>
## Gabriel Ulici <ulicigabriel@gmail.com>

PROG="`basename $0`"
HOSTNAME="`hostname`"
# Name of authfile containing the credentials etc.
# Make sure you exclude this file from your repository using .gitignore
# Example content:
#   ORIGINATOR="TUI"
#   ROUTE="2693"
#   BEARERTOKEN=***************
AUTHFILE=spryng.auth

function Usage() {
cat << EOF

The following are mandatory:
  -a AUTHFILE (\$authfile$)
  -d LONGDATETIME (\$icinga.long_date_time$)
  -e SERVICENAME (\$service.name$)
  -l HOSTALIAS (\$host.name$)
  -n HOSTDISPLAYNAME (\$host.display_name$)
  -o HOSTOUTPUT (\$host.output$)
  -r USERPHONE (\$user.phone$)
  -s SERVICESTATE (\$host.state$)
  -t NOTIFICATIONTYPE (\$notification.type$)
  -u SERVICEDISPLAYNAME (\$service.display_name$)

And these are optional:
  -v VERBOSE (\$notification_sendtosyslog$)

EOF

exit 1;
}

while getopts 4:6:a:b:c:d:e:f:hi:l:n:o:r:s:t:u:v: opt
do
  case "$opt" in
    a) AUTHFILE=$OPTARG ;;
    d) LONGDATETIME=$OPTARG ;;
    e) SERVICENAME=$OPTARG ;;
    l) HOSTALIAS=$OPTARG ;;
    n) HOSTDISPLAYNAME=$OPTARG ;;
    o) HOSTOUTPUT=$OPTARG ;;
    r) USERPHONE=$OPTARG ;;
    s) SERVICESTATE=$OPTARG ;;
    t) NOTIFICATIONTYPE=$OPTARG ;;
    u) SERVICEDISPLAYNAME=$OPTARG ;;
    v) VERBOSE=$OPTARG ;;
   \?) echo "ERROR: Invalid option -$OPTARG" >&2
       Usage ;;
    :) echo "Missing option argument for -$OPTARG" >&2
       Usage ;;
    *) echo "Unimplemented option: -$OPTARG" >&2
       Usage ;;
  esac
done

shift $((OPTIND - 1))

## Retrieve authentication variables from auth file
source $AUTHFILE
# remove leading whitespace characters
ORIGINATOR="${ORIGINATOR#"${ORIGINATOR%%[![:space:]]*}"}"
# remove trailing whitespace characters
ORIGINATOR="${ORIGINATOR%"${ORIGINATOR##*[![:space:]]}"}"
# remove leading whitespace characters
ROUTE="${ROUTE#"${ROUTE%%[![:space:]]*}"}"
# remove trailing whitespace characters
ROUTE="${ROUTE%"${ROUTE##*[![:space:]]}"}"
# remove leading whitespace characters
BEARERTOKEN="${BEARERTOKEN#"${BEARERTOKEN%%[![:space:]]*}"}"
# remove trailing whitespace characters
BEARERTOKEN="${BEARERTOKEN%"${BEARERTOKEN##*[![:space:]]}"}"

## Build the message's subject
SUBJECT="[$NOTIFICATIONTYPE] $SERVICEDISPLAYNAME on $HOSTDISPLAYNAME is $SERVICESTATE!"

## Check if there are multiple numbers in the USERPHONE var
IFS=',' # space is set as delimiter
read -ra ADDR <<< "$USERPHONE" # str is read into an array as tokens separated by IFS
for PHONE in "${ADDR[@]}"; do # access each element of array
    # remove leading whitespace characters
    PHONE="${PHONE#"${PHONE%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    PHONE="${PHONE%"${PHONE##*[![:space:]]}"}"

    ## Build the notification message
    NOTIFICATION_MESSAGE=`cat << EOF
    Subject: $SUBJECT
    To: $PHONE

    ***** Icinga 2 Host Monitoring on $HOSTNAME *****

    ==> $SERVICEDISPLAYNAME on $HOSTDISPLAYNAME is $SERVICESTATE! <==

    Info?    $SERVICEOUTPUT

    Originator? $ORIGINATOR
    Route?      $ROUTE

    When?    $LONGDATETIME
    Service? $SERVICENAME (aka "$SERVICEDISPLAYNAME")
    Host?    $HOSTALIAS (aka "$HOSTDISPLAYNAME")

EOF
    `

    ## Are we verbose? Then put a message to syslog.
    if [ "$VERBOSE" == "true" ] ; then
      logger "$PROG sends $SUBJECT => $PHONE"
      ## print to terminal
      /usr/bin/printf "%b" "$NOTIFICATION_MESSAGE"
    fi

    ## And finally: send the SMS using TWILIO.
    CURL=$(curl --trace service-by-sms.txt --location --request POST https://rest.spryngsms.com/v1/messages \
    --header "Accept: application/json" \
    --header "Authorization: Bearer $BEARERTOKEN" \
    --header "Content-Type: application/json" \
    --data-raw "{
    "\"body"\": "\"$SUBJECT"\",
    "\"encoding"\": "\"auto"\",
    "\"originator"\": "\"$ORIGINATOR"\",
    "\"recipients"\": [
      "\"$PHONE"\"
    ],
    "\"route"\": "\"$ROUTE"\"
}")

    ## Are we verbose? Then put a message to syslog.
    if [ "$VERBOSE" == "true" ] ; then
      /usr/bin/printf "%b" "$CURL"
    fi

done