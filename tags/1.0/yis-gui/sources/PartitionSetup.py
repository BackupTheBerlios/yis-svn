#The PartitionSetup Python file
#Deals with the PartitionSetup Screen
#It takes the QWizard object (qwizard) from YoperInstaller as the object in the 
#constructor, which allows us to access our Installer GUI.
#Modifications can be done here pertaining to PartitionSetup screen only

#Author - Chaks
#email  - chaks.yoper@gmail.com

from qt import *
from Devices import *
from Variables import *
import os.path
import popen2
import time

class PartitionSetup:
	def __init__(self,qwizard):
		self.yiswiz=qwizard
		self.proc_qtparted=QProcess("/usr/sbin/qtparted")
		self.setDefaultValues()
		self.connectSignals()

	def setDefaultValues(self):
		self.fillDevicesCombo()
		self.yiswiz.setNextEnabled(self.yiswiz.page(3),0)

	def connectSignals(self):
		self.yiswiz.connect(self.yiswiz.btnStartQtParted,SIGNAL("clicked()"),self.onStartQtParted)
		self.yiswiz.connect(self.yiswiz.cmbRoot,SIGNAL("activated(int)"),self.onRootActivated)
		self.yiswiz.connect(self.yiswiz.cmbHome,SIGNAL("activated(int)"),self.onHomeActivated)
		self.yiswiz.connect(self.yiswiz.cmbBoot,SIGNAL("activated(int)"),self.onBootActivated)
		self.yiswiz.connect(self.yiswiz.cmbSwap,SIGNAL("activated(int)"),self.onSwapActivated)
		self.yiswiz.connect(self.proc_qtparted,SIGNAL("processExited()"),self.onQtPartedExit)
		self.yiswiz.connect(self.yiswiz.chkFormatHome,SIGNAL("clicked()"),self.onCheckHome)
		self.yiswiz.connect(self.yiswiz.chkFormatBoot,SIGNAL("clicked()"),self.onCheckBoot)
		self.yiswiz.connect(self.yiswiz.btnDefaults,SIGNAL("clicked()"),self.onDefaults)
		self.yiswiz.connect(self.yiswiz.btnCreate,SIGNAL("clicked()"),self.onCreatePartitions)
	
	def lateSignals(self,type):
		if type=="mount":
			self.yiswiz.connect(self.proc_mount,SIGNAL("processExited()"),self.onMountExit)
			
	def onCheckHome(self):
		if self.yiswiz.chkFormatHome.isChecked() == True:
			self.yiswiz.cmbHomeType.setEnabled(1)
		else:
			self.yiswiz.cmbHomeType.setEnabled(0)
			
	def onCheckBoot(self):
		if self.yiswiz.chkFormatBoot.isChecked() == True:
			self.yiswiz.cmbBootType.setEnabled(1)
		else:
			self.yiswiz.cmbBootType.setEnabled(0)
			
	def forRootPartition(self):
		cmb_current_item=self.yiswiz.cmbRoot.currentItem()
		cmb_current_text=self.yiswiz.cmbRoot.text(cmb_current_item)
		print "Root"
		print cmb_current_text
		if self.yiswiz.cmbRoot.text(cmb_current_item)!="Devices":
			#QMessageBox.about(self.yiswiz,"YIS",self.yiswiz.cmbRoot.text(cmb_current_item))	
			self.INST_ROOT_DEV=self.yiswiz.cmbRoot.text(cmb_current_item)
			#extract /dev/hdxx from the whole combo selection
			self.INST_ROOT_DEV=self.INST_ROOT_DEV[0:9]
			root_part=str(self.INST_ROOT_DEV)
			#extract only hdxx from /dev/hdxx
			root_part=root_part[5:9]
			self.yiswiz.root_device=root_part
			
			#write this root_device for lilo config in /var/tmp/root_partition_choice
			os.popen("/bin/touch /var/tmp/root_partition_choice")
			root_partition_choice=open('/var/tmp/root_partition_choice', 'w')
			root_partition_choice.write(self.yiswiz.root_device)
			
			self.INST_ROOT_DEV_FORMAT="yes"
			cmb_current_item=self.yiswiz.cmbRootType.currentItem()
			self.INST_ROOT_FS=self.yiswiz.cmbRootType.text(cmb_current_item)
				
	def forHomePartition(self):
		cmb_current_item=self.yiswiz.cmbHome.currentItem()
		cmb_current_text=self.yiswiz.cmbHome.text(cmb_current_item)
		print "Home"
		print cmb_current_text
		if self.yiswiz.cmbHome.text(cmb_current_item)!="Devices":
			#QMessageBox.about(self.yiswiz,"YIS",self.yiswiz.cmbHome.text(cmb_current_item))	
			self.INST_HOME_DEV=self.yiswiz.cmbHome.text(cmb_current_item)
			self.INST_HOME_DEV=self.INST_HOME_DEV[0:9]
			if self.yiswiz.chkFormatHome.isChecked()==1:
				self.INST_HOME_DEV_FORMAT="yes"
			else:
				self.INST_HOME_DEV_FORMAT="no"
			cmb_current_item=self.yiswiz.cmbHomeType.currentItem()
			self.INST_HOME_FS=self.yiswiz.cmbHomeType.text(cmb_current_item)
		else:
			self.INST_HOME_DEV="none"
			self.INST_HOME_DEV_FORMAT="none"
			self.INST_HOME_FS="none"
					
	
	def forBootPartition(self):
		cmb_current_item=self.yiswiz.cmbBoot.currentItem()
		cmb_current_text=self.yiswiz.cmbBoot.text(cmb_current_item)
		print "Boot"
		print cmb_current_text
		if self.yiswiz.cmbBoot.text(cmb_current_item)!="Devices":	
			#QMessageBox.about(self.yiswiz,"YIS",self.yiswiz.cmbBoot.text(cmb_current_item))		
			self.INST_BOOT_DEV=self.yiswiz.cmbBoot.text(cmb_current_item)
			self.INST_BOOT_DEV=self.INST_BOOT_DEV[0:9]
			if self.yiswiz.chkFormatBoot.isChecked()==1:
				self.INST_BOOT_DEV_FORMAT="yes"
			else:
				self.INST_BOOT_DEV_FORMAT="no"
			cmb_current_item=self.yiswiz.cmbBootType.currentItem()
			self.INST_BOOT_FS=self.yiswiz.cmbBootType.text(cmb_current_item)
			self.yiswiz.boot_device=str(self.INST_BOOT_DEV)
		else:
			self.INST_BOOT_DEV="none"
			self.INST_BOOT_DEV_FORMAT="none"
			self.INST_BOOT_FS="none"
			self.yiswiz.boot_device="none"
					
	
	def forSwapPartition(self):
		cmb_current_item=self.yiswiz.cmbSwap.currentItem()
		cmb_current_text=self.yiswiz.cmbSwap.text(cmb_current_item)
		print "Swap"
		print cmb_current_text
		if self.yiswiz.cmbSwap.text(cmb_current_item)!="Devices":
			#QMessageBox.about(self.yiswiz,"YIS",self.yiswiz.cmbSwap.text(cmb_current_item))	
			self.INST_SWAP_DEV=cmb_current_text
			self.INST_SWAP_DEV_FORMAT="yes"
		else:
			self.INST_SWAP_DEV="none"
			self.INST_SWAP_DEV_FORMAT="none"
	
	def startCreatingPartitions(self):
		cmb_current_item=self.yiswiz.cmbRoot.currentItem()
		if self.yiswiz.cmbRoot.text(cmb_current_item)!="Devices":
			result=QMessageBox.question(self.yiswiz, "Partition Setup","Apply Partition Changes ?",QMessageBox.Yes,QMessageBox.No)
			if result==QMessageBox.Yes:
				self.yiswiz.btnCreate.setEnabled(0)
				self.createRootPartition()
				if self.INST_SWAP_DEV != "none":
					self.yiswiz.setNextEnabled(self.yiswiz.page(3),0)
					self.createSwapPartition()
				if self.INST_HOME_DEV != "none":
					self.yiswiz.setNextEnabled(self.yiswiz.page(3),0)
					self.createHomePartition()
				if self.INST_BOOT_DEV != "none":
					self.yiswiz.setNextEnabled(self.yiswiz.page(3),0)
					self.createBootPartition()
				self.createFstab()
			else:
				self.yiswiz.btnCreate.setEnabled(1)
				self.yiswiz.cmbRoot.setEnabled(1)
		
	def onCreatePartitions(self):
		#create directories required for partition setup
		os.popen("/bin/rm -rf /ramdisk/YIS")
		os.popen("/bin/mkdir -p " + TGT_ROOT)
		os.popen("/bin/mkdir -p " + TGT_HOME)
		os.popen("/bin/mkdir -p " + TGT_BOOT)
		
		self.yiswiz.btnCreate.setEnabled(0)

		os.popen("/bin/mkdir -p /ramdisk/YIS/settings")
		os.popen("/bin/touch /ramdisk/YIS/settings/partition")
		
		#for Root Partition
		self.forRootPartition()
		
		#for Home Partition
		self.forHomePartition()
			
		#for Boot Partition
		self.forBootPartition()
			
		#for Swap Partition
		self.forSwapPartition()
		
		#actual process
		self.startCreatingPartitions()

	def createFstab(self):
		os.popen("/bin/mkdir -p /ramdisk/YIS/settings/etc")
		os.popen("/bin/cp -f /KNOPPIX/etc/fstab /ramdisk/YIS/settings/etc")
		
		file_fstab=open("/ramdisk/YIS/settings/etc/fstab",'a')
		
		#for root partition
		file_fstab.writelines(str(self.INST_ROOT_DEV))
		file_fstab.writelines("\t")
		file_fstab.writelines("/")
		file_fstab.writelines("\t")
		file_fstab.writelines(str(self.INST_ROOT_FS))
		file_fstab.writelines("\t")
		file_fstab.writelines("defaults")
		file_fstab.writelines("\t")
		file_fstab.writelines("1 1 #yoper-root")
		file_fstab.writelines("\n")
		
		#for swap partition
		if self.INST_SWAP_DEV != "none":
			file_fstab.writelines(str(self.INST_SWAP_DEV))
			file_fstab.writelines("\t")
			file_fstab.writelines("swap")
			file_fstab.writelines("\t")
			file_fstab.writelines("swap")
			file_fstab.writelines("\t")
			file_fstab.writelines("pri=1")
			file_fstab.writelines("\t")
			file_fstab.writelines("0 0")
			file_fstab.writelines("\n")
			
		#for home partition
		if self.INST_HOME_DEV != "none":
			file_fstab.writelines(str(self.INST_HOME_DEV))
			file_fstab.writelines("\t")
			file_fstab.writelines("/home")
			file_fstab.writelines("\t")
			file_fstab.writelines(str(self.INST_HOME_FS))
			file_fstab.writelines("\t")
			file_fstab.writelines("defaults")
			file_fstab.writelines("\t")
			file_fstab.writelines("0 0")
			file_fstab.writelines("\n")
			
		#for boot partition
		if self.INST_BOOT_DEV != "none":
			file_fstab.writelines(str(self.INST_BOOT_DEV))
			file_fstab.writelines("\t")
			file_fstab.writelines("/boot")
			file_fstab.writelines("\t")
			file_fstab.writelines(str(self.INST_BOOT_FS))
			file_fstab.writelines("\t")
			file_fstab.writelines("defaults")
			file_fstab.writelines("\t")
			file_fstab.writelines("0 0")
			file_fstab.writelines("\n")
		
		file_fstab.close()
		
	def mountPartition(self,INST_DEV,TGT_DIR,type):
		self.yiswiz.setNextEnabled(self.yiswiz.page(3),0)
		self.yiswiz.app_object.processEvents()
		proc_format=popen2.Popen3("/var/yis/common/partitioning.sh " + "Mount " + "none" + " " + str(INST_DEV) + " " + type,True)
		while proc_format.poll()==-1:
			pass
		
		self.yiswiz.setNextEnabled(self.yiswiz.page(3),1)
		self.yiswiz.lblDispFormat.setText(type + " Partition Created")
		self.yiswiz.app_object.processEvents()
				
			
	def createRootPartition(self):
		#print "yes" + " " + "Root"
		self.yiswiz.lblDispFormat.setText("Creating Root Partition...")
		self.yiswiz.app_object.processEvents()				
		self.formatDrive(self.INST_ROOT_FS,self.INST_ROOT_DEV,"Root")
	
	def createSwapPartition(self):
		self.yiswiz.lblDispFormat.setText("Creating Swap Partition...")
		self.yiswiz.app_object.processEvents()				
		self.formatDrive("swap",self.INST_SWAP_DEV,"Swap")
			
	def createHomePartition(self):
		self.yiswiz.lblDispFormat.setText("Creating Home Partition...")
		self.yiswiz.app_object.processEvents()	
		#print self.INST_HOME_DEV_FORMAT + " " + "Home"
		if self.INST_HOME_DEV_FORMAT=="yes":
			self.formatDrive(self.INST_HOME_FS,self.INST_HOME_DEV,"Home")
		else:
			#print "No format - Home"
			self.mountPartition(self.INST_HOME_DEV,TGT_HOME,"Home")
			
	def createBootPartition(self):
		self.yiswiz.lblDispFormat.setText("Creating Boot Partition...")
		self.yiswiz.app_object.processEvents()	
		#print self.INST_HOME_DEV_FORMAT + " " + "Boot"			
		if self.INST_BOOT_DEV_FORMAT=="yes":
			self.formatDrive(self.INST_BOOT_FS,self.INST_BOOT_DEV,"Boot")
		else:
			#print "No format - Boot"
			self.mountPartition(self.INST_BOOT_DEV,TGT_BOOT,"Boot")
	
	def formatDrive(self,INST_FS,INST_DEV,type):
		#print "Type = " + type + "Device = " + str(INST_DEV)
		self.yiswiz.setNextEnabled(self.yiswiz.page(3),0)
		self.yiswiz.app_object.processEvents()
		proc_format=popen2.Popen3("/var/yis/common/partitioning.sh " + "Format " + str(INST_FS) + " " + str(INST_DEV) + " " + type,True)
		while proc_format.poll()==-1:
			pass
		
		self.yiswiz.setNextEnabled(self.yiswiz.page(3),1)
		self.yiswiz.lblDispFormat.setText(type + " Partition Created")
		self.yiswiz.app_object.processEvents()
				
	def onRootActivated(self):
		if len(self.disk_type_keys) < 1:
			QMessageBox.about(self.yiswiz, "Partition Setup","You dont have enough partitions, Please run QtParted")
			self.yiswiz.cmbRoot.setCurrentItem(0)
		else:
			cmb_current_item=self.yiswiz.cmbRoot.currentItem()
			if self.yiswiz.cmbRoot.text(cmb_current_item)!="Devices":
				self.yiswiz.cmbRoot.setEnabled(0)
				self.yiswiz.cmbRootType.setEnabled(1)
				self.yiswiz.btnCreate.setEnabled(1)
				self.yiswiz.cmbSwap.setEnabled(1)
				if len(self.disk_type_keys) > 2:
					self.yiswiz.cmbHome.setEnabled(1)
					self.yiswiz.cmbBoot.setEnabled(1)
					self.yiswiz.cmbHome.removeItem(cmb_current_item)
					self.yiswiz.cmbBoot.removeItem(cmb_current_item)
	
	def onHomeActivated(self):
		cmb_current_item=self.yiswiz.cmbHome.currentItem()
		self.yiswiz.chkFormatHome.setEnabled(1)
		self.yiswiz.cmbHomeType.setEnabled(1)
		if self.yiswiz.cmbHome.text(cmb_current_item)!="Devices":
			self.yiswiz.cmbHome.setEnabled(0)
			self.yiswiz.cmbBoot.removeItem(cmb_current_item)
	
	def onBootActivated(self):
		cmb_current_item=self.yiswiz.cmbBoot.currentItem()
		if self.yiswiz.cmbBoot.text(cmb_current_item)!="Devices":
			self.yiswiz.cmbBoot.setEnabled(0)
			self.yiswiz.chkFormatBoot.setEnabled(1)
			self.yiswiz.cmbBootType.setEnabled(1)
			
	def onSwapActivated(self):
		cmb_current_item=self.yiswiz.cmbSwap.currentItem()
		if self.yiswiz.cmbSwap.text(cmb_current_item)!="Devices":
			self.yiswiz.cmbSwap.setEnabled(0)
			
	def onDefaults(self):
		self.fillDevicesCombo()
		
		#do for Root Partition Items
		self.yiswiz.cmbRoot.setEnabled(1)
		self.yiswiz.chkFormatRoot.setChecked(1)
		self.yiswiz.chkFormatRoot.setEnabled(0)
		self.yiswiz.cmbRootType.setEnabled(0)
		self.yiswiz.cmbRootType.setCurrentItem(0)
		
		#do for Home Partition Items
		self.yiswiz.cmbHome.setEnabled(0)
		self.yiswiz.chkFormatHome.setChecked(1)
		self.yiswiz.chkFormatHome.setEnabled(0)
		self.yiswiz.cmbHomeType.setEnabled(0)
		self.yiswiz.cmbHomeType.setCurrentItem(0)
		
		#do for Boot Partition Items
		self.yiswiz.cmbBoot.setEnabled(0)
		self.yiswiz.chkFormatBoot.setChecked(1)
		self.yiswiz.chkFormatBoot.setEnabled(0)
		self.yiswiz.cmbBootType.setCurrentItem(0)
		self.yiswiz.cmbBootType.setEnabled(0)
		
		self.yiswiz.btnCreate.setEnabled(0)
		
		self.yiswiz.setNextEnabled(self.yiswiz.page(3),0)
		
	def onStartQtParted(self):
		self.proc_qtparted.start()
		self.yiswiz.btnStartQtParted.setEnabled(0)
		self.yiswiz.setNextEnabled(self.yiswiz.page(3),0)
	
	def onQtPartedExit(self):
		if self.proc_qtparted.normalExit():
			self.yiswiz.btnStartQtParted.setEnabled(1)
			self.yiswiz.setNextEnabled(self.yiswiz.page(3),1)
			self.onDefaults()
		else:
			QMessageBox(self,"QtParted","QtParted has exited with some errors.")
			
	def fillDevicesCombo(self):
		self.yiswiz.cmbRoot.clear()
		self.yiswiz.cmbHome.clear()
		self.yiswiz.cmbBoot.clear()
		self.yiswiz.cmbSwap.clear()
		
		self.yiswiz.cmbRoot.insertItem("Devices")
		self.yiswiz.cmbHome.insertItem("Devices")
		self.yiswiz.cmbBoot.insertItem("Devices")
		self.yiswiz.cmbSwap.insertItem("Devices")
		
		disk_info=Devices()
		self.disk_types=disk_info.invokeDevices("DISK-PARTITION-TYPES")
		self.disk_type_keys=self.disk_types.keys()
		
		#fill cmbRoot and leditSwap
		for keys in self.disk_type_keys:
			value=self.disk_types[keys]
			pos=string.find(value,'swap',6)
			swap_flag=0
			if pos==-1:
				self.yiswiz.cmbRoot.insertItem("/dev/"+keys+'->'+value)
			else:	
				self.yiswiz.cmbSwap.insertItem("/dev/"+keys)
				swap_flag=1
		
		if swap_flag==0:
			self.yiswiz.cmbSwap.changeItem("Devices",0)
			self.yiswiz.cmbSwap.setEnabled(0)
		
		#fill cmbHome and cmbBoot
		if len(self.disk_type_keys) > 2:
			for keys in self.disk_type_keys:
				value=self.disk_types[keys]
				pos=string.find(value,'swap',6)
				if pos==-1:
					self.yiswiz.cmbHome.insertItem("/dev/"+keys+'->'+value)
					self.yiswiz.cmbBoot.insertItem("/dev/"+keys+'->'+value)
		else:
			self.yiswiz.cmbHome.changeItem("Devices",0)
			self.yiswiz.cmbHome.setEnabled(0)
			self.yiswiz.cmbBoot.changeItem("Devices",0)
			self.yiswiz.cmbBoot.setEnabled(0)

