---
layout: article
title: Install GPU driver + CUDA + cuDNN + Tensorflow on Ubuntu 18.04
key: 20191104
tags:
- Linux
- Nvidia
- ML/DL
- Tensorflow
mathjax: true
---

Installing Nvidia driver, CUDA, cuDNN, Tensorflow-gpu/Keras is not an easy task. We need to figure out how to match driver with hardware, match cuda/cudnn libraries versions(pretty complicated as known), and also need to make sure ML/DL frameworks(e.g., tensorflow) version can be compatible with the installed cuda version, etc. In this article we will introduce how to install Nvidia driver, CUDA, cuDNN, tensorflow-gpu/keras-gpu in Ubuntu 18.04 LTS. The article will cover two ways: one regular way(Method 1) and one simple, easy way(Method 2). Thanks to Anaconda, which makes our life easier!

<!--more-->

### 1. Install Ubuntu (18.04 LTS)
#### 1.1 Download Ubuntu ISO File
`https://ubuntu.com/download/desktop`
#### 1.2 Create bootable disk
- Rufus (use Rufus to create bootable disk, which can be download from [here](https://rufus.ie/).
- [Tutorials](https://tutorials.ubuntu.com/tutorial/tutorial-create-a-usb-stick-on-windows#0)

#### 1.3 Install Ubuntu system
- Tutorials:
	- [Ubuntu 18.04 LTS Desktop Installation Guide with Screenshots](https://www.linuxtechi.com/ubuntu-18-04-lts-desktop-installation-guide-screenshots/)
	- [Tutorial-install-ubuntu-desktop](https://tutorials.ubuntu.com/tutorial/tutorial-install-ubuntu-desktop#0)
- Others
  - [Disk partition on Ubuntu 18.04 (swap)](https://askubuntu.com/questions/1030231/ubuntu-18-04-lts-disk-partition-recomendations)

Note: Ubuntu 18.04 defaults to using a swap file instead of the previous method of having a dedicated swap partition. This makes it easier to partition new installations of 18.04 than it was before. 
In my case, I didn't choose swap partition like before, and swap is available using `sudo swapon --show`

~~~
$ sudo swapon --show  # swap
$ cat /proc/meminfo   # memory info
$ df -H               # disk info
$ cat /proc/cpuinfo   # cpu info
~~~


### 2. Network Configuration
#### 2.1 gateway/interface setting
- *Check network status before configration*: In Ubuntu 18.04 LTS, `net-tools` is not installed by default, which means, `ifconfig` or `route` cannot be used. Instead, we can use `ip -c a` check the `ip` information, such as port name, which port status is `up`, etc. You can also use `ping` to check the connection. In my case, before setting the gateway correctly, I cannot use internet. 

~~~
$ ifconfig 
$ ip -c a
$ ip link show
$ ping www.google.com
~~~

- *Configuration*: In Ubuntu 18.04 LTS, we use netplan to manage network setting.

~~~
$ cd /etc/netplan/
$ sudo cp 01-network-manager-all.yaml 01-network-manager-all.yaml.factory-set
$ sudo nano 01-network-manager-all.yaml
$ sudo netplan apply   # make the change effective
~~~
    
> 01-network-manager-all.yaml(before)

~~~   
# Let NetworkManager manage all devices on this system
  version: 2
  renderer: NetworkManager
~~~
   
> 01-network-manager-all.yaml(after) 

~~~   
# Let NetworkManager manage all devices on this system
network:
  ethernets:
     enp0s31f6:  # interface shown in `ip -c a`
        addresses: [your-ip-address/24] # ip address shown in `ip -c a`, use `/24` instead of mask `255.255.255.0`
        gateway4: your-gateway          # gateway
        nameservers:
           addresses: [8.8.8.8, 8.8.4.4] # DNS
  version: 2
  renderer: NetworkManager
~~~

- *Check status after configuration*: we can use `ip r` to check the route information. In the meantime, we can also install `net-tools`, so we can use familiar commands, such as `ifconfig` and `route`.

~~~
$ sudo apt-get update
$ sudo apt-get install net-tools
$ ifconfig
$ route
$ netstat -i
$ ip r
$ ping www.google.com
~~~

   
#### 2.2 enable ssh 
In Ubuntu 18.04 LTS, `openssh-server` is not installed by default. To install it:

~~~
$ sudo systemctl status ssh.service  # no ssh service 
$ sudo apt-get install openssh-server 
$ sudo systemctl status ssh.service  # activated, running
~~~
Enable firewall of ubuntu, and enable ssh rule:

~~~
$ sudo ufw status
$ sudo ufw allow ssh
$ sudo ufw enable
$ sudo ufw status
~~~

   
### 3. Install GPU driver + CUDA + cuDNN + tensorflow-gpu
#### 3.1 Install GPU driver
~~~
$ sudo lshw -c display
$ sudo ubuntu-drivers devices
$ sudo ubuntu-drivers autoinstall
$ sudo reboot (need to reboot)
~~~
Check:

~~~
$ nvidia-smi
$ sudo lshw -c display
$ lsmod | grep nvidia
$ lspci | grep -i nvidia
~~~

- CUDA Compatibility: 
You need to find compatible driver version for your nvidia graphic card, such as `CUDA 10.0 (10.0.130)	>= 410.48`.
More details can be found [CUDA Compatibility in Nvidia official docs](https://docs.nvidia.com/deploy/cuda-compatibility/index.html).

- Different CUDA versions shown by using `nvcc --version` and `nvidia-smi`: CUDA has 2 primary APIs: the runtime and the driver API. Both have a corresponding version. In my case, I installed latest 430 driver, when use `nvidia-smi`, you can CUDA version is `10.2` and I installed CUDA toolkit 10.0, CUDA version is `10.0` when use `nvcc --version`. More discussions can be found [here](https://stackoverflow.com/questions/53422407/different-cuda-versions-shown-by-nvcc-and-nvidia-smi).

After install driver, we can either use regular way to install CUDA, cuDNN or tensorflow-gpu one by one, or we can install them together while using anaconda. We will regular way first, you can skip this part, directly go to Anoconda part. 

### Method 1

#### 3.2 Install CUDA (toolkit)
~~~
$ cat /etc/lsb-release 
$ gcc --version 
~~~

Select system, architecture, distribution and version, etc. Then, [download CUDA Toolkit](https://developer.nvidia.com/cuda-downloads)

- **Install specific CUDA version as needed**

~~~
$ https://developer.nvidia.com/cuda-toolkit-archive
~~~

For example, to install `cuda_10.0.130_410.48`:

~~~
$ wget https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda_10.0.130_410.48_linux
$ sudo sh cuda_10.0.130_410.48_linux.run
~~~

check

~~~
cd /usr/local/
~~~
If everything is ok you should see a cuda folder in /usr/local/.

`sudo nano ~/.bashrc`

add at the end of the file:

~~~
export PATH=/usr/local/cuda-10.0/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-10.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
~~~
CTL+X to save and exit

`source ~/.bashrc`

**Note:** after install driver, you may meet error/warning when you try to install cuda toolkit by using local cuda runfile, showing `...already existed`. You can choose `continue`, and then skip to install cuda driver (all items ready to install labelled `+` by default, unselect driver parts `+`).

- **Install default(latest) version** (updated till 11/05/2019)

If you choose to use default lateset version, you can either choose runfile (local) or deb (network)

> runfile (local) Installation Instructions:

~~~
$ wget http://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.243_418.87.00_linux.run
$ sudo sh cuda_10.1.243_418.87.00_linux.run 
~~~

`sudo nano ~/.bashrc`

add at the end of the file:

~~~
export PATH=/usr/local/cuda-10.1/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-10.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
~~~

`CTL+X` to save and exit

`source ~/.bashrc`


> deb (network) Installation Instructions:

~~~
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
sudo add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /"
sudo apt-get update
sudo apt-get -y install cuda
~~~

#### 3.3 Install cuDNN
1. Register at nvidia developers, download [cuDNN](https://developer.nvidia.com/cudnn). Download 10.0 runtime & developer library for 18.04 (Files cuDNN7.6.x Runtime Library for Ubuntu18.04 (Deb) & cuDNN v7.6.x Developer Library for Ubuntu18.04 (Deb)).

2. Open the files with software manager and install them. 

3. Check:

~~~
$ cat /usr/include/x86_64-linux-gnu/cudnn_v*.h | grep CUDNN_MAJOR -A 2
$ whereis cudnn.h
$ nvcc --version
~~~

#### 3.4 install tensorflow-gpu / keras-gpu
~~~
sudo apt-get install libcupti-dev
pip3 install tensorflow-gpu  
~~~

### Method 2
#### 3.5 Install CUDA toolkit/cuDNN/tensorflow-gpu using Anaconda

- Install Anaconda:

~~~
$ cd Downloads/
$ sudo apt install curl (if curl was not installed)
$ curl -O https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh
$ ls
$ sha256sum Anaconda3-2019.10-Linux-x86_64.sh 
$ bash Anaconda3-2019.10-Linux-x86_64.sh
$ source ~/.bashrc (you may meet 'conda: command not found')
~~~

- Install CUDA, cuDNN, tensorflow-gpu and keras
 
Create conda env as needed and test gpu works or not.
Note latest python3 is python 3.8 and comes with tensorflow 2.0, many 1.x codes cannot run, need to use compatible setting. In this case, we will use 1.x tensorflow and keras. 

~~~
$ conda create --name tf-gpu
$ conda activate tf-gpu
$ conda install -c anaconda tensorflow-gpu  (tf default version: 2.0)
or:
$ conda install -c anaconda tensorflow-gpu==1.14 (if choose tf version 1.14)
$ conda install keras
$ python test-gpu.py 
$ python test-keras.py
$ conda deactivate
~~~

> Example: test-gpu.py (using tensorflow)

~~~
# Creates a graph.
#import tensorflow as tf
import tensorflow.compat.v1 as tf
tf.disable_v2_behavior()
c = []
for d in ['/device:GPU:0']:
  with tf.device(d):
    a = tf.constant([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], shape=[2, 3])
    b = tf.constant([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], shape=[3, 2])
    c.append(tf.matmul(a, b))
with tf.device('/cpu:0'):
  sum = tf.add_n(c)
# Creates a session with log_device_placement set to True.
sess = tf.Session(config=tf.ConfigProto(log_device_placement=True))
# Runs the op.
print(sess.run(sum))
~~~

> Example: test-keras.py

~~~
from keras import backend as K
print(K.tensorflow_backend._get_available_gpus())
~~~

We can also use `keras-gpu` to install tensorflow-gpu and keras together. The tensorflow version is 2.0 and keras version is 2.2.4 (updated till 11/05/2019) 

~~~
$ conda create --name keras-gpu
$ conda activate keras-gpu
$ conda install -c anaconda keras-gpu 
~~~


##### [References]

> Install Nvidia Driver

- [2 Ways to Install Nvidia Driver on Ubuntu 18.04 (GUI & Command Line)](https://www.linuxbabe.com/ubuntu/install-nvidia-driver-ubuntu-18-04)
- [How to install NVIDIA drivers on Ubuntu 18.04 LTS Bionic Beaver Linux](https://www.mvps.net/docs/install-nvidia-drivers-ubuntu-18-04-lts-bionic-beaver-linux/)
- [NVIDIA CUDA Installation Guide for Linux](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html)

> Install CUDA, cuDNN

- [The easy way: Install Nvidia drivers, CUDA, CUDNN and Tensorflow GPU on Ubuntu 18.04](https://askubuntu.com/questions/1033489/the-easy-way-install-nvidia-drivers-cuda-cudnn-and-tensorflow-gpu-on-ubuntu-1)
- [Ubuntu-18.04 Install Nvidia driver and CUDA and CUDNN and build Tensorflow for gpu](https://github.com/nathtest/Tutorial-Ubuntu-18.04-Install-Nvidia-driver-and-CUDA-and-CUDNN-and-build-Tensorflow-for-gpu/blob/master/README.md)
- [How to verify CuDNN installation?](https://stackoverflow.com/questions/31326015/how-to-verify-cudnn-installation)

> Method 2: using Anoconda 

- [How To Install Anaconda on Ubuntu 18.04 [Quickstart]](https://www.digitalocean.com/community/tutorials/how-to-install-anaconda-on-ubuntu-18-04-quickstart)
- [Compatibility with Cuda 10.1?](https://github.com/tensorflow/tensorflow/issues/26289#issuecomment-515494697)
- [TensorFlow 1.14.0 is not using GPU](https://stackoverflow.com/questions/56786677/tensorflow-1-14-0-is-not-using-gpu)
- [TF versions vs. required CUDA versions table](https://www.tensorflow.org/install/source#linux).
- [TF for cuda_10.0 for ubuntu 18.04](https://www.tensorflow.org/install/gpu#ubuntu_1804_cuda_10)
- [how-to-install-keras-with-gpu-support](https://stackoverflow.com/questions/54689096/how-to-install-keras-with-gpu-support)
- [Anaconda: keras-gpu](https://anaconda.org/anaconda/keras-gpu)

> Check GPU works:

- [Use a GPU\-TensorFlow](https://www.tensorflow.org/guide/gpu)
- [check gpu works](https://stackoverflow.com/questions/53221523/how-to-check-if-tensorflow-is-using-all-available-gpus)
- [To get TF 1.x like behaviour in TF 2.0 one can run](https://stackoverflow.com/questions/55142951/tensorflow-2-0-attributeerror-module-tensorflow-has-no-attribute-session)

> Network configuration:

- [Quick Tip: Enable Secure Shell (SSH) Service in Ubuntu 18.04](http://tipsonubuntu.com/2018/05/31/enable-secure-shell-ssh-service-ubuntu-18-04/)
- [Gateway setting for previous ubuntu version](https://www.cyberciti.biz/faq/howto-debian-ubutnu-set-default-gateway-ipaddress/)
     
> Others:

- [use linux screen: keep session available](https://linuxize.com/post/how-to-use-linux-screen/)
- [systemback: restore system](https://vitux.com/how-to-restore-your-ubuntu-linux-system-to-its-previous-state/)
     
  


 


