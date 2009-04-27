#The Installing Python file
#Here we talk only about the Installing Screen in our Yoper Installer
#It takes the QWizard object (qwizard) from YoperInstaller as the object in the 
#constructor, which allows us to access our Installer GUI.
#Now modifications can be done here pertaining to Installing screen only

#Author - Chaks
#Email  - chaks.yoper@gmail.com

from qt import *

class Installing:
	def __init__(self,qwizard):
		self.yiswiz=qwizard
		self.setDefaultValues()

	def setDefaultValues(self):
		self.yiswiz.setNextEnabled(self.yiswiz.page(6),1)
