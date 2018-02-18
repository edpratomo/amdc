#!/bin/bash

ruby -rjson -rpp -e'puts JSON.pretty_generate(JSON.parse(STDIN.read))'
