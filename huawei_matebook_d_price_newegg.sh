#! /usr/bin/env bash

## Get the price of the Huawei Matebook D (AMD Ryzen 5) from newegg.com

## Matebook D URL
huawei_matebook_d_url="https://www.newegg.com/Product/Product.aspx?Item=N82E16834324036&Description=huawei%20matebook%20d%20amd%20ryzen%205&cm_re=huawei_matebook_d_amd_ryzen_5-_-34-324-036-_-Product"

## Matebook D price in dollars
huawei_matebook_d_price="\$$(python3 -c "import requests
print(requests.get('${huawei_matebook_d_url}').content.decode())" | grep -oP "(?<='price'\\scontent=')\\d{3}\\.\\d{2}(?=')")"

## Set DBUS_SESSION_BUS_ADDRESS and a desktop notification of the price
/usr/bin/env "$(grep -Ez DBUS_SESSION_BUS_ADDRESS "/proc/$(pgrep -u "${LOGNAME}" gnome-session)/environ" | tr -d '\0')" notify-send 'Huawei Matebook D' "${huawei_matebook_d_price}"


# vi:ft=sh:et:sts=2:sw=2:ts=8:tw=0
