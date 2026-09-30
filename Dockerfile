FROM ubuntu:22.04

RUN apt-get update && apt-get install -y wget git unzip gdb

# install jdk
RUN wget https://download.oracle.com/java/22/archive/jdk-22.0.2_linux-x64_bin.tar.gz
RUN tar -xf jdk-22.0.2_linux-x64_bin.tar.gz && rm jdk-22.0.2_linux-x64_bin.tar.gz
RUN mv jdk-22.0.2 /opt/
ENV JAVA_HOME='/opt/jdk-22.0.2'
ENV PATH="$JAVA_HOME/bin:$PATH"

# install mvn
RUN wget https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.tar.gz
RUN tar -xf apache-maven-3.9.16-bin.tar.gz && rm apache-maven-3.9.16-bin.tar.gz
RUN mv apache-maven-3.9.16 /opt/
ENV M2_HOME='/opt/apache-maven-3.9.16'
ENV PATH="$M2_HOME/bin:$PATH"

RUN mkdir /home/fuzz
COPY artifacts/pdfbox.patch /home/fuzz/pdfbox.patch

# clone pdfbox repository
WORKDIR /home/fuzz
RUN wget https://archive.apache.org/dist/pdfbox/3.0.5/pdfbox-3.0.5-src.zip
RUN unzip pdfbox-3.0.5-src.zip && rm pdfbox-3.0.5-src.zip && mv pdfbox-3.0.5 pdfbox
WORKDIR /home/fuzz/pdfbox
RUN git apply /home/fuzz/pdfbox.patch

# install jazzer
RUN mkdir jazzer
WORKDIR /home/fuzz/jazzer
RUN wget https://github.com/CodeIntelligenceTesting/jazzer/releases/download/v0.24.0/jazzer-linux.tar.gz
RUN tar xf jazzer-linux.tar.gz && rm jazzer-linux.tar.gz
ENV PATH="$PATH:/home/fuzz/jazzer"

# # get log4j
RUN mkdir /home/fuzz/log4j
WORKDIR /home/fuzz/log4j
RUN wget https://archive.apache.org/dist/commons/logging/binaries/commons-logging-1.2-bin.tar.gz
RUN tar xf commons-logging-1.2-bin.tar.gz && rm commons-logging-1.2-bin.tar.gz
WORKDIR /home/fuzz

# get jacoco
RUN mkdir jacoco
WORKDIR /home/fuzz/jacoco
RUN wget https://search.maven.org/remotecontent?filepath=org/jacoco/jacoco/0.8.12/jacoco-0.8.12.zip -O jacoco.zip
RUN unzip jacoco.zip && rm jacoco.zip
WORKDIR /home/fuzz/pdfbox