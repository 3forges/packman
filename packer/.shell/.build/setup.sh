export LX_USERNAME=vagrant
mkdir -p /home/${LX_USERNAME}/.ssh/
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDNtNaldkySfaVvagKQv0g24/j1gADb7qM4gFqXdayzyKVsUrVItVOvXpvfzuquv0FwnIMCU2TCKjQZ86ghUBmeBfDQwTGmtXtyQbHbRo1B6b4gJJGudndr3zQKWsuKYbcqRelNB4g9EGyLwrZL6DVdHh81uF1ncVfgE2mQ5yR2tF8kQT+ZodFByUtIjIwj9qpspp30ghhbzIM07p//5T3yqjL09OeIkJ5pjRsFQdv/rpleNFxIqM1w23KpGMNiIAQz/MzgBRU/Lbvgy77RUPVpe0GMYTz/Atua7XVaANI46ONEdpSFZ7ZR0Fz9zZgnoxR4Oagz9hYkKToZfdoPv8Bfc2jGH/YtwHA3ooIbJF8nqbSPJjipwe/8tQs0gtrGdjRv2se83j1K2Le7w7ELqjN1b/nPHNKeEiOv2NuXVZ0+kQsWVAt002PD+Me4PDiO5vd1t/mGpluNzZsZDh0eeLQ+apFKpxYIB9uojtsZkBpEj2NB/7CTu9YBIISnNXDmtfZvQ3bMj5hLOeKxWwqwf1GY7JQSIiJi7G/QG85eLes/+X4PJmo38GPQ2SZ0egdV3QDbBUGa+r7NOkZDf43IjZYa9Hqw93qC5//eYXsfH3loDbMsGGlZ4MoVmesp1qjxPjAyBrG0CfhnFBdnvotL4z4l+QDXhboZ74xJLUNemtTYpQ== ' | sudo tee -a /home/${LX_USERNAME}/.ssh/authorized_keys
chmod 700 -R /home/${LX_USERNAME}/.ssh/
chmod 644 -R /home/${LX_USERNAME}/.ssh/authorized_keys
sudo apt-get install -y curl wget gettext jq