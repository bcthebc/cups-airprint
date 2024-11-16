# base image
FROM ubuntu:jammy

# Avoid timezone and other questions from packages
ARG DEBIAN_FRONTEND=noninteractive

# label the built image with HEAD commit if given
ARG GIT_COMMIT=unspecified
LABEL git_commit=$GIT_COMMIT

# Install the packages we need. Avahi will be included
RUN apt-get update && apt-get install -y \
	# Avahi
	avahi-daemon \
	avahi-utils \
	# CUPS packages
	cups \
	cups-pdf \
  	cups-bsd \
  	cups-filters \
	inotify-tools \
	python3-cups \
	cups-backend-bjnp \
	# printer-specific packages and other helpful things
	foomatic-db-compressed-ppds \
	printer-driver-all \
	openprinting-ppds \
	hpijs-ppds \
	hp-ppd \
	hplip \
	printer-driver-brlaser \
	docx2txt \
# Clean up the package list to save space
&& rm -rf /var/lib/apt/lists/*

# This will use port 631
EXPOSE 631

# We want a mount for these
VOLUME /config
VOLUME /services

# Add drivers to image /lib directory
ADD printerdrivers /lib/
RUN chmod +x /lib/printerdrivers/*

# Install libgtk-3-0 (needed by the Canon driver) and associated dependencies
RUN apt-get update && apt-get install -y \
	libgtk-3-0 \
	libjpeg62 \
	lsb-release \
&& apt-get -y -f install

# Install Canon driver from /lib/printerdrivers directory (ensure the architecture matches the system, ie amd64, and
# the file name matches the one in the root directory of this repo)
RUN dpkg -i /lib/printerdrivers/cnrdrvcups-ufr2-us_6.00-1.02_amd64.deb

# Add scripts for cups and the airprint generate routine and set run_cups.sh to start when the container runs
ADD root /
RUN chmod +x /root/*
CMD ["/root/run_cups.sh"]

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf


