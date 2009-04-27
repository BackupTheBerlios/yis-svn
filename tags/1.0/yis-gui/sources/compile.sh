#!/bin/bash

rm -f InstallerUI.py *.pyc

make

for file in `ls -1 *.py` ; do
	python $file ;
done

