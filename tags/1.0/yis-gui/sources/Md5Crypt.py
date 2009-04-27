#The Md5Crypt Python file
#Here we talk only about the Md5Crypt Screen in our Yoper Installer
#It takes the QWizard object (qwizard) from YoperInstaller as the object in the 
#constructor, which allows us to access our Installer GUI.
#Now modifications can be done here pertaining to Md5Crypt screen only

#Author - Chaks
#Email  - chaks.yoper@gmail.com

import datetime
import crypt
import os
import random,string

class Md5Crypt:
	
	def getSalt(self,chars = string.letters + string.digits):
    		# generate a random 2-character 'salt'
    		return "$1$"+ random.choice(chars) + random.choice(chars) + "$"
	
	def updateShadow(self):
		os.popen("/bin/cp -pf /var/yis/common/shadow-non-root /ramdisk/YIS/settings/etc/shadow")
		os.popen("/bin/cp -pf /KNOPPIX/etc/passwd /ramdisk/YIS/settings/etc")
		#calculate DOC
		current_date=datetime.date.today()
		compare_date=datetime.date(1970,1,1)
		todays_date=datetime.date(current_date.year,current_date.month,current_date.day)
		date_doc=todays_date-compare_date
		
		#update the Shadow file
		#"username:passwd:last:may:must:warn:expire:disable:reserved"
		file_shadow=open("/ramdisk/YIS/settings/etc/shadow","a")
		shadow_str="root:"+self.md5_crypt_pwd+":"+str(date_doc.days)+"::::::"
		file_shadow.write(shadow_str)
		file_shadow.close()
		
	def md5CryptRoot(self,password):
		self.md5_crypt_pwd=crypt.crypt(password,self.getSalt())
		#print self.md5_crypt_pwd
		self.updateShadow()
