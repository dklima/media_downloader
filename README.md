# Media Downloader with RabbitMQ
A Ruby application to download videos and audio using RabbitMQ message queues. This project demonstrates how to use the Bunny gem to interact with RabbitMQ while applying Object-Oriented Programming concepts and composition over inheritance.

## Motivation
This project was created to provide a fun and practical way to learn RabbitMQ using the Bunny gem in Ruby. It also serves as a playground for applying Object-Oriented Programming concepts, emphasizing composition over inheritance.

By building a useful application that downloads media from video sites, it combines learning with practical utility.

## Demo
![Media Downloader Demo GIF](.img/media_downloader_demo.gif "Optional title")

## Prerequisites
- Ruby 3.x
- Docker (for RabbitMQ if you don't have an instance)
- **ffmpeg** -> on the computer that will run the _receiver.rb_ file
- **yt-dlp** -> on the computer that will run the _receiver.rb_ file

## Setup
### 1. Set up RabbitMQ container (First Step)
Before configuring the application, you need to set up RabbitMQ:
1. Make sure the _rabbitmq.conf_ file is in the _conf/_ directory
2. Build the RabbitMQ Docker image:
``` bash
bash bin/rabbitmq_start.sh
```
3. Get the admin password from _secrets/admin_password_ file, you will need it to fill the _config.yml_

### 2. Clone the repository
``` bash
git clone https://github.com/dklima/media_downloader
cd media_downloader
```

### 3. Install dependencies
``` bash
bundle install
```

### 4. Configure the application
Create the configuration file based on the provided sample: _config.yml.sample_
``` bash
cp config.yml.sample config.yml
```
Edit the _config.yml_ file to match your environment:
- Update RabbitMQ connection details with the _hostname_, _port_, and _credentials_ (using the password you retrieved from the _secrets/admin_password_ file)
- Make sure the virtual host is correct (usually ) `/`
- Specify download paths as required

Your _config.yml_ should look something like this:
``` yaml
# RabbitMQ Configuration
- rabbitmq:
    hostname: localhost  
    port: 5672           
    vhost: /             
    username: admin      
    password: something
    queue: download_queue  

# Downloader Configuration
- downloader:
    path: ./medias
```

## Usage
### Sending a download request
Use the _send.rb_ script to submit a URL with media for downloading:
``` bash
# Basic usage
ruby send.rb -u https://youtube.com/watch?v=example

# Download audio only
ruby send.rb -u https://youtube.com/watch?v=example -a

# Specify output filename
ruby send.rb -u https://youtube.com/watch?v=example -n "my_video"

# Keep original files
ruby send.rb -u https://youtube.com/watch?v=example -k
```
You can also run the _send.rb_ script without arguments and you'll be prompted for the URL:
``` bash
ruby send.rb
```

### Starting the consumer/worker
To start processing the download queue, run the _receiverrb_ script:
``` bash
ruby receive.rb
```
The consumer will listen for messages in the download queue and process them as they arrive.

## Project Structure
- `_bin/` Binary executables
- `lib/` Core application code
- `conf/` Configuration files for RabbitMQ
- `medias/` Default directory for downloaded files
- `send.rb` Script to publish download requests
- `receive.rb` Script to consume and process download requests

## License
MIT License
Copyright (c) 2025
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
