FROM nvidia/cuda:11.2.0-devel-ubuntu20.04
ENV DEBIAN_FRONTEND=noninteractive
RUN rm /etc/apt/sources.list.d/cuda.list

RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update && \
    apt-get install -q -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/*

RUN apt update 

# install minimum tools:
RUN apt install -y build-essential sudo git

RUN \
  useradd user && \
  echo "user ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
  chmod 0440 /etc/sudoers.d/user && \
  mkdir -p /home/user && \
  chown user:user /home/user && \
  chsh -s /bin/bash user

RUN echo 'root:root' | chpasswd
RUN echo 'user:user' | chpasswd

# install packages
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    dirmngr \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# setup sources.list
RUN echo "deb http://packages.ros.org/ros/ubuntu focal main" > /etc/apt/sources.list.d/ros1-latest.list

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

ENV ROS_DISTRO noetic

# install ros packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-ros-core=1.5.0-1* \
    && rm -rf /var/lib/apt/lists/*

# install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    python3-rosdep \
    python3-rosinstall \
    python3-vcstools \
    && rm -rf /var/lib/apt/lists/*

# install ros packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-ros-base=1.5.0-1* \
    && rm -rf /var/lib/apt/lists/*

RUN apt update && apt install python3-osrf-pycommon python3-catkin-tools python3-wstool -y
RUN apt update && apt install ros-noetic-jsk-tools -y
RUN apt update && apt install ros-noetic-image-transport-plugins -y

# install launch/sample_detection.launch dependencies
RUN apt update && apt install ros-noetic-jsk-pcl-ros ros-noetic-jsk-pcl-ros-utils -y

WORKDIR /home/user

USER user
CMD /bin/bash
SHELL ["/bin/bash", "-c"]

RUN sudo apt install python3-pip -y
RUN pip3 install torch==1.9.0+cu111 torchvision==0.10.0+cu111 torchaudio==0.9.0 -f https://download.pytorch.org/whl/torch_stable.html 

########################################
########### WORKSPACE BUILD ############
########################################
# Installing catkin package
RUN mkdir -p ~/detic_ws/src
COPY --chown=user . /home/user/detic_ws/src/detic_ros
RUN sudo apt install -y wget
RUN sudo rosdep init && rosdep update && sudo apt update
RUN cd ~/detic_ws/src &&\
    source /opt/ros/noetic/setup.bash &&\
    wstool init &&\
    wstool merge detic_ros/rosinstall.noetic &&\
    wstool update &&\
    rosdep install --from-paths . --ignore-src -y -r &&\
    source /opt/ros/noetic/setup.bash &&\
    rosdep install --from-paths . -i -r -y &&\
    cd ~/detic_ws/src/detic_ros && ./prepare.sh &&\
    cd ~/detic_ws && catkin init && catkin build

########################################
########### ENV VARIABLE STUFF #########
########################################
RUN touch ~/.bashrc
RUN echo "source ~/detic_ws/devel/setup.bash" >> ~/.bashrc
RUN echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc

RUN pip3 install torch==1.9.0+cu111 torchvision==0.10.0+cu111 torchaudio==0.9.0 -f https://download.pytorch.org/whl/torch_stable.html

CMD ["bash"]
