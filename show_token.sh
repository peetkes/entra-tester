#!/bin/bash

./decode-jwt.sh "$(./gen_token.sh $1)"