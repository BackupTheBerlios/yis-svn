from qt import *
from threading import *
from path import path
import os.path
import popen2

class CopyBaseSystem(Thread):
	def __init__(self,name,receiver,yiswiz):
		self.name=name
		self.receiver=receiver
		self.yiswiz=yiswiz
		apply(Thread.__init__, (self, ))
		#print "inside thread"
	
	def shell_quote(self,path):
   		return "\'".join(path.split("'"))
		
	def get_dir_size(self,path):
   		status = None
   		sig = None
   		pipe = popen2.Popen3("du -s '%s'" % self.shell_quote(path))
   		data = pipe.fromchild.read()
   		try:
       			size = data.split()[0]
   		except IndexError:
       			raise FormatError, data
   		code = pipe.wait()
   		if os.WIFEXITED(code):
       			status = os.WEXITSTATUS(code)
   		elif os.WIFSIGNALED(status):
       			sig = os.WTERMSIG(code)
   		return int(size)
		
	def run(self):
		copy_process=popen2.Popen3("/var/yis/common/copy-files.sh")
		copy_process_id=copy_process.pid
		#print copy_process_id
		self.yiswiz.lblProgressText.setText("Installing Yoper,Please wait...")
		self.yiswiz.app_object.processEvents()	
		while copy_process.poll()==-1:
			dir_size=self.get_dir_size("/ramdisk/YIS/root")
			total_size_percentage=(dir_size*100)/1888564
			#print "Dir Size " + str(dir_size) + " Total Size % " + str(total_size_percentage)
			self.yiswiz.progressYoper.setProgress(total_size_percentage)
			self.yiswiz.app_object.processEvents()
		
		if self.yiswiz.dont_config_bootloader==0:
			#install LILO
			self.yiswiz.lblProgressText.setText("Installing Bootloader,Please wait...")
			os.popen("/var/yis/common/install-lilo.sh")
		
		#copy the settings file
		proc_copy=popen2.Popen3("/var/yis/common/copy-settings.sh",True)
		while proc_copy.poll()==-1:
			pass
		
		#create the inird image
		proc_initrd=popen2.Popen3("/var/yis/common/mkinitrd.sh",True)
		while proc_initrd.poll()==-1:
			pass
		
		#install lilo
		proc_lilo=popen2.Popen3("/var/yis/common/install-lilo.sh",True)
		while proc_lilo.poll()==-1:
			pass
				
		self.yiswiz.progressYoper.setProgress(100)
		self.yiswiz.lblProgressText.setText("Install Over, Please Reboot your machine")
		
		#Enable Reboot button
		self.yiswiz.btnReboot.setEnabled(1)
		self.yiswiz.connect(self.yiswiz.btnReboot,SIGNAL("clicked()"),self.onReboot)
	
	def onReboot(self):
		#eject the media and reboot
		os.popen("/sbin/init 6")

class FinalScreen:
	def __init__(self,qwizard):
		self.yiswiz=qwizard
		self.connectSignals()
	
	def connectSignals(self):
		self.yiswiz.connect(self.yiswiz.btnInstallYoper,SIGNAL("clicked()"),self.onInstallYoper)
	
	def onInstallYoper(self):
		self.yiswiz.btnInstallYoper.setEnabled(0)
		self.threadCopy=CopyBaseSystem("CopyBase",self,self.yiswiz)
		self.threadCopy.start()
	
	def __del__(self):
		if not self.threadCopy.finished():
			self.threadCopy.wait()
