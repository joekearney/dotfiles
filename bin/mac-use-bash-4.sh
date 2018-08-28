#!/usr/local/bin/bash

echo /usr/local/bin/bash | sudo tee -a /etc/shells
chsh -s /usr/local/bin/bash
sudo chsh -s /usr/local/bin/bash
