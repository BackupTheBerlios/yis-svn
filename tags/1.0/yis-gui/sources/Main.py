#The Main python file
#This file is the Main - Father for our Installer Program
#This creates the main QApllication Object and attaches to our YoperInstaller
#and sets that as our main widget.

#Author - Chaks
#Email  - chaks.yoper@gmail.com

from qt import *
from YoperInstaller import *
import sys

def main(args):
	app=QApplication(args)
	win=YoperInstaller(app)
	app.setMainWidget(win)
	win.show()
	app.exec_loop()
	
if __name__ == "__main__":
	main(sys.argv)