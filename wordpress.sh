#!/bin/bash

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Task 1: Check and install Docker and Docker Compose if not present
if ! command_exists docker || ! command_exists docker-compose; then
    echo "Installing Docker and Docker Compose..."
    if ! command_exists docker; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        echo "Docker installed successfully!"
    fi
    if ! command_exists docker-compose; then
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose installed successfully!"
    fi
fi

# Task 2: Create a WordPress site using the latest version
if [ $# -eq 0 ]; then
    echo "Please provide a site name as a command-line argument."
    exit 1
fi

site_name=$1
echo "Creating WordPress site: $site_name"
mkdir "$site_name"
cd "$site_name"
cat <<EOF >docker-compose.yml
version: '3'
services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: somewordpress
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress

  wordpress:
    depends_on:
      - db
    image: wordpress
    ports:
      - "8000:80"
    volumes:
      - ./wp-content:/var/www/html/wp-content
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
volumes:
  db_data:

EOF

docker-compose up -d

# Task 3: Add /etc/hosts entry for example.com
sudo sed -i '/example.com/d' /etc/hosts
echo "127.0.0.1 example.com" | sudo tee -a /etc/hosts >/dev/null

# Task 4: Prompt the user to open example.com in a browser
echo "WordPress site created successfully!"
echo "You can now open http://example.com in your browser."

# Task 5: Enable/disable the site (stop/start containers)
if [ "$2" = "disable" ]; then
    echo "Disabling the site..."
    docker-compose stop
    echo "The site has been disabled."
elif [ "$2" = "enable" ]; then
    echo "Enabling the site..."
    docker-compose start
    echo "The site has been enabled."
fi

# Task 6: Delete the site (delete containers and local files)
if [ "$2" = "delete" ]; then
    echo "Deleting the site..."
    docker-compose down
    cd ..
    rm -rf "$site_name"
    echo "The site has been deleted."
fi
