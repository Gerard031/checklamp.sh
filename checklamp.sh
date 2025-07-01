#!/bin/bash

# Function to check if a service is running
check_service() {
    service_name=$1
    if systemctl is-active --quiet "$service_name"; then
        echo "$service_name is running."
    else
        echo "$service_name is not running."
        exit 1
    fi
}

# Check Apache
check_apache() {
    echo "Checking Apache..."

    # Try detecting the correct Apache service name
    if systemctl list-units --type=service | grep -q apache2; then
        APACHE_SERVICE="apache2"
    elif systemctl list-units --type=service | grep -q httpd; then
        APACHE_SERVICE="httpd"
    else
        echo "Apache service not found. Is it installed?"
        exit 1
    fi

    # Check if the Apache service is active
    if systemctl is-active --quiet "$APACHE_SERVICE"; then
        echo "Apache service ($APACHE_SERVICE) is running."
    else
        echo "Apache service ($APACHE_SERVICE) is not running. Attempting to start..."
        sudo systemctl start "$APACHE_SERVICE"
        if systemctl is-active --quiet "$APACHE_SERVICE"; then
            echo "Apache started successfully."
        else
            echo "Failed to start Apache service ($APACHE_SERVICE)."
            exit 1
        fi
}

# Check MySQL
check_mysql() {
    echo "Checking MySQL..."
    check_service "mysql"
    
    # Check MySQL connection
    if mysql -uroot -e "STATUS;" > /dev/null 2>&1; then
        echo "MySQL connection successful."
    else
        echo "MySQL connection failed."
        exit 1
    fi
}

# Check PHP
check_php() {
    echo "Checking PHP..."
    php_version=$(php -v | grep "^PHP" | awk '{print $2}')
    if [ -n "$php_version" ]; then
        echo "PHP is installed. Version: $php_version"
        
        # Check PHP integration with Apache
        echo "<?php phpinfo(); ?>" > /var/www/html/info.php
        response=$(curl -s http://localhost/info.php | grep -i "php version")
        if [[ "$response" == *"PHP Version"* ]]; then
            echo "PHP is working with Apache."
        else
            echo "PHP is not working with Apache."
            exit 1
        fi
        rm /var/www/html/info.php
    else
        echo "PHP is not installed."
        exit 1
    fi
}

# Main function to run all checks
main() {
    echo "Starting LAMP stack check..."
    check_apache
    check_mysql
    check_php
    echo "LAMP stack is properly configured and functional."
}

# Run the main function
main
