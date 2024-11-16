# Project Journal
## Vision
The goal of this project was to create an Airplay relay for an older Canon MF4800dw laser printer (which is not natively Airprint capable).

I have a small Ubuntu server on my home network which is on the same subnet as the printer. The idea is to create a Docker container running on this machine which will advertise the Airprint service and send print jobs to the printer. 

The learning goal of this project is to become more familiar with various Docker commands and implementations, as well as general Linux CLI concepts. Exposure to some printer-related and network-related concepts is a side benefit. An un-anticipated benefit was also learning much more about Git and Microsoft VS Code.

## Docker Image #1: cups-avahi-airprint
The original thought was to simply clone a repo from Github, tweak a few things, and then launch the container and... profit!

 A search of Github turned up some promising ideas... 

I started here:
https://github.com/chuckcharlie/cups-avahi-airprint

This is a repo running Alpine Linux with CUPS and a Python script that publishes the CUPS printers as Airprint devices. I tried to get it running, but although I was able to get the CUPS server up, I could not add the printer due to a lack of a ppd file. 

So, I went to the Canon website and found a driver download for this machine for Linux. After poking around the package, I found a ppd file I thought might work, but while it let me make the printer (and see it on Airprint!) it would not print ("broken pipe" error).

Thinking that a different distro might have drivers for the printer, I turned to a different image. 

## Docker Image #2: cups-airprint

https://github.com/RagingTiger/cups-airprint

This is a predecessor of the first image, built on Ubuntu Xenial. I got a basic container running but still could not install the printer (no drivers). So, I actually *read* the documentation provided by Canon and found directions on how to install the driver .deb package from the CLI. 

First, I edited the project to create a new directory ("printerdrivers") and edited the Dockerfile to copy this directory into the new container.

I then entered the running container with Docker Exec: ```docker exec -it cups sh```

Then I tried running the installer... but it failed due to dependency problems. Then, after a lot of fun with apt and apt-get, I was able get the installer to run.

Next, I spent a few hours (!) figuring out how to incorporate all this into the Dockerfile with ```RUN``` commands and the ```-y``` flag, like this: ```apt-get -y install packagename```

Finally got it all running, but alas... while I could now add the printer to CUPS, I could not see it on Airprint. Then it dawned on me... when I was checking the logs earlier (inside the running container), I noticed that there were some fatal errors with Avahi. Well, I remembered that Avahi is basically the Bonjour service that advertises things on the network, and I realized that maybe this is the reason this image was depreciated. Old Avahi on old Ubuntu distro? So... now back to the first Alpine image, but this time with the knowledge of how to install the drivers and add the Canon printer to CUPS. 

## Docker Image #3: back to the first one
