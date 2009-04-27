import os
import re
import string

class Devices:

	def __init__(self):
		self.device_disks = {}
		self.regDevs =re.compile(r'/dev/(\w{3,3})(\d)\s*(\*?)\s*\d*\s*\d*\s*(\d*\+?)\s*\d?\d?\w?\w?\s*(.*)')
		self.mkdir="mkdir -p "
		self.tmpDirName="/var/tmp/YIS"
		self.tmpFileName=self.tmpDirName+"/yis-config"
		
	def createTempDir(self):
		os.popen(self.mkdir + self.tmpDirName)
		os.popen("touch " + self.tmpFileName)
		
	def openFile(self,mode):
		self.fObject=open(tmpFileName,mode)
	
	def writeFile(self,strWrite):
		self.fObject.write(strWrite + "\n")

	def invokeDevices(self,device_flag):
		if device_flag == "DISK-NAMES":
			diskInfo=self.getDiskName()
			return diskInfo
		if device_flag == "DISK-PARTITON-NAMES":
			self.getPartitionNames()
		if device_flag == "DISK-PARTITION-TYPES":
			diskTypes=self.getPartitionTypes()
			return diskTypes

	def executefdisk(self):
		fdisk = '/sbin/fdisk'
		fdiskOutput = os.popen(fdisk + ' -l')
		return fdiskOutput
		
	def parseStorageDevice(self,fdiskOutput):
		disks_no=[]
		chk_flag=0;
		for line in fdiskOutput:
    			theseMatches = self.regDevs.findall(line)
    			if(len(theseMatches)>0):
        			thisMatch = theseMatches[0]
				#print "Start"
				#print thisMatch[0]
				#print thisMatch[1]
				#print thisMatch[2]
				#print thisMatch[4]
				#print "End"
				if chk_flag == 0:
					chk_flag=1
					disks_no.append(thisMatch[1])
					self.device_disks[thisMatch[0]]=disks_no
				else:
					if self.device_disks.has_key(thisMatch[0]) == True:
						disks_no.append(thisMatch[1])
						self.device_disks[thisMatch[0]]=disks_no
					else:
						length=len(disks_no)
						disks_no[0:length]=[]
						disks_no.append(thisMatch[1])
						self.device_disks[thisMatch[0]]=disks_no
		return self.device_disks
					
	def parsePartitionTypes(self,fdiskOutput):
		self.diskTypes={}
		for line in fdiskOutput:
    			theseMatches = self.regDevs.findall(line)
    			if(len(theseMatches)>0):
        			thisMatch = theseMatches[0]
				if string.find(thisMatch[4],'Linux')!=-1:
					disk_data=thisMatch[0]+thisMatch[1]
					self.diskTypes[disk_data]=thisMatch[4]+"->"+thisMatch[3]+" kb"
		return self.diskTypes
	
	def getDiskName(self):
		fdiskOutput=self.executefdisk()
		diskInfo=self.parseStorageDevice(fdiskOutput)
		return diskInfo.keys()
	
	def getPartitionNames(self):
		return 1
	
	def getPartitionTypes(self):
		fdiskOutput=self.executefdisk()
		diskTypes=self.parsePartitionTypes(fdiskOutput)
		return diskTypes