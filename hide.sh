hide_desktop_files() {
    local APPLICATION_PATH="/usr/share/applications"
    local FIRST_USER_HOME=$(ls -d /home/* | head -n 1)
    local USER_APPLICATION_PATH="${FIRST_USER_HOME}/.local/share/applications"
    local files=("$@")

    # Ensure USER_APPLICATION_PATH exists
    mkdir -p "${USER_APPLICATION_PATH}"

    for FILE in "${files[@]}"; do
        if [ -e "${APPLICATION_PATH}/${FILE}" ]; then
            if [ ! -e "${USER_APPLICATION_PATH}/${FILE}" ]; then
                echo "Creating file ${USER_APPLICATION_PATH}/${FILE}"
                echo "NoDisplay=true" > "${USER_APPLICATION_PATH}/${FILE}"
            fi
        elif [ -e "${USER_APPLICATION_PATH}/${FILE}" ]; then
            echo "Deleting unnecessary file ${USER_APPLICATION_PATH}/${FILE}"
            rm "${USER_APPLICATION_PATH}/${FILE}"
        fi
    done

    # Change ownership after the loop
    chown -R $(basename ${FIRST_USER_HOME}):$(basename ${FIRST_USER_HOME}) "${USER_APPLICATION_PATH}"
}

# List of files to process
files=(
    "avahi-discover.desktop" \
    "bssh.desktop" \
    "bvnc.desktop" \
    "qv4l2.desktop" \
    "qvidcap.desktop"
)

# Call the function with the list of files
log "Hide those pesky little shits"
hide_desktop_files "${files[@]}"
