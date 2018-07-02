# VladimirDe_infra
VladimirDe Infra repository

#Homework 3
ssh -At -i appuser <username>@<bastion ip> ssh <username>@<ip of server behind bastion>
for example:
ssh -At -i appuser appuser@35.197.233.194 ssh appuser@10.132.0.2

for command like ssh someinternalhost need to define alias in file .bashrc (unix):
alias someinternalhost='-At -i appuser appuser@35.197.233.194 ssh appuser@10.132.0.2'

Data for VPN:
bastion_IP = 35.197.233.194 
someinternalhost_IP = 10.132.0.2
