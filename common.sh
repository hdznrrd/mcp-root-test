#!/bin/bash

function delay () {
  read -n 1 -s
}

function result () {
  res=$?
  if test "$res" != "0"; then
	echo -e "\e[31m"
  else
	echo -e "\e[32m"
  fi
  echo -e "\n result: $res\n\n\u001b[0m"
}

function step () {
  echo "$@"
  delay
}

rm -f *pem *sha384



