#!/bin/bash
if [[ -d /root/ottbot ]]; then
    ipvps=$(curl -s "https://ipv4.icanhazip.com")
    if [ "$(curl -s "https://raw.githubusercontent.com/lalatlangau/iptv/main/panel_bot.sh" | grep -wc "${ipvps}")" != '0' ]; then
        firtsTimeRun() {

            [[ ! -f /usr/bin/jq ]] && {
                apt install jq
            }
            [[ ! -d /root/ottbot ]] && {
                mkdir -p /root/ottbot
                touch /root/ottbot/db.txt
                touch "/root/ottbot/all_id.txt"
            }
            [[ ! -f /root/ottbot/api.sh ]] && {
                wget -qO- api.samproject.tech/BotAPI.sh >/root/ottbot/api.sh
            }
            [[ ! -f /root/ottbot/bot.conf ]] && {
                echo -ne "Input your Bot TOKEN : "
                read bot_tkn
                echo "Token: $bot_tkn" >/root/ottbot/bot.conf
                echo -ne "Input your Admin ID : "
                read adm_ids
                echo "AdminID: $adm_ids" >>/root/ottbot/bot.conf
            }
        }
        firtsTimeRun

        source /root/ottbot/api.sh
        get_Token=$(sed -n '1 p' /root/ottbot/bot.conf | cut -d' ' -f2)
        get_AdminID=$(sed -n '2 p' /root/ottbot/bot.conf | cut -d' ' -f2)
        admin_password=$(grep -o 'admin_pass = "[^"]*' "/root/iptv-panel/data.txt" | grep -o '[^"]*$' | sed -n '1p')
        domain=$(sed -n '1p' /root/iptv-panel/domain.txt)
        API_BASE_URL="https://${domain}"
        database_id="/root/ottbot/all_id.txt"
        expired_data="/root/ottbot/expired.txt"

        ShellBot.init --token $get_Token --monitor --return map --flush --log_file /root/log_bot

        msg_welcome() {
            msg="Welcome ${message_from_first_name}\n"
            msg+="ID : <code>${message_from_id}</code>\n"
            if [ "$(grep -wc ${message_from_id} "/root/ottbot/db.txt")" != '0' ] || [ "${message_from_id[$id]}" == "$get_AdminID" ]; then
                response=$(curl -s --request GET \
                    --url "$API_BASE_URL/api/get_users_by_reseller?reseller_username=${message_from_id}&password_input=${admin_password}")
                balance=$(echo "${response}" | grep -o '"balance":[^,]*' | grep -o '[^:]*$')
                msg+="Balance : <code>${balance}</code>\n"
                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                    --text "$msg" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
            else
                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                    --text "$msg" \
                    --parse_mode html
            fi
        }

        backReq() {
            msg="Welcome ${callback_query_from_first_name}\n"
            msg+="ID : <code>${callback_query_from_id}</code>\n"
            if [ "$(grep -wc ${callback_query_from_id} "/root/ottbot/db.txt")" != '0' ] || [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                response=$(curl -s --request GET \
                    --url "$API_BASE_URL/api/get_users_by_reseller?reseller_username=${callback_query_from_id}&password_input=${admin_password}")
                balance=$(echo "${response}" | grep -o '"balance":[^,]*' | grep -o '[^:]*$')
                msg+="Balance : <code>${balance}</code>\n"
                ShellBot.editMessageText --chat_id ${callback_query_message_chat_id[$id]} \
                    --message_id ${callback_query_message_message_id[$id]} \
                    --text "$msg" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
            else
                ShellBot.editMessageText --chat_id ${callback_query_message_chat_id[$id]} \
                    --message_id ${callback_query_message_message_id[$id]} \
                    --text "$msg" \
                    --parse_mode html
            fi
        }

        menu_reseller() {
            if [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                msg="This Is Reseller Menu\n"
                ShellBot.editMessageText --chat_id ${callback_query_message_chat_id[$id]} \
                    --message_id ${callback_query_message_message_id[$id]} \
                    --text "$msg" \
                    --reply_markup "$keyboard2" \
                    --parse_mode html
            else
                ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                    --text "🚫 You're Not Admin 🚫"
            fi
            exit 0
        }

        add_reseller() {
            if [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                ShellBot.sendMessage --chat_id ${callback_query_message_chat_id[$id]} \
                    --text "Input Reseller Tele ID [CREATE]:" \
                    --reply_markup "$(ShellBot.ForceReply)"
            else
                ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                    --text "🚫 You're Not Admin 🚫"
            fi
            exit 0
        }

        del_reseller() {
            if [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                ShellBot.sendMessage --chat_id ${callback_query_message_chat_id[$id]} \
                    --text "Input Reseller Tele ID [DELETE]:" \
                    --reply_markup "$(ShellBot.ForceReply)"
            else
                ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                    --text "🚫 You're Not Admin 🚫"
            fi
            exit 0
        }

        bal_reseller() {
            if [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                ShellBot.sendMessage --chat_id ${callback_query_message_chat_id[$id]} \
                    --text "Input Reseller Tele ID [BALANCE]:" \
                    --reply_markup "$(ShellBot.ForceReply)"
            else
                ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                    --text "🚫 You're Not Admin 🚫"
            fi
            exit 0
        }

        add_custom() {
            if [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                ShellBot.sendMessage --chat_id ${callback_query_message_chat_id[$id]} \
                    --text "Input Username [Custom]:" \
                    --reply_markup "$(ShellBot.ForceReply)"
            else
                ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                    --text "🚫 You're Not Admin 🚫"
            fi
            exit 0
        }

        renew_custom() {
            if [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                ShellBot.sendMessage --chat_id ${callback_query_message_chat_id[$id]} \
                    --text "Input UUID [Custom]:" \
                    --reply_markup "$(ShellBot.ForceReply)"
            else
                ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                    --text "🚫 You're Not Admin 🚫"
            fi
            exit 0
        }

        create_reseller() {
            reseller_id=$1
            reseller_bal=$2
            response=$(curl -s --request POST \
                --url "$API_BASE_URL/api/register_reseller" \
                --header 'Content-Type: application/json' \
                --data '{
            "password": "'"$admin_password"'",
            "balance": '"$reseller_bal"',
            "username": "'"$reseller_id"'"
        }')
            reseller_password=$(echo "${response}" | grep -o '"password":"[^"]*' | grep -o '[^"]*$')
            if [ "$(echo "${response}" | grep -ic "User already exists")" != '0' ]; then
                ShellBot.sendMessage --chat_id ${message_from_id} \
                    --text "🚫 User Already Exist 🚫" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
            else
                echo "${reseller_id} ${reseller_password} " >>"/root/ottbot/db.txt"
                msg="Username : <code>${reseller_id}</code>\n"
                msg+="Password : <code>${reseller_password}</code>\n"
                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                    --text "Successful Register Reseller\n\n${msg}" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
                ShellBot.sendMessage --chat_id ${reseller_id} \
                    --text "Hi, Admin has registered you as RESELLER\n\n${msg}" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
            fi
            exit 0
        }

        req_delres() {
            reseller_id=$1
            if [ "$(grep -wc ${reseller_id} "/root/ottbot/db.txt")" != '0' ]; then
                response=$(curl -s --request POST \
                    --url "$API_BASE_URL/api/delete_reseller" \
                    --header 'Content-Type: application/json' \
                    --data '{
	"password": "'"$admin_password"'",
	"username": "'"$reseller_id"'"
}')
                if [ "$(echo "${response}" | grep -ic "not found")" == '0' ]; then
                    sed -i "/${reseller_id}/d" "/root/ottbot/db.txt"
                    ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                        --text "Successful Delete Reseller\n" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                    ShellBot.sendMessage --chat_id ${reseller_id} \
                        --text "Hi, Admin has DELETED you as RESELLER\n" \
                        --parse_mode html
                else
                    ShellBot.sendMessage --chat_id ${message_from_id} \
                        --text "🚫 Reseller Not Found 🚫" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                fi

            else
                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                    --text "Reseller Not Exist\n" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
            fi
            exit 0
        }

        add_balreq() {
            reseller_id=$1
            reseller_topup=$2
            if [ "$(grep -wc ${reseller_id} "/root/ottbot/db.txt")" != '0' ]; then
                reseller_password=$(grep -w "${reseller_id}" "/root/ottbot/db.txt" | awk '{print $2}')
                response=$(curl -s --request POST \
                    --url "$API_BASE_URL/api/add_reseller_balance" \
                    --header 'Content-Type: application/json' \
                    --data '{
            "username": "'"$reseller_id"'",
            "amount": '"$reseller_topup"',
            "password": "'"$admin_password"'"
        }')

                if [ "$(echo "${response}" | grep -ic "Reseller balance added successfully")" != '0' ]; then
                    new_balance=$(echo "${response}" | grep -o '"new_balance":[^,]*' | grep -o '[^:]*$')
                    ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                        --text "Successful Add Reseller Balance\n\nNew Balance : <code>${new_balance}</code>\n" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                    ShellBot.sendMessage --chat_id ${reseller_id} \
                        --text "Hi, Admin has add your account balance\n\nNew Balance : <code>${new_balance}</code>\n" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                else
                    ShellBot.sendMessage --chat_id ${message_from_id} \
                        --text "🚫 User Not Found 🚫" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                fi
            else
                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                    --text "Reseller Not Exist\n" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
            fi
            exit 0
        }

        menu_create() {
            if [ "$(grep -wc ${callback_query_from_id} "/root/ottbot/db.txt")" != '0' ] || [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                response=$(curl -s --request GET \
                    --url "$API_BASE_URL/api/get_users_by_reseller?reseller_username=${callback_query_from_id}&password_input=${admin_password}")
                balance=$(echo "${response}" | grep -o '"balance":[^,]*' | grep -o '[^:]*$')
                msg="Create ID Menu\n\n"
                msg+="Balance : <code>${balance}</code>\n"
                ShellBot.editMessageText --chat_id ${callback_query_message_chat_id[$id]} \
                    --message_id ${callback_query_message_message_id[$id]} \
                    --text "$msg" \
                    --reply_markup "$keyboardpackage" \
                    --parse_mode html
            else
                ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                    --text "🚫 Dont Has Access 🚫"
            fi
            exit 0
        }

        menu_renew() {
            if [ "$(grep -wc ${callback_query_from_id} "/root/ottbot/db.txt")" != '0' ] || [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                response=$(curl -s --request GET \
                    --url "$API_BASE_URL/api/get_users_by_reseller?reseller_username=${callback_query_from_id}&password_input=${admin_password}")
                balance=$(echo "${response}" | grep -o '"balance":[^,]*' | grep -o '[^:]*$')
                msg="Renew ID Menu\n\n"
                msg+="Balance : <code>${balance}</code>\n"
                ShellBot.editMessageText --chat_id ${callback_query_message_chat_id[$id]} \
                    --message_id ${callback_query_message_message_id[$id]} \
                    --text "$msg" \
                    --reply_markup "$keyboardrenew" \
                    --parse_mode html
            else
                ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                    --text "🚫 Dont Has Access 🚫"
            fi
            exit 0
        }

        choose_package() {
            if [ "$(grep -wc ${callback_query_from_id} "/root/ottbot/db.txt")" != '0' ] || [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                response=$(curl -s --request GET \
                    --url "$API_BASE_URL/api/get_users_by_reseller?reseller_username=${callback_query_from_id}&password_input=${admin_password}")
                balance=$(echo "${response}" | grep -o '"balance":[^,]*' | grep -o '[^:]*$')
                if [ ${callback_query_data[$id]} == _pakeja ]; then
                    package="a"
                elif [ ${callback_query_data[$id]} == _pakejb ]; then
                    package="b"
                elif [ ${callback_query_data[$id]} == _pakejc ]; then
                    package="c"
                elif [ ${callback_query_data[$id]} == _pakejtrial ]; then
                    package="trial"
                else
                    exit 0
                fi
                if [[ "${balance}" -ge "${price}" ]]; then
                    echo "$package" >"/tmp/cad.${callback_query_from_id[$id]}"
                    ShellBot.sendMessage --chat_id ${callback_query_message_chat_id[$id]} \
                        --text "Input Username :" \
                        --reply_markup "$(ShellBot.ForceReply)"
                else
                    ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                        --text "🚫 Insuficient Balance 🚫"
                fi
            else
                ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                    --text "🚫 Dont Has Access 🚫"
            fi
            exit 0
        }

        renew_package() {
            if [ "$(grep -wc ${callback_query_from_id} "/root/ottbot/db.txt")" != '0' ] || [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                response=$(curl -s --request GET \
                    --url "$API_BASE_URL/api/get_users_by_reseller?reseller_username=${callback_query_from_id}&password_input=${admin_password}")
                balance=$(echo "${response}" | grep -o '"balance":[^,]*' | grep -o '[^:]*$')
                if [ ${callback_query_data[$id]} == _renewa ]; then
                    package="a"
                elif [ ${callback_query_data[$id]} == _renewb ]; then
                    package="b"
                elif [ ${callback_query_data[$id]} == _renewc ]; then
                    package="c"
                else
                    exit 0
                fi
                if [[ "${balance}" -ge "${price}" ]]; then
                    echo "$package" >"/tmp/cad.${callback_query_from_id[$id]}"
                    ShellBot.sendMessage --chat_id ${callback_query_message_chat_id[$id]} \
                        --text "Input UUID :" \
                        --reply_markup "$(ShellBot.ForceReply)"
                else
                    ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                        --text "🚫 Insuficient Balance 🚫"
                fi
            else
                ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                    --text "🚫 Dont Has Access 🚫"
            fi
            exit 0
        }

        create_ott() {
            package=$1
            username=$2
            tele_id=$3
            exist=$4
            user_uuid=$5
            if [ "$(grep -wc ${message_from_id} "/root/ottbot/db.txt")" != '0' ] || [ "${message_from_id[$id]}" == "$get_AdminID" ]; then
                reseller_username=$(grep -w "${message_from_id}" "/root/ottbot/db.txt" | awk '{print $1}')
                reseller_password=$(grep -w "${message_from_id}" "/root/ottbot/db.txt" | awk '{print $2}')
                response=$(curl -s --request POST \
                    --url "$API_BASE_URL/api/add_user" \
                    --header 'Content-Type: application/json' \
                    --data '{
            "username": "'"$username"'",
            "reseller_username": "'"$reseller_username"'",
            "reseller_password": "'"$reseller_password"'",
            "package": "'"$package"'"
        }')

                if [ "$(echo "${response}" | grep -ic "User already exists")" != '0' ]; then
                    ShellBot.sendMessage --chat_id ${message_from_id} \
                        --text "🚫 User already exists 🚫" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                    exit 0
                elif [ "$(echo "${response}" | grep -ic "Insufficient balance")" != '0' ]; then
                    ShellBot.sendMessage --chat_id ${message_from_id} \
                        --text "🚫 Insuficient Balance 🚫" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                    exit 0
                else
                    new_balance=$(echo "${response}" | grep -o '"balance":[^,]*' | grep -o '[^:]*$')
                    date=$(echo "${response}" | grep -o '"expiration_date":"[^"]*' | grep -o '[^"]*$' | awk '{print $1}')
                    link=$(echo "${response}" | grep -o '"link":"[^"]*' | grep -o '[^"]*$')
                    username=$(echo "${response}" | grep -o '"username":"[^"]*' | grep -o '[^"]*$')
                    uuid=$(echo "${response}" | grep -o '"uuid":"[^"]*' | grep -o '[^"]*$')
                fi

                if [ "$(grep -wc ${uuid} "$database_id")" != '0' ]; then
                    sed -i "/${uuid}/d" "$database_id"
                fi
                if [ "$(grep -wc ${uuid} "$expired_data")" != '0' ]; then
                    sed -i "/${uuid}/d" "$expired_data"
                fi
                echo "### ${username} ${date} ${uuid} ${tele_id}" >>"$database_id"
                template_file="/root/iptv-panel/add_template.txt"
                template=$(<"$template_file")
                template=$(echo "${template}" | sed "s|\${date}|${date}|g")
                template=$(echo "${template}" | sed "s|\${link}|${link}|g")
                template=$(echo "${template}" | sed "s|\${username}|${username}|g")
                template=$(echo "${template}" | sed "s|\${uuid}|${uuid}|g")
                msg="$template"

                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                    --text "$msg" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
                ShellBot.sendMessage --chat_id ${tele_id} \
                    --text "$msg" \
                    --parse_mode html

            else
                ShellBot.sendMessage --chat_id ${message_from_id} \
                    --text "🚫 Dont Has Access 🚫" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
            fi
            exit 0
        }

        renew_ott() {
            package=$1
            username=$2
            tele_id=$3
            exist=$4
            user_uuid=$5
            if [ "$(grep -wc ${message_from_id} "/root/ottbot/db.txt")" != '0' ] || [ "${message_from_id[$id]}" == "$get_AdminID" ]; then
                reseller_username=$(grep -w "${message_from_id}" "/root/ottbot/db.txt" | awk '{print $1}')
                reseller_password=$(grep -w "${message_from_id}" "/root/ottbot/db.txt" | awk '{print $2}')
                response=$(curl -s --request POST \
                    --url "$API_BASE_URL/api/renew_user" \
                    --header 'Content-Type: application/json' \
                    --data '{
	"reseller_username": "'"$reseller_username"'",
	"reseller_password": "'"$reseller_password"'",
	"uuid": "'"$user_uuid"'",
	"package": "'"$package"'"
}')
                if [ "$(echo "${response}" | grep -ic "User not found")" != '0' ]; then
                    ShellBot.sendMessage --chat_id ${message_from_id} \
                        --text "🚫 User not found 🚫" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                    exit 0
                elif [ "$(echo "${response}" | grep -ic "Insufficient balance")" != '0' ]; then
                    ShellBot.sendMessage --chat_id ${message_from_id} \
                        --text "🚫 Insuficient Balance 🚫" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                    exit 0
                else
                    new_balance=$(echo "${response}" | grep -o '"new_reseller_balance":[^,]*' | grep -o '[^:]*$')
                    date=$(echo "${response}" | grep -o '"new_expiration_date":"[^"]*' | grep -o '[^"]*$' | awk '{print $1}')
                    username=$(echo "${response}" | grep -o '"username":"[^"]*' | grep -o '[^"]*$')
                    uuid=$(echo "${response}" | grep -o '"uuid":"[^"]*' | grep -o '[^"]*$')
                fi

                if [ "$(grep -wc ${uuid} "$database_id")" != '0' ]; then
                    sed -i "/${uuid}/d" "$database_id"
                fi
                if [ "$(grep -wc ${uuid} "$expired_data")" != '0' ]; then
                    sed -i "/${uuid}/d" "$expired_data"
                fi
                echo "### ${username} ${date} ${uuid} ${tele_id}" >>"$database_id"

                template_file="/root/iptv-panel/renew_template.txt"
                template=$(<"$template_file")
                template=$(echo "${template}" | sed "s|\${date}|${date}|g")
                template=$(echo "${template}" | sed "s|\${username}|${username}|g")
                template=$(echo "${template}" | sed "s|\${uuid}|${uuid}|g")
                msg="$template"

                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                    --text "$msg" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
                ShellBot.sendMessage --chat_id ${tele_id} \
                    --text "$msg" \
                    --parse_mode html

            else
                ShellBot.sendMessage --chat_id ${message_from_id} \
                    --text "🚫 Dont Has Access 🚫" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
            fi
            exit 0
        }

        req_add_custom() {
            user_file=$1
            username=$(sed -n '1p' "${user_file}" | awk '{print $1}')
            days=$(sed -n '2p' "${user_file}" | awk '{print $1}')
            tele_id=$(sed -n '3p' "${user_file}" | awk '{print $1}')
            if [ "${message_from_id[$id]}" == "$get_AdminID" ]; then
                reseller_username=$(grep -w "${message_from_id}" "/root/ottbot/db.txt" | awk '{print $1}')
                reseller_password=$(grep -w "${message_from_id}" "/root/ottbot/db.txt" | awk '{print $2}')

                response=$(curl -s --request POST \
                    --url "$API_BASE_URL/api/add_user_custom" \
                    --header 'Content-Type: application/json' \
                    --data '{
            "admin_password": "'"$admin_password"'",
            "reseller_username": "'"$reseller_username"'",
            "reseller_password": "'"$reseller_password"'",
            "username": "'"$username"'",
            "days": '"$days"'
        }')
                if [ "$(echo "${response}" | grep -ic "User already exists")" != '0' ]; then
                    ShellBot.sendMessage --chat_id ${message_from_id} \
                        --text "🚫 User already exists 🚫" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                    exit 0
                elif [ "$(echo "${response}" | grep -ic "Insufficient balance")" != '0' ]; then
                    ShellBot.sendMessage --chat_id ${message_from_id} \
                        --text "🚫 Insuficient Balance 🚫" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                    exit 0
                else
                    date=$(echo "${response}" | grep -o '"expiration_date":"[^"]*' | grep -o '[^"]*$' | awk '{print $1}')
                    link=$(echo "${response}" | grep -o '"link":"[^"]*' | grep -o '[^"]*$')
                    username=$(echo "${response}" | grep -o '"username":"[^"]*' | grep -o '[^"]*$')
                    uuid=$(echo "${response}" | grep -o '"uuid":"[^"]*' | grep -o '[^"]*$')
                fi

                if [ "$(grep -wc ${uuid} "$database_id")" != '0' ]; then
                    sed -i "/${uuid}/d" "$database_id"
                fi
                if [ "$(grep -wc ${uuid} "$expired_data")" != '0' ]; then
                    sed -i "/${uuid}/d" "$expired_data"
                fi

                echo "### ${username} ${date} ${uuid} ${tele_id}" >>"$database_id"
                template_file="/root/iptv-panel/add_template.txt"
                template=$(<"$template_file")
                template=$(echo "${template}" | sed "s|\${date}|${date}|g")
                template=$(echo "${template}" | sed "s|\${link}|${link}|g")
                template=$(echo "${template}" | sed "s|\${username}|${username}|g")
                template=$(echo "${template}" | sed "s|\${uuid}|${uuid}|g")
                msg="$template"

                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                    --text "$msg" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
                ShellBot.sendMessage --chat_id ${tele_id} \
                    --text "$msg" \
                    --parse_mode html
            else
                ShellBot.sendMessage --chat_id ${message_from_id} \
                    --text "🚫 Dont Has Access 🚫" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
            fi
            exit 0
        }

        req_renew_custom() {
            uuid=$1
            days=$2
            tele_id=$3
            if [ "${message_from_id[$id]}" == "$get_AdminID" ]; then
                reseller_username=$(grep -w "${message_from_id}" "/root/ottbot/db.txt" | awk '{print $1}')
                reseller_password=$(grep -w "${message_from_id}" "/root/ottbot/db.txt" | awk '{print $2}')

                response=$(curl -s --request POST \
                    --url "$API_BASE_URL/api/renew_user_custom" \
                    --header 'Content-Type: application/json' \
                    --data '{
            "admin_password": "'"$admin_password"'",
            "reseller_username": "'"$reseller_username"'",
            "reseller_password": "'"$reseller_password"'",
            "uuid": "'"$uuid"'",
            "days": '"$days"'
        }')
                if [ "$(echo "${response}" | grep -ic "User not found")" != '0' ]; then
                    ShellBot.sendMessage --chat_id ${message_from_id} \
                        --text "🚫 User not found 🚫" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                    exit 0
                elif [ "$(echo "${response}" | grep -ic "Insufficient balance")" != '0' ]; then
                    ShellBot.sendMessage --chat_id ${message_from_id} \
                        --text "🚫 Insuficient Balance 🚫" \
                        --reply_markup "$keyboard1" \
                        --parse_mode html
                    exit 0
                else
                    date=$(echo "${response}" | grep -o '"new_expiration_date":"[^"]*' | grep -o '[^"]*$' | awk '{print $1}')
                    username=$(echo "${response}" | grep -o '"username":"[^"]*' | grep -o '[^"]*$')
                    uuid=$(echo "${response}" | grep -o '"uuid":"[^"]*' | grep -o '[^"]*$')
                fi

                if [ "$(grep -wc ${uuid} "$database_id")" != '0' ]; then
                    sed -i "/${uuid}/d" "$database_id"
                fi
                if [ "$(grep -wc ${uuid} "$expired_data")" != '0' ]; then
                    sed -i "/${uuid}/d" "$expired_data"
                fi
                echo "### ${username} ${date} ${uuid} ${tele_id}" >>"$database_id"
                template_file="/root/iptv-panel/renew_template.txt"
                template=$(<"$template_file")
                template=$(echo "${template}" | sed "s|\${date}|${date}|g")
                template=$(echo "${template}" | sed "s|\${username}|${username}|g")
                template=$(echo "${template}" | sed "s|\${uuid}|${uuid}|g")
                msg="$template"

                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                    --text "$msg" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
                ShellBot.sendMessage --chat_id ${tele_id} \
                    --text "$msg" \
                    --parse_mode html
            else
                ShellBot.sendMessage --chat_id ${message_from_id} \
                    --text "🚫 Dont Has Access 🚫" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
            fi
            exit 0
        }

        delete_ott() {
            if [ "${callback_query_from_id[$id]}" == "$get_AdminID" ]; then
                ShellBot.sendMessage --chat_id ${callback_query_message_chat_id[$id]} \
                    --text "Input OTT UUID :" \
                    --reply_markup "$(ShellBot.ForceReply)"
            else
                ShellBot.answerCallbackQuery --callback_query_id ${callback_query_id[$id]} \
                    --text "🚫 You're Not Admin 🚫"
            fi
            exit 0
        }

        reqdelete_ott() {
            uuid=$1
            if [ "$(grep -wc ${uuid} "$database_id")" != '0' ]; then
                username=$(grep -w "$uuid" "$database_id" | awk '{print $2}')
                date=$(grep -w "$uuid" "$database_id" | awk '{print $3}')
                uuid=$(grep -w "$uuid" "$database_id" | awk '{print $4}')
                customer_id=$(grep -w "$uuid" "$database_id" | awk '{print $5}')

                response=$(curl -s --request POST \
                    --url "$API_BASE_URL/api/delete_user" \
                    --header 'Content-Type: application/json' \
                    --data '{
            "username": "'"$username"'",
            "uuid": "'"$uuid"'",
            "admin_password": "'"$admin_password"'"
        }')
                sed -i "/${uuid}/d" "$database_id"
                msg="Successfully Delete ID\n\n"
                msg+="Username : ${username}\n"
                msg+="Expired on : ${date}\n"
                msg+="UUID : <code>${uuid}</code>\n"
                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                    --text "$msg" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
                ShellBot.sendMessage --chat_id ${customer_id} \
                    --text "$msg" \
                    --parse_mode html
            else
                ShellBot.sendMessage --chat_id ${message_from_id} \
                    --text "User Does Not Exist" \
                    --reply_markup "$keyboard1" \
                    --parse_mode html
            fi
            exit 0
        }

        alert_expired() {
            data=($(cat "$database_id" | awk '{print $2}'))
            now=$(date +"%Y-%m-%d")
            for user in "${data[@]}"; do
                exp=$(grep -w "$user" "$database_id" | awk '{print $3}' | sed -n '1p')
                d1=$(date -d "$exp" +%s)
                d2=$(date -d "$now" +%s)
                exp2=$(((d1 - d2) / 86400))
                uuid=$(grep -w "$user" "$database_id" | awk '{print $4}' | sed -n '1p')
                cust_id=$(grep -w "$user" "$database_id" | awk '{print $5}' | sed -n '1p')
                if [[ "$exp2" -gt 0 && "$exp2" -le 3 ]]; then
                    msg="<b>RENEW YOUR OTT</b>\n\n"
                    msg+="Your ID Is About To Expired In <code>$exp2</code> Day\n"
                    msg+="Username : <code>$user</code>\n"
                    msg+="UUID : <code>$uuid</code>\n"
                    msg+="Expired On : <code>$exp</code>\n\n"
                    #msg+="Please Contact <a href='tg://user?id=$get_AdminID'>Admin</a> to renew\n"
                    msg+="Please contact our reseller to renew your id, Thank You\n"
                    ShellBot.sendMessage --chat_id ${cust_id} \
                        --text "$msg" \
                        --parse_mode html
                elif [ "$exp2" -le 0 ]; then
                    user_data=$(grep -i "${uuid}" "$database_id")
                    msg="<b>RENEW YOUR OTT</b>\n\n"
                    msg+="Your ID Has Been Terminated\n"
                    msg+="Username : <code>$user</code>\n"
                    msg+="UUID : <code>$uuid</code>\n"
                    msg+="Expired On : <code>$exp</code>\n\n"
                    #msg+="Please Contact <a href='tg://user?id=$get_AdminID'>Admin</a> to renew\n"
                    msg+="Please contact our reseller to renew your id, Thank You\n"
                    sed -i "/${uuid}/d" "$database_id"
                    echo "${user_data}" >>"$expired_data"
                    ShellBot.sendMessage --chat_id ${cust_id} \
                        --text "$msg" \
                        --parse_mode html
                fi
            done
            exit 0
        }

        auto_backup() {
            [[ ! -f /usr/bin/zip ]] && {
                apt install zip -r
            }
            dateToday=$(date +"%Y-%m-%d")
            mkdir /root/backup
            cp -rf /root/ottbot /root/backup/
            cp -rf /root/iptv-panel /root/backup/
            zip -r /root/backup_$dateToday.zip /root/backup
            curl -Ss --request POST \
                --url "https://api.telegram.org/bot${get_Token}/sendDocument?chat_id=${get_AdminID}&caption=Here Your Backup Today : ${dateToday}" \
                --header 'content-type: multipart/form-data' \
                --form document=@"/root/backup_$dateToday.zip"
            rm -rf "/root/backup/"
            rm -rf "/root/backup_$dateToday.zip"
            exit 0
        }

        unset menu1
        menu1=''
        ShellBot.InlineKeyboardButton --button 'menu1' --line 1 --text '• Create ID •️' --callback_data '_addid'
        ShellBot.InlineKeyboardButton --button 'menu1' --line 1 --text '• Renew ID •️' --callback_data '_renewid'
        ShellBot.InlineKeyboardButton --button 'menu1' --line 2 --text '• Create ID [Custom] •️' --callback_data '_caddid'
        ShellBot.InlineKeyboardButton --button 'menu1' --line 2 --text '• Renew ID [Custom] •️' --callback_data '_crenewid'
        ShellBot.InlineKeyboardButton --button 'menu1' --line 3 --text '• Delete ID •️' --callback_data '_delid'
        ShellBot.InlineKeyboardButton --button 'menu1' --line 4 --text '• Reseller •️' --callback_data '_menureseller'
        ShellBot.InlineKeyboardButton --button 'menu1' --line 5 --text '• Main Menu •️' --callback_data '_menu1'
        ShellBot.regHandleFunction --function menu_create --callback_data _addid
        ShellBot.regHandleFunction --function menu_renew --callback_data _renewid
        ShellBot.regHandleFunction --function add_custom --callback_data _caddid
        ShellBot.regHandleFunction --function renew_custom --callback_data _crenewid
        ShellBot.regHandleFunction --function delete_ott --callback_data _delid
        ShellBot.regHandleFunction --function menu_reseller --callback_data _menureseller
        ShellBot.regHandleFunction --function backReq --callback_data _menu1
        unset keyboard1
        keyboard1="$(ShellBot.InlineKeyboardMarkup -b 'menu1')"

        unset menu2
        menu2=''
        ShellBot.InlineKeyboardButton --button 'menu2' --line 1 --text '• Add Reseller •️' --callback_data '_addres'
        ShellBot.InlineKeyboardButton --button 'menu2' --line 1 --text '• Delete Reseller •️' --callback_data '_delres'
        ShellBot.InlineKeyboardButton --button 'menu2' --line 2 --text '• Add Balance •️' --callback_data '_balres'
        ShellBot.InlineKeyboardButton --button 'menu2' --line 3 --text '• Main Menu •️' --callback_data '_menu2'
        ShellBot.regHandleFunction --function add_reseller --callback_data _addres
        ShellBot.regHandleFunction --function del_reseller --callback_data _delres
        ShellBot.regHandleFunction --function bal_reseller --callback_data _balres
        ShellBot.regHandleFunction --function backReq --callback_data _menu2
        unset keyboard2
        keyboard2="$(ShellBot.InlineKeyboardMarkup -b 'menu2')"

        unset menupackage
        menupackage=''
        ShellBot.InlineKeyboardButton --button 'menupackage' --line 1 --text '• Package A •️' --callback_data '_pakeja'
        ShellBot.InlineKeyboardButton --button 'menupackage' --line 1 --text '• Package B •️' --callback_data '_pakejb'
        ShellBot.InlineKeyboardButton --button 'menupackage' --line 2 --text '• Package C •️' --callback_data '_pakejc'
        ShellBot.InlineKeyboardButton --button 'menupackage' --line 2 --text '• TRIAL •️' --callback_data '_pakejtrial'
        ShellBot.InlineKeyboardButton --button 'menupackage' --line 3 --text '• Main Menu •️' --callback_data '_menupakej'
        ShellBot.regHandleFunction --function choose_package --callback_data _pakeja
        ShellBot.regHandleFunction --function choose_package --callback_data _pakejb
        ShellBot.regHandleFunction --function choose_package --callback_data _pakejc
        ShellBot.regHandleFunction --function choose_package --callback_data _pakejtrial
        ShellBot.regHandleFunction --function backReq --callback_data _menupakej
        unset keyboardpackage
        keyboardpackage="$(ShellBot.InlineKeyboardMarkup -b 'menupackage')"

        unset menurenew
        menurenew=''
        ShellBot.InlineKeyboardButton --button 'menurenew' --line 1 --text '• Package A •️' --callback_data '_renewa'
        ShellBot.InlineKeyboardButton --button 'menurenew' --line 1 --text '• Package B •️' --callback_data '_renewb'
        ShellBot.InlineKeyboardButton --button 'menurenew' --line 2 --text '• Package C •️' --callback_data '_renewc'
        ShellBot.InlineKeyboardButton --button 'menurenew' --line 3 --text '• Main Menu •️' --callback_data '_menurenew'
        ShellBot.regHandleFunction --function renew_package --callback_data _renewa
        ShellBot.regHandleFunction --function renew_package --callback_data _renewb
        ShellBot.regHandleFunction --function renew_package --callback_data _renewc
        ShellBot.regHandleFunction --function backReq --callback_data _menurenew
        unset keyboardrenew
        keyboardrenew="$(ShellBot.InlineKeyboardMarkup -b 'menurenew')"
        if [[ "$1" == "-a" || "$1" == "--allert" ]]; then
            alert_expired
            exit 0
        elif [[ "$1" == "-b" || "$1" == "--backup" ]]; then
            auto_backup
            exit 0
        else
            while :; do
                ShellBot.getUpdates --limit 100 --offset $(ShellBot.OffsetNext) --timeout 35
                for id in $(ShellBot.ListUpdates); do
                    (
                        ShellBot.watchHandle --callback_data ${callback_query_data[$id]}
                        CAD_ARQ=/tmp/cad.${message_from_id[$id]}
                        if [[ ${message_entities_type[$id]} == bot_command ]]; then
                            case ${message_text[$id]} in
                            *)
                                :
                                comando=(${message_text[$id]})
                                [[ "${comando[0]}" = "/start" ]] && msg_welcome
                                ;;
                            esac
                        fi
                        if [[ ${message_reply_to_message_message_id[$id]} ]]; then
                            case ${message_reply_to_message_text[$id]} in
                            'Input Reseller Tele ID [CREATE]:')
                                echo "${message_text[$id]}" >$CAD_ARQ
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                                    --text "Reseller Balance :" \
                                    --reply_markup "$(ShellBot.ForceReply)"
                                ;;
                            'Input Reseller Tele ID [DELETE]:')
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                req_delres "${message_text[$id]}"
                                ;;
                            'Input Reseller Tele ID [BALANCE]:')
                                echo "${message_text[$id]}" >$CAD_ARQ
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                                    --text "Topup Balance :" \
                                    --reply_markup "$(ShellBot.ForceReply)"
                                ;;
                            'Topup Balance :')
                                echo "${message_text[$id]}" >>$CAD_ARQ
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                reseller_id=$(sed -n '1p' $CAD_ARQ | awk '{print $1}')
                                amount=$(sed -n '2p' $CAD_ARQ | awk '{print $1}')
                                add_balreq "$reseller_id" "$amount"
                                ;;
                            'Reseller Balance :')
                                echo "${message_text[$id]}" >>$CAD_ARQ
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                reseller_id=$(sed -n '1p' $CAD_ARQ | awk '{print $1}')
                                reseller_bal=$(sed -n '2p' $CAD_ARQ | awk '{print $1}')
                                create_reseller "${reseller_id}" "${reseller_bal}"
                                ;;
                            'Input Username :')
                                echo "${message_text[$id]}" >>$CAD_ARQ
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                                    --text "Customer Tele ID :" \
                                    --reply_markup "$(ShellBot.ForceReply)"

                                ;;
                            'Input UUID :')
                                echo "${message_text[$id]}" >>$CAD_ARQ
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                package=$(sed -n '1p' $CAD_ARQ | awk '{print $1}')
                                uuid=$(sed -n '2p' $CAD_ARQ | awk '{print $1}')
                                if [ "$(grep -wc "${uuid}" "$database_id")" != '0' ]; then
                                    username=$(grep -w "${uuid}" "$database_id" | awk '{print $2}')
                                    tele_id=$(grep -w "${uuid}" "$database_id" | awk '{print $5}')
                                    exist="1"
                                    renew_ott "${package}" "${username}" "${tele_id}" "${exist}" "${uuid}"
                                elif [ "$(grep -wc "${uuid}" "$expired_data")" != '0' ]; then
                                    username=$(grep -w "${uuid}" "$expired_data" | awk '{print $2}')
                                    tele_id=$(grep -w "${uuid}" "$expired_data" | awk '{print $5}')
                                    exist="1"
                                    renew_ott "${package}" "${username}" "${tele_id}" "${exist}" "${uuid}"
                                else
                                    ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                                        --text "User Does Not Exist" \
                                        --parse_mode html
                                    exit 0
                                fi
                                ;;
                            'Customer Tele ID :')
                                echo "${message_text[$id]}" >>$CAD_ARQ
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                package=$(sed -n '1p' $CAD_ARQ | awk '{print $1}')
                                username=$(sed -n '2p' $CAD_ARQ | awk '{print $1}')
                                tele_id=$(sed -n '3p' $CAD_ARQ | awk '{print $1}')
                                exist="0"
                                create_ott "${package}" "${username}" "${tele_id}" "${exist}"
                                ;;
                            'Input OTT UUID :')
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                reqdelete_ott "${message_text[$id]}"
                                ;;
                            'Input Username [Custom]:')
                                echo "${message_text[$id]}" >$CAD_ARQ
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                                    --text "Input Days [Add]:" \
                                    --reply_markup "$(ShellBot.ForceReply)"
                                ;;
                            'Input UUID [Custom]:')
                                echo "${message_text[$id]}" >$CAD_ARQ
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                                    --text "Input Days [Renew]:" \
                                    --reply_markup "$(ShellBot.ForceReply)"
                                ;;
                            'Input Days [Add]:')
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                echo "${message_text[$id]}" >>$CAD_ARQ
                                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                                    --text "Customer Tele ID [Add]:" \
                                    --reply_markup "$(ShellBot.ForceReply)"
                                ;;
                            'Customer Tele ID [Add]:')
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                echo "${message_text[$id]}" >>$CAD_ARQ
                                req_add_custom $CAD_ARQ
                                ;;
                            'Input Days [Renew]:')
                                ShellBot.deleteMessage --chat_id ${message_reply_to_message_chat_id[$id]} \
                                    --message_id ${message_reply_to_message_message_id[$id]}
                                echo "${message_text[$id]}" >>$CAD_ARQ
                                uuid=$(sed -n '1p' $CAD_ARQ | awk '{print $1}')
                                if [ "$(grep -wc "${uuid}" "$database_id")" != '0' ]; then
                                    uuid=$(sed -n '1p' "${CAD_ARQ}" | awk '{print $1}')
                                    days=$(sed -n '2p' "${CAD_ARQ}" | awk '{print $1}')
                                    tele_id=$(grep -w "${uuid}" "$database_id" | awk '{print $5}')
                                    req_renew_custom "$uuid" "$days" "$tele_id"
                                elif [ "$(grep -wc "${uuid}" "$expired_data")" != '0' ]; then
                                    uuid=$(sed -n '1p' "${CAD_ARQ}" | awk '{print $1}')
                                    days=$(sed -n '2p' "${CAD_ARQ}" | awk '{print $1}')
                                    tele_id=$(grep -w "${uuid}" "$expired_data" | awk '{print $5}')
                                    req_renew_custom "$uuid" "$days" "$tele_id"
                                else
                                    ShellBot.sendMessage --chat_id ${message_chat_id[$id]} \
                                        --text "User Does Not Exist" \
                                        --parse_mode html
                                    exit 0
                                fi
                                ;;
                            esac
                        fi
                    ) &
                done
            done
        fi

    else
        rm -rf "/root/ottbot"
        crontab -l | grep -v 'start_bot.sh' | crontab -
    fi
fi