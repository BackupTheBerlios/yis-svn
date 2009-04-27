#The Disclaimer Python file
#Deals with the Disclaimer Screen
#It takes the QWizard object (qwizard) from YoperInstaller as the object in the 
#constructor, which allows us to access our Installer GUI.
#Modifications can be done here pertaining to Disclaimer screen only

#Author - Chaks
#email  - chaks.yoper@gmail.com

from qt import *

class Disclaimer:
	def __init__(self,qwizard):
		self.yiswiz=qwizard
		self.setDefaultValues()
		self.connectSignals()

	def setDefaultValues(self):
		self.yiswiz.setNextEnabled(self.yiswiz.page(1),0)

	def connectSignals(self):
		self.yiswiz.connect(self.yiswiz.chkAgree,SIGNAL("clicked()"),self.onAgree)

	def onAgree(self):
		if self.yiswiz.chkAgree.isChecked() == True:
			self.yiswiz.setNextEnabled(self.yiswiz.page(1),1)
		else:
			self.yiswiz.setNextEnabled(self.yiswiz.page(1),0)