# setup_ansible_dev_env
Very basic setup of an Ansible development environment for Debian/Ubuntu.

The shellscript will create a python-venv, install Ansible and molecule in it
and initialize a git-repo.

Clone this repo to where you want to setup your dev-environment for Ansible
and run the shellscript:

    $ ./setup_ansible_dev_env.sh -t MyAwesomeAnsibleProject

