#!/bin/bash

figlet 'Spinup Troubleshooter'

source ./.troubleshooter.env.sh
docker-compose -f ./.troubleshooter.yml build
docker-compose -f ./.troubleshooter.yml up -d

