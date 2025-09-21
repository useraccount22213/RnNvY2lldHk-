#!/bin/bash

# Check if correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <IP Address> <Port> <client.cpp file>"
    exit 1
fi

# Assign arguments to variables
IP_ADDRESS=$1
PORT=$2
CLIENT_CPP_FILE=$3

# Verify if the provided client.cpp file exists
if [ ! -f "$CLIENT_CPP_FILE" ]; then
    echo "Error: $CLIENT_CPP_FILE not found!"
    exit 1
fi

# Generate a random string for the output filename
OUTPUT_FILENAME=$(cat /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c 8)

# Create a backup of the original client.cpp
cp "$CLIENT_CPP_FILE" "${CLIENT_CPP_FILE}.bak"

# Replace IP address and port in client.cpp
sed -i "s|const char\* server_address = .*$|const char\* server_address = \"$IP_ADDRESS\";|" "$CLIENT_CPP_FILE"
sed -i "s|int port = .*$|int port = $PORT;|" "$CLIENT_CPP_FILE"

# Compile the modified client.cpp using g++
g++ "$CLIENT_CPP_FILE" -o "$OUTPUT_FILENAME" -lssl -lcrypto

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo "Compilation successful! Output file: $OUTPUT_FILENAME"
else
    echo "Compilation failed!"
    exit 1
fi

# Optionally, restore the original client.cpp
# mv "${CLIENT_CPP_FILE}.bak" "$CLIENT_CPP_FILE"

exit 0
