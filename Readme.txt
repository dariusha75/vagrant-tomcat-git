======== Automic Solution Developer's scenario implementation ==========
AUTHOR:
	Hoang Duong <hoangf.da@gmail.com>
	https://github.com/wizhub

DESCRIPTION:
	This project implement the Solution Developer's scenario. This include the following files:
	-	Vagrantfile: the vagrant configuration file to start the VM
		+   Use lucid32 as base box
		+   Forward port 8080 on guest machine to 8085 on host machine to access tomcat via http://localhost:8085/
		+   Forward port 9418 on guest machine to 8086 on host machine to access git server via git://localhost:8086/
		+   Sync folder ./delivery on host machine to /home/vagrant/delivery on guest machine for auto-commit feature
		+   Enable provision shell to bash apt-update.sh shell script
		+   Enable provision puppet to install tomcat6, git, active auto-commit, auto-deploy job
		
	-	./scripts directory: contain the scripts to install the required packages for desired environment:
		+	./scripts/apt-update.sh: shell script to update all current package (when deploy vagrant VM) and install unzip package which will be used
			in auto-commit service later
		+   ./scripts/puppet : Puppet scripts to install tomcat6, git, auto-commit and auto-deploy cron jobs.
			+	./scripts/puppet/modules: Contain 2 puppet modules:
				+	/tomcat: To install tomcat6, tomcat6-admin, tomcat6-user packages. Copy user config file tomcat-users.xml to 
							/etc/tomcat6/tomcat-users.xml then restart tomcat service to enable `root` account(pwd:`vagrant`). 
							We can use this account to manage tomcat applications via: http://localhost:8085/manager/
				+	/git:   To install git-core, git-daemon-run packages. Copy git-daemon-run config from file to /etc/service/git-daemon/run 
							then restart the git-daemon-service to enable git:// protocol. 
							Create git repository at: /home/vagrant/git/repository and initialize this repository to clone from host machine via
							git://localhost:8086/repository
			+	./scripts/puppet/manifests: Contain the default.pp manifests (which will be load when vagrant VM start) and 2 bash shell for 
				commit (commit.sh) and deploy (deploy.sh) job
				+	default.pp manifest: It will do the following tasks when vagrant VM start:
					-	Include tomcat class (to activate the tomcat module)
					-	Include git class (to activate the git module)
					-	Create auto-commit puppet cron job to bash `commit.sh` file every 3 minutes
					-	Create auto-deploy puppet cron job to bash `deploy.sh` file every 5 minutes
				+	commit.sh: Bash script to auto commit any .tar.gz or .zip archive in the ./delivery directory
				+	deploy.sh: Bash script to auto deploy any .war file which have been committed to git repository (/home/vagrant/git/repository)		
	-   ./delivery directory: synced folder to upload file to git via auto-commit job from host machine. It also contain /logs folder
		for auto-commit, auto-deploy service
		+	Copy any .tar.gz or .zip file into this directory (from either host machine or guest machine) wait about 3 mins, this file will
			be auto-committed into git server. Check out the changes in /home/vagrant/git/repository on guest machine
		+	./delivery/logs directory: contain logs file and processed and deployed folder to store all processed files for auto-commit, auto-deploy   
		*   ./delivery/logs/processed: contain several tested archive which can be use as test scenario for auto commit service.

ISSUES AND SOLUTION:
	-	For auto commit and auto deploy service:
		At the first time, I tried to use inotifywait lib to monitor the changes on each folder(/delivery and git repository). But this script doesn't be triggered for 
		network file system event. It only works fine for the some basic event (create, delete, move etc..) directly from the guest machine.		
	=>	Therefore, I decided to use puppet cron jobs for the auto-commit and auto-deploy services. 
		Auto-commit cron job will start every 3 minutes (configurable), it look up in /delivery directory to find any .tar.gz or .zip archive. Extract these archives
		to a temp dir (/home/vagrant/tmp/$TMP_COUTER) then search for the manifest.txt file. When commit the archive content according to manifest.txt instruction,
		it logs every processing steps and errors into /delivery/logs/delivery_<%Y%m%d>.txt file. Then move the processed file to /delivery/logs/processed directory.
	
	-	For auto deploy service:
		At the first time, I planned to get the auto commit result as input for the auto deploy service. It means whenever we found an .war in any manifest.txt file,
		after committing it to git repository, it will be deployed to tomcat immediately. 
		But what happen if we want to manually commit a .war file to git server????
	=>	Therefore, I decided to use another puppet cron jobs for this service. It will be start every x=5 minutes (configurable). 
		This job will get the last commits since x=5 minutes ago (configurable). For each commit, get the branch and all files which is added. Then, looking for any
		.war file, deploy this .war file into tomcat/webapps under the deploy name = [branch]-[appName]. It will overwrite the application if exist. 
		During the process, it logs every steps and errors into /delivery/logs/deployment_<%Y%m%d>.txt file. 
		Then copy these .war files to /logs/deployed/ directory to back up.
		
	-	Using shell provision apt-update.sh to update all existing package of lucid32 box is taking much time, should we use the newest box?
	-	In 2 puppet modules tomcat, git, all packages are installing from online distribution packages system. This process also take much time to 
		download these packages to guest machine. We should try to install these packages from local archive to boost the VM faster.
	-	Bash shell is very powerful for installing, auto committing or deploying services, but it's hard to debug, maintain, modularize and create reused function.
		Should we use high level language for these services (i.e. Java)
	-	Puppet cron jobs run every specific time is seems to consume much resource, but it safe for batch processing (less miss any cases than directly monitoring
		the changes of a directory). However, we should set the period to start carefully based on the scale of real system. We also try to implement puppet schedule or resource
		subscribe method for this scenario and assess all the methods in order to choose the best one. Performance tuning is also an important aspect for any auto batch processing.
		
Reference link:
	1. http://xaroumenosloukoumas.wordpress.com/2011/01/28/watching-directories-for-file-changes-with-inotifywait/
	2. http://docs.puppetlabs.com/
	3. http://git-scm.com/book/en/Git-on-the-Server-Git-Daemon
	4. http://www.rockfloat.com/blog/?month=02/1/2009