# catalog installer 사용법

## Prerequisites
  - 해당 installer는 폐쇄망 기준 가이드입니다.
  - image registry에 이미지를 push 합니다. (Prerequisites 참고)
    - https://github.com/tmax-cloud/install-catalog/tree/4.1

## Step0. catalog.config 설정
- 목적 : `catalog controller 설치 진행을 위한 catalog config 설정`
- 순서 : 
  - 환경에 맞는 config 내용을 작성합니다.
     - imageRegistry={IP}:{PORT}
       - ex : imageRegistry=192.168.6.122:5000
     - catalogVersion={catalog version}
       - ex : catalogVersion=0.3.0

## Step1. install-catalog
- 목적 : `catalog controller 설치 진행을 위한 shell script 실행`
- 순서 : 
	```bash
    sudo ./install-catalog.sh install
	```
- 비고 :
    - catalog.config, install-catalog.sh파일,ca와 yaml 디렉토리는 같은 디렉토리 내에에 있어야 합니다.

## Step2. uninstall-catalog
- 목적 : `catalog controller 제거를 위한 shell script 실행`
- 순서 : 
	```bash
    sudo ./install-catalog.sh uninstall
	```
- 비고 :
    - catalog.config, install-catalog.sh파일,ca와 yaml 디렉토리는 같은 디렉토리 내에에 있어야 합니다.