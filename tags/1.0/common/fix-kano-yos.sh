#! /bin/bash

rm -rf /var/*
cp -a /KNOPPIX/var/* /var
cp -a /KNOPPIX/yis /var

rm -rf /root/.kde
ln -s /var/yis/yis-gui/.kde /root/.kde
ln -sf /root/.kde/yoperwall2.2.png /root/yoperv2.jpg

