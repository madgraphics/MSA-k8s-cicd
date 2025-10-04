# MSA 기반 Kubernetes CI/CD 서비스 메시 구축 가이드
 
## 목차

1. [개요](#개요)
2. [Part 1: 마이크로서비스 구성](#part-1-마이크로서비스-구성)
3. [Part 2: CI/CD 구성](#part-2-cicd-구성)
4. [Part 3: 서비스 메시](#part-3-서비스-메시)
5. [참고 자료](#참고-자료)

---

## 개요

본 문서는 전적으로 개인적인 테스트 목적으로 작성된 것이며, 어떠한 경우에도 소속 회사와 관련이 없음을 명확히 합니다
이 프로젝트는 Kubernetes 환경에서 MongoDB와 PostgreSQL을 사용하는 마이크로서비스 아키텍처를 구축하고, Jenkins를 활용한 CI/CD 파이프라인과 Istio 기반의 서비스 메시를 적용하는 방법을 다룹니다.

---

## Part 1: 마이크로서비스 구성

### 1.1 환경 구성

CentOS Stream 8 환경에 Docker를 설치하여 컨테이너 기반 개발 환경을 준비합니다.

### 1.2 마이크로서비스 구성

각 마이크로서비스 구성:

- **Manage Service**: 매니지 정보 관리
- **Movie Service**: 영화 정보 관리
- **User Service**: 사용자 정보 관리

각 서비스는 Docker 컨테이너로 패키징되어 Kubernetes 클러스터에 배포됩니다.

---

## Part 2: CI/CD 구성

### 2.1 Jenkins 설치 및 구성

- Jenkins 설치
- GitHub, Docker Hub 연동
- 자동화된 빌드 및 배포 환경 구성

### 2.2 Jenkins 파이프라인 구성

자동화 단계:

1. **코드 가져오기**: GitHub에서 소스 코드 가져오기
2. **Docker 이미지 생성**: 빌드된 애플리케이션을 Docker 이미지로 생성
3. **이미지 푸시**: 로컬 Docker 레지스트리에 이미지 푸시
6. **배포**: Kubernetes 클러스터에 배포

---

## Part 3: 서비스 메시

### 3.1 Istio 설치 및 구성

Istio를 설치하여 서비스 간 통신 관리, 트래픽 라우팅, 로드 밸런싱, 모니터링 제공

### 3.2 서비스 간 통신 구성

- VirtualService, DestinationRule 사용
- 서비스 간 트래픽 라우팅 및 통신 정책 설정

---

## 참고 자료

- [MSA-k8s-cicd GitHub 저장소](https://github.com/dontotl/MSA-k8s-cicd)
- [Kubernetes 공식 문서](https://kubernetes.io/ko/docs/)
- [Jenkins 공식 문서](https://www.jenkins.io/ko/doc/)
- [Docker 공식 문서](https://docs.docker.com/ko/)

---
