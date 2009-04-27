#The Media Python file
#Deals with the Media Screen
#It takes the QWizard object (qwizard) from YoperInstaller as the object in the 
#constructor, which allows us to access our Installer GUI.
#Modifications can be done here pertaining to Media screen only

#Author - Chaks
#email  - chaks.yoper@gmail.com

from qt import *
from threading import *
from path import path
import os
import popen2

class CheckMedia(Thread):
	def __init__(self,name,receiver,yiswiz):
		self.name=name
		self.receiver=receiver
		self.yiswiz=yiswiz
		apply(Thread.__init__, (self, ))
	
	def run(self):
		self.yiswiz.setNextEnabled(self.yiswiz.page(2),0)
		proc_media_check=popen2.Popen3("/var/yis/common/checkmd5sum.sh",True)
		while proc_media_check.poll()==-1:
			pass

		err=proc_media_check.childerr.read()
		print err
		self.yiswiz.app_object.processEvents()
		if err:
			self.yiswiz.lblProgressMedia.setText("You do not have a proper Yoper CD!")
			self.yiswiz.app_object.processEvents()	
			popen2.Popen3("/usr/bin/kdialog --msgbox 'You do not have a proper Yoper CD,System is going for Reboot'")
			popen2.Popen3("/sbin/init 6")
			self.yiswiz.setNextEnabled(self.yiswiz.page(2),0)		
		else:
			self.yiswiz.lblProgressMedia.setText("You have a proper Yoper CD, Enjoy Yoper Installation!")
			self.yiswiz.app_object.processEvents()	
			self.yiswiz.setNextEnabled(self.yiswiz.page(2),1)		
class Media:
	def __init__(self,qwizard):
		self.yiswiz=qwizard
		self.setDefaultValues()
		self.connectSignals()
		
	def setDefaultValues(self):
		self.yiswiz.setNextEnabled(self.yiswiz.page(2),1)

	def connectSignals(self):
		self.yiswiz.connect(self.yiswiz.btnVerifyCd,SIGNAL("clicked()"),self.onVerifyCD)
	
	def onVerifyCD(self):
		self.yiswiz.lblProgressMedia.setText("Checking Media, Please wait")
		self.yiswiz.btnVerifyCd.setEnabled(0)
		self.threadCheck=CheckMedia("Check Media",self,self.yiswiz)
		self.threadCheck.start()
	
	def __del__(self):
		if not self.threadCheck.finished():
			self.threadCheck.wait()
