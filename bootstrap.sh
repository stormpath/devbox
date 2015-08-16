#!/bin/bash

DELAY=5
XCODE_POLL_DELAY=10
XCODE_TIMEOUT=60
XCODE_RETRIES=0
XCODE_STATUS=""
######## END OF CONFIG ITEMS

# Check for root privs
if [ "$UID" -eq 0 ]
  	then echo "FATAL: Please do not run as root. We will automatically call sudo where needed."
	exit
else
  	echo "Checking UID... good"
fi

echo "Starting install... CTRL+C now to abort. Sleeping $DELAY seconds."
sleep $DELAY

# Get down to business
XCODE_STATUS=`pkgutil --pkg-info=com.apple.pkg.CLTools_Executables | grep "install-time"`
if [ -z "$XCODE_STATUS" ]; then
  echo "Triggering Xcode install. Follow pop-up screen directions _you must click Install_ ..."
  xcode-select --install
  
  while :
  do
  	XCODE_STATUS=`pkgutil --pkg-info=com.apple.pkg.CLTools_Executables | grep "install-time"`
  	XCODE_RETRIES=$(( $XCODE_RETRIES + 1 ))

  	if [ $XCODE_RETRIES -ge $XCODE_TIMEOUT ]; then 
      echo "Retry timeout $timeout reached while waiting for XCODE to become available" 
      break 
    fi
    
    if [[ "$XCODE_STATUS" =~ ^install-time ]]; then 
      echo "Xcode is available! Proceeding with install."
      break
    fi
    	
  	echo "Waiting for your Xcode installation to complete...  (retry $XCODE_RETRIES/$XCODE_TIMEOUT)"
    sleep $XCODE_POLL_DELAY
  done
else
  echo "XCode already installed.  Proceeding with install."
fi

echo "Fixing PATH in .bash_profile to properly pick up Xcode and macports... your sudo password will be required."
echo "export PATH=$PATH:/opt/local/bin:/Library/Developer/CommandLineTools/usr/bin" >> ~/.bash_profile
sudo echo "export PATH=$PATH:/opt/local/bin:/Library/Developer/CommandLineTools/usr/bin" >> ~/.bash_profile
source ~/.bash_profile

echo "Starting ruby install... your sudo password will be required."
sudo curl -L https://get.rvm.io | bash -s stable --ruby

echo "Importing rvm variables into this session..."
source "$HOME/.rvm/scripts/rvm"

echo "Installing homebrew..."
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

##homebrew says: sudo mv /opt/local ~/macports  #…..skipped.
echo "Starting install of GIT via brew..."
brew install git

echo "Creating /vagrant directories with the proper permissions..."
sudo mkdir /vagrant && sudo chown $USER /vagrant

echo "Cloning the docker GIT repo from BitBucker..."
git clone git@bitbucket.org:stormpath/docker.git /vagrant

echo "About to run Docker setup script..."
/vagrant/SETUP.sh
