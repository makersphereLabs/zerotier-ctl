#!/bin/bash

#
# team:     devops/zerotier-ctl
# status:   laboratory
# author:   Makersphere Labs <opensource@makersphere.org>
#
VERSION=1.1.14
#
#
#
ZT_AUTHFILE='/var/lib/zerotier-one/authtoken.secret'
ZT_PUBLICID='/var/lib/zerotier-one/identity.public'
ZT_NETWORK_PRIVATE=1
ZT_NETWORK_BRIDGING=0
ZT_NETWORK_V4_ASSIGN_MODE='zt'
ZT_NETWORK_V6_ASSIGN_MODE='none'
#
# Colors
#
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'
#
# Main Application
#
if [ "$1" != '' ]; then
    #
	# List all networks on this controller
	#
    if [ "$1" == 'listnetworks' ] || [ "$1" == 'list' ] || [ "$1" == '-l' ]; then
        echo
        echo -e "${ORANGE}=> List Networks${NC}";
        echo
        # Check if authtoken.secret exists
        if [ -f $ZT_AUTHFILE ]; then
            echo -e "${ORANGE}> Loading networks...${NC}";
            echo
            ZT_AUTHTOKEN=`cat $ZT_AUTHFILE`
            # Make a GET request to the API
            # Tested with ZeroTier One (1.1.4) API v1.
            ZT_API_RESPONSE=$(curl -LsfSw '\n%{http_code}' \
                            -X GET http://localhost:9993/controller/network?auth=${ZT_AUTHTOKEN})
            if [ "$(echo "$ZT_API_RESPONSE" | tail -n1 )" == '200' ]; then
                echo -e "> $(echo "$ZT_API_RESPONSE" | head -n-1 )";
                echo
                echo -e "${GREEN}==> Success${NC}";
                echo
				exit 0;
            else
                echo -e "${RED}==> Failed to connect to Controller${NC}";
                exit 1;
            fi
        else
            echo -e "${RED}==> The AuthFile is missing${NC}";
            exit 1;
        fi
    #
    # Add a new network to this controller
    #
    elif [ "$1" == 'create' ] || [ "$1" == '-c' ]; then
        echo
        echo -e "${ORANGE}=> Create Network${NC}";
        echo
        if [ "$2" != '' ]; then
            # Check if authtoken.secret exists
            if [ -f $ZT_AUTHFILE ]; then
                ZT_NETWORK_NAME=$2
                ZT_NETWORK_SERVER_ID=`head -c 10 $ZT_PUBLICID`;
                ZT_AUTHTOKEN=`cat $ZT_AUTHFILE`
                echo "> Add a configuration for network '${2}'..."
                read -p '> Enter a start IP address (e.g. 10.1.1.1): ' READ_IP
                if [ "$READ_IP" != '' ]; then
                    ZT_NETWORK_IP_START=$READ_IP
                    read -p '> Enter the last IP address (e.g. 10.1.1.254): ' READ_IP2
                    if [ "$READ_IP2" != '' ]; then
                        ZT_NETWORK_IP_END=$READ_IP2
                        read -p '> Enter the network address (e.g. 10.1.1.0): ' READ_ROUTE
                        if [ "$READ_ROUTE" != '' ]; then
                            ZT_NETWORK_IP_LOCAL_ROUTE=$READ_ROUTE
                            read -p '> Enter the network submask (e.g. /24): /' READ_MASK
                            if [ "$READ_MASK" != '' ]; then
                                ZT_NETWORK_IP_LOCAL_ROUTE_MASK=$READ_MASK
                            else
                                echo -e "${RED}==> Please enter a vaild submask${NC}";
                                exit 1;
                            fi
                        else
                            echo -e "${RED}==> Please enter a network address${NC}";
                            exit 1;
                        fi
                    else
                        echo -e "${RED}==> Please enter the last IP address${NC}";
                        exit 1;
                    fi
                else
                    echo -e "${RED}==> Please enter a start IP address${NC}";
                    exit 1;
                fi
                # Huge JSON file ahead
                # Do not change this JSON string!
                ZT_NETWORK_CONFIG="{\"auth\":\"${ZT_AUTHTOKEN}\",\"name\":\"${ZT_NETWORK_NAME}\",\"private\":${ZT_NETWORK_PRIVATE},\"allowPassiveBridging\":${ZT_NETWORK_BRIDGING},\"v4AssignMode\":\"${ZT_NETWORK_V4_ASSIGN_MODE}\",\"v6AssignMode\":\"${ZT_NETWORK_V6_ASSIGN_MODE}\",\"routes\":[{\"target\":\"${ZT_NETWORK_IP_LOCAL_ROUTE}/${ZT_NETWORK_IP_LOCAL_ROUTE_MASK}\",\"via\":null,\"flags\":0,\"metric\":0}],\"ipAssignmentPools\":[{\"ipRangeStart\":\"${ZT_NETWORK_IP_START}\",\"ipRangeEnd\":\"${ZT_NETWORK_IP_END}\"}],\"rules\":[{\"ruleNo\":10,\"action\":\"accept\"}]}"
                echo '> Do you wish to add this network?'
                select ZT_ADD_NET_YN in 'Yes' 'No'; do
                    case $ZT_ADD_NET_YN in
                        'Yes' )
                            # Make a POST request to the API
                            # Tested with ZeroTier One (1.1.4) API v1.
                            ZT_API_RESPONSE=$(curl -LsfSw '\n%{http_code}' \
                                -X POST -d "$ZT_NETWORK_CONFIG" \
                                http://localhost:9993/controller/network/${ZT_NETWORK_SERVER_ID}______?auth=${ZT_AUTHTOKEN})
                            if [ "$(echo "$ZT_API_RESPONSE" | tail -n1 )" == '200' ]; then
                                ZT_NETWORK_NWID=$(echo "$(echo "$ZT_API_RESPONSE" | head -n-1 )" | grep -Po '(?<="nwid": ")[^"]*')
                                echo -e "${GREEN}==> Network '${ZT_NETWORK_NAME}' (ID ${ZT_NETWORK_NWID}) was successfully added to controller '${ZT_NETWORK_SERVER_ID}'${NC}";
                                echo
                                exit 0;
                            else
                                echo -e "${RED}==> Failed to connect to Controller${NC}";
                                exit 1;
                            fi
                            #DEBUG: echo $ZT_NETWORK_CONFIG
                        break;;
                        'No' )
                            echo -e "${ORANGE}==> Nothing was added${NC}";
                            echo
                            exit 0;
                        exit;;
                    esac
                done
            else
                echo -e "${RED}==> The AuthFile is missing${NC}";
                exit 1;
            fi
        else
            echo -e "${RED}==> Please specify a network${NC}";
			exit 1;
        fi
    #
    # Remove a new network from this controller
    #
    elif [ "$1" == 'delete' ]  || [ "$1" == '-d' ]; then
        echo
        echo -e "${ORANGE}=> Delete Network${NC}";
        echo
        if [ "$2" != '' ]; then
            # Check if authtoken.secret exists
            if [ -f $ZT_AUTHFILE ]; then
                ZT_NETWORK_ID=$2
                ZT_AUTHTOKEN=`cat $ZT_AUTHFILE`
                echo '> Do you wish to remove this network?'
                select ZT_DEL_NET_YN in 'Yes' 'No'; do
                    case $ZT_DEL_NET_YN in
                        'Yes' )
                            # Make a DELETE request to the API
                            # Tested with ZeroTier One (1.1.4) API v1.
                            ZT_API_RESPONSE=$(curl -LsfSw '\n%{http_code}' \
                                -X DELETE http://localhost:9993/controller/network/${ZT_NETWORK_ID}?auth=${ZT_AUTHTOKEN})
                            if [ "$(echo "$ZT_API_RESPONSE" | tail -n1 )" == '200' ]; then
                                echo -e "${GREEN}==> Network '${ZT_NETWORK_ID}' was removed${NC}";
                                echo
                                exit 0;
                            else
                                echo -e "${RED}==> Failed to connect to Controller${NC}";
                                exit 1;
                            fi
                        break;;
                        'No' )
                            echo -e "${ORANGE}==> Nothing was removed${NC}";
                            echo
                            exit 0;
                        exit;;
                    esac
                done

            else
                echo -e "${RED}==> The AuthFile is missing${NC}";
                exit 1;
            fi
        else
            echo -e "${RED}==> Please specify a network${NC}";
			exit 1;
        fi
    #
    # Authorize a new client to a network
    #
    elif [ "$1" == 'auth' ]  || [ "$1" == '-a' ]; then
        echo
        echo -e "${ORANGE}=> Authorize Client${NC}";
        echo
        if [ "$2" != '' ] && [ "$3" != '' ]; then
            # Check if authtoken.secret exists
            if [ -f $ZT_AUTHFILE ]; then
                ZT_NETWORK=$2
                ZT_MEMBER=$3
                ZT_AUTHTOKEN=`cat $ZT_AUTHFILE`
                echo "> Do you wish to authorize this client (${ZT_MEMBER})?"
                select ZT_ADD_MEM_YN in 'Yes' 'No'; do
                    case $ZT_ADD_MEM_YN in
                        'Yes' )
                            # Make a POST request to the API
                            # Tested with ZeroTier One (1.1.4) API v1.
                            ZT_API_RESPONSE=$(curl -LsfSw '\n%{http_code}' \
                                -X POST -d "{\"authorized\":true}" \
                                http://localhost:9993/controller/network/${ZT_NETWORK}/member/${ZT_MEMBER}?auth=${ZT_AUTHTOKEN})
                            if [ "$(echo "$ZT_API_RESPONSE" | tail -n1 )" == '200' ]; then
                                echo -e "${GREEN}==> Client '${3}' was authorized to network '${2}'${NC}";
                                echo
                                exit 0;
                            else
                                echo -e "${RED}==> Failed to connect to Controller${NC}";
                                exit 1;
                            fi
                        break;;
                        'No' )
                            echo -e "${ORANGE}==> Nothing was added${NC}";
                            echo
                            exit 0;
                        exit;;
                    esac
                done
            else
                echo -e "${RED}==> The AuthFile is missing${NC}";
                exit 1;
            fi
        else
            echo -e "${RED}==> Please specify a network & client${NC}";
			exit 1;
        fi
    #
    # Deauthorize a client
    #
    elif [ "$1" == 'deauth' ] || [ "$1" == '-da' ]; then
        echo
        echo -e "${ORANGE}=> Deauthorize Client${NC}";
        echo
        if [ "$2" != '' ] && [ "$3" != '' ]; then
            # Check if authtoken.secret exists
            if [ -f $ZT_AUTHFILE ]; then
                ZT_NETWORK=$2
                ZT_MEMBER=$3
                ZT_AUTHTOKEN=`cat $ZT_AUTHFILE`
                echo "> Do you wish to deauthorize this client (${ZT_MEMBER})?"
                select ZT_DEL_MEM_YN in 'Yes' 'No'; do
                    case $ZT_DEL_MEM_YN in
                        'Yes' )
                            # Make a DELETE request to the API
                            # Tested with ZeroTier One (1.1.4) API v1.
                            ZT_API_RESPONSE=$(curl -LsfSw '\n%{http_code}' \
                                -X DELETE http://localhost:9993/controller/network/${ZT_NETWORK}/member/${ZT_MEMBER}?auth=${ZT_AUTHTOKEN})
                            echo $ZT_API_RESPONSE
                            if [ "$(echo "$ZT_API_RESPONSE" | tail -n1 )" == '200' ]; then
                                echo -e "${GREEN}==> Client '${3}' was deauthorized${NC}";
                                echo
                                exit 0;
                            else
                                echo -e "${RED}==> Failed to connect to Controller${NC}";
                                exit 1;
                            fi
                        break;;
                        'No' )
                            echo -e "${ORANGE}==> Nothing was removed${NC}";
                            echo
                            exit 0;
                        exit;;
                    esac
                done
            else
                echo -e "${RED}==> The AuthFile is missing${NC}";
                exit 1;
            fi
        else
            echo -e "${RED}==> Please specify a network & client${NC}";
			exit 1;
        fi
    #
    # Display help
    #
    elif [ "$1" == 'help' ] || [ "$1" == '-h' ]; then
        echo -e "
${ORANGE}+++ ZeroTier Controller CLI +++${NC}

Version ${VERSION}

Copyright © 2016 Makersphere Labs
Licensed under GNU GPL v3

Usage: zerotier-ctl <command> [<args>]

Available commands:
help                           - Display this help
listnetworks                   - List all network IDs
create <name>                  - Create a new network
delete <network>               - Delete a network
auth <network> <client>        - Authorize a client
deauth <network> <client>      - Deauthorize a client";
        echo
        exit 0;
    else
        echo -e "${ORANGE}==> Use 'help' to get started${NC}";
    	exit 1;
    fi
else
    echo -e "${ORANGE}==> Use 'help' to get started${NC}";
    exit 1;
fi
