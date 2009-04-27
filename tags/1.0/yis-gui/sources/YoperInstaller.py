#The YoperInstaller python file
#Main file for the Installer, which initialises all other modules

#Author - Chaks
#email  - chaks.yoper@gmail.com

from qt import *
from InstallerUI import *
from Disclaimer import *
from Media import *
from PartitionSetup import *
from Bootloader import *
from FinalScreen import *
import os

class YoperInstaller (YIS):
	def __init__(self,app):
		YIS.__init__(self)
		
		self.app_object=app
		
		#Disclaimer Screen
		self.disclaimer_screen=Disclaimer(self)
		
		#Check your Media Screen
		self.media_screen=Media(self)
		
		#Partition Setup
		self.partition_setup=PartitionSetup(self)
		
		#Bootloader Screen
		self.bootloader_screen=Bootloader(self)
		
		#Final Screen
		self.final_screen=FinalScreen(self)
	
	def reject(self):
		result=QMessageBox.question(self, "YIS","Cancel Installation ?",QMessageBox.Yes,QMessageBox.No)
		if result==QMessageBox.Yes:
			self.done(0)
			os.popen("/sbin/init 6")
	
	#def next(self):
		#result=QMessageBox.question(self, "YIS","Cancel Installation ?",QMessageBox.Yes,QMessageBox.No)
		#if result==QMessageBox.Yes:
			#page3=self.page(3)
			#self.showPage(page3)		