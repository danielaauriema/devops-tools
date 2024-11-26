#!/bin/bash
docker system prune -f && docker build -t ldapz . && docker run -it ldapz
