#The Bootloader Python file
#Here we talk only about the Bootloader Screen in our Yoper Installer
#It takes the QWizard object (qwizard) from YoperInstaller as the object in the 
#constructor, which allows us to access our Installer GUI.
#Now modifications can be done here pertaining to Bootloader screen only

#Author - Chaks
#Email  - chaks.yoper@gmail.com

from qt import *
from time import *
from Devices import *
from Md5Crypt import *

class Bootloader:
	def __init__(self,qwizard):
		self.yiswiz=qwizard
		self.setDefaultValues()
		self.connectSignals()
		self.yiswiz.dont_config_bootloader=0

	def setDefaultValues(self):
		self.yiswiz.setNextEnabled(self.yiswiz.page(4),0)
		self.fillDevicesList()
		self.fillOsList()
		
	def connectSignals(self):
		self.yiswiz.connect(self.yiswiz.cmbDevices,SIGNAL("activated(int)"),self.onDeviceSelect)
		self.yiswiz.connect(self.yiswiz.cmbChooseOS,SIGNAL("activated(int)"),self.onOsSelect)
		self.yiswiz.connect(self.yiswiz.radioBootCusLater,SIGNAL("clicked()"),self.onCustomizeLater)
		self.yiswiz.connect(self.yiswiz.radioBootCusNow,SIGNAL("clicked()"),self.onCustomizeNow)	
		self.yiswiz.connect(self.yiswiz.btnConfigBootloader,SIGNAL("clicked()"),self.onConfigBootloader)
		self.yiswiz.connect(self.yiswiz.btnAddRoot,SIGNAL("clicked()"),self.onAddRoot)
		self.yiswiz.connect(self.yiswiz.leditRootCPwd,SIGNAL("textChanged(const QString &)"),self.onCPwdChanged)
	
	def fillDevicesList(self):
		disk_info=Devices()
		disk_devices=disk_info.invokeDevices("DISK-NAMES")
		for diskname in disk_devices:
			self.yiswiz.cmbDevices.insertItem(diskname)
	
	def fillOsList(self):
		self.yiswiz.cmbChooseOS.insertItem("Select Your OS")
		self.yiswiz.cmbChooseOS.insertItem("Yoper")
		windows=self.findWindows()
		if self.boot_flag==1:
			self.yiswiz.cmbChooseOS.insertItem("Windows")
			self.win_device=windows[0:3]
			self.win_number=int(windows[3:])
			self.win_number=self.win_number-1
			#print self.win_device
			#print self.win_number
		self.yiswiz.cmbChooseOS.setCurrentItem(0)
		
	def findWindows(self):
		win_disks=[]
		self.regDevs =re.compile(r'/dev/(\w{3,3})(\d)\s*(\*?)\s*\d*\s*\d*\s*(\d*\+?)\s*\d?\d?\w?\w?\s*(.*)')
		fdisk = '/sbin/fdisk'
		fdiskOutput = os.popen(fdisk + ' -l')
		self.boot_flag=0
		for line in fdiskOutput:
    			theseMatches = self.regDevs.findall(line)
    			if(len(theseMatches)>0):
        			thisMatch = theseMatches[0]
				if thisMatch[2]=="*":
					self.fileType=QString(thisMatch[4])
					if self.fileType.find("NTFS")!=-1 or self.fileType.find("FAT")!=-1:
						self.boot_flag=1
						return thisMatch[0]+thisMatch[1]
	
	def onOsSelect(self):
		self.yiswiz.btnConfigBootloader.setEnabled(1)
	
	def onCPwdChanged(self):
		self.yiswiz.btnAddRoot.setEnabled(1)
		
	def onAddRoot(self):
		root_pwd=str(self.yiswiz.leditRootPwd.text())
		root_cpwd=str(self.yiswiz.leditRootCPwd.text())
		root_pwd_len=len(root_pwd)
		root_cpwd_len=len(root_cpwd)
		
		#check for min 6 characters
		if root_pwd_len==root_cpwd_len:
			if root_pwd_len >= 6 and root_cpwd_len >= 6:
				if root_pwd==root_cpwd:
					md5_pwd=Md5Crypt()
					md5_pwd.md5CryptRoot(root_pwd)
					self.yiswiz.setNextEnabled(self.yiswiz.page(4),1)
				else:
					QMessageBox.critical(self.yiswiz, "Yoper Configuration","Root passwords should match.Please retype",QMessageBox.Ok)
			else:
				QMessageBox.critical(self.yiswiz, "Yoper Configuration","Root password should be atleast 6 characters",QMessageBox.Ok)
		else:
			QMessageBox.critical(self.yiswiz, "Yoper Configuration","Root passwords should match.Please retype",QMessageBox.Ok)

		
	def onConfigBootloader(self):
		
		boot_time=str(self.yiswiz.leditTimeToWait.text())
		if boot_time=="":
			boot_time="5"
		
		cmb_current_item=self.yiswiz.cmbChooseOS.currentItem()
			
		#write into /var/tmp/HD_choice for lilo config		
		print "Boot Device : " + str(self.mbr_device)
		os.popen("/bin/touch /var/tmp/HD_choice")
		root_partition_choice=open('/var/tmp/HD_choice', 'w')
		root_partition_choice.write(str(self.mbr_device))
				
		#self.yiswiz.setNextEnabled(self.yiswiz.page(4),1)
		self.yiswiz.leditRootPwd.setEnabled(1)
		self.yiswiz.leditRootCPwd.setEnabled(1)
	
	def modifyForGrub(self,bdevice):
		if bdevice=="hda":
			self.device="hd0"
		elif bdevice=="hdb":
			device="hd1"
		elif bdevice=="hdc":
			self.device="hd2"
		elif bdevice=="hdd":
			self.device="hd3"
	
	def onCustomizeLater(self):
		#self.yiswiz.setNextEnabled(self.yiswiz.page(4),1)
		self.yiswiz.leditRootPwd.setEnabled(1)
		self.yiswiz.leditRootCPwd.setEnabled(1)
		self.yiswiz.dont_config_bootloader=1
		self.yiswiz.btnConfigBootloader.setEnabled(0)
		self.yiswiz.cmbDevices.setEnabled(0)
		self.yiswiz.cmbChooseOS.setEnabled(0)
		self.yiswiz.leditTimeToWait.setEnabled(0)
	
	def onCustomizeNow(self):
		self.yiswiz.leditRootPwd.setEnabled(0)
		self.yiswiz.leditRootCPwd.setEnabled(0)
		self.yiswiz.dont_config_bootloader=0
		self.yiswiz.setNextEnabled(self.yiswiz.page(4),0)
		self.yiswiz.dont_config_bootloader=0
		self.yiswiz.btnConfigBootloader.setEnabled(0)
		self.yiswiz.cmbDevices.setEnabled(1)

	def onDeviceSelect(self,index):
		cmb_current_item=self.yiswiz.cmbDevices.currentItem()
		if self.yiswiz.cmbDevices.text(cmb_current_item)!="Devices":
			self.mbr_device=self.yiswiz.cmbDevices.text(cmb_current_item)
			#self.yiswiz.grub_device=str(self.mbr_device)
			self.yiswiz.cmbChooseOS.setEnabled(1)
			self.yiswiz.leditTimeToWait.setEnabled(1)
		
	
