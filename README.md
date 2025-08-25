# CI/CD Demo (Maven + Jenkins + SonarQube + Docker + Docker Hub)

This is a tiny Spring Boot project you can use to practice a full CI/CD flow:
- Pull code from **Git**
- Build & test with **Maven**
- Analyze code quality with **SonarQube**
- Build a container with **Docker**
- Push the image to **Docker Hub**
- (Optional) run the container

> Tools you said you know: Maven, SonarQube, Docker, Jenkins, Git — this ties them all together.

---

## 1) Prerequisites

- Docker Desktop or Docker Engine 20+
- Docker Hub account (create a repo named `ci-demo`)
- Java not required on host (Jenkins will handle builds), but installing JDK 17 locally helps if you want to run the app yourself
- Git (to push this code to your remote Git server, e.g., GitHub/GitLab)

---

## 2) Start Jenkins and SonarQube locally (via Docker Compose)

```bash
cd infra
docker compose up -d --build
```

- Jenkins UI → http://localhost:8080  (first run will show an unlock key in container logs: `docker logs jenkins`)
- SonarQube UI → http://localhost:9000  (default login: `admin` / `admin` → you will be asked to change the password)

### Create a SonarQube token
1. Login to SonarQube → **My Account** → **Security** → **Generate Token** (e.g., name `jenkins-token`). Save it.

### Configure SonarQube Webhook (for Quality Gate)
1. In SonarQube: **Administration → Configuration → Webhooks → Create**  
   **Name**: `Jenkins`  
   **URL**: `http://jenkins:8080/sonarqube-webhook/`  
   (The `jenkins` hostname works from the SonarQube container to the Jenkins container.)

---

## 3) Configure Jenkins

1. Open http://localhost:8080 and finish the setup wizard.
2. **Install suggested plugins**, then also ensure these are installed:
   - *Pipeline*, *Git*, *Docker Pipeline*, *SonarQube Scanner for Jenkins*, *JUnit*.
3. **Manage Jenkins → Tools**  
   - **JDK installations**: Add `jdk17` (Temurin 17).
   - **Maven installations**: Add `maven3` (e.g., Maven 3.9.x).
4. **Manage Jenkins → Credentials**  
   - Add **Username with password** for Docker Hub → ID: `dockerhub-creds`.
5. **Manage Jenkins → System → SonarQube servers**  
   - Add server **Name**: `MySonarQube`  
   - **Server URL**: `http://sonarqube:9000`  
   - **Server authentication token**: paste the token you created above.

---

## 4) Put this code in Git

```bash
git init
git add .
git commit -m "CI/CD demo initial commit"
# create a repo on GitHub/GitLab and set it as origin:
git remote add origin https://YOUR_GIT_REMOTE/ci-cd-demo.git
git push -u origin main
```

---

## 5) Create the Jenkins Pipeline Job

- In Jenkins: **New Item → Pipeline → (name) ci-cd-demo → OK**
- Under **Pipeline**:
  - **Definition**: *Pipeline script from SCM*
  - **SCM**: *Git*
  - **Repository URL**: your repo URL
  - **Branch**: `main`
- Save, then **Build Now**.

### What the pipeline does
1. **Checkout** code from Git
2. **Build & Unit Test** with Maven (produces JAR in `target/` and publishes JUnit reports)
3. **SonarQube Scan** (mvn `sonar:sonar`)
4. **Quality Gate** wait (aborts pipeline if gate fails)
5. **Docker Build** image `YOUR_DOCKERHUB_USERNAME/ci-demo:<build number>` and tag `latest`
6. **Docker Push** to Docker Hub using credentials `dockerhub-creds`

> Before running the job, edit the `Jenkinsfile` in this repo and set:
> `DOCKER_IMAGE = "YOUR_DOCKERHUB_USERNAME/ci-demo"`

---

## 6) Try the app locally (optional)

Build the JAR:
```bash
mvn -B -DskipTests=false clean package
```

Build the image and run it:
```bash
docker build -t ci-demo:local .
docker run -p 8080:8080 ci-demo:local
# Test it:
curl http://localhost:8080/api/hello
curl "http://localhost:8080/api/hello?name=Muni"
```

---

## 7) Troubleshooting tips

- **Jenkins can't run docker**: We run Jenkins as root in Compose and mount `/var/run/docker.sock`. If you prefer a safer setup, add the `jenkins` user to the host Docker group and avoid root.
- **Quality Gate step never finishes**: Check the SonarQube webhook URL and that Jenkins is reachable from the SonarQube container (`curl http://jenkins:8080/sonarqube-webhook/` from inside `sonarqube` container should return 200).
- **Sonar token**: In this pipeline we rely on Jenkins' SonarQube server config to expose `SONAR_AUTH_TOKEN`. Ensure you set the token there.
- **Docker Hub push denied**: Make sure the Jenkins credentials ID is exactly `dockerhub-creds` and your repo exists on Docker Hub.
- **Ports already in use**: Change the host ports in `infra/docker-compose.yml`.

---

## File map

- `pom.xml` — Maven build (Java 17, Spring Boot)
- `Jenkinsfile` — CI/CD pipeline
- `Dockerfile` — Builds a tiny runtime image for the app
- `infra/docker-compose.yml` — Spins up Jenkins + SonarQube + Postgres
- `infra/jenkins/Dockerfile` — Extends Jenkins with `git` and `docker` CLI
- `src/main/java/...` — App code (`/api/hello` endpoint)
- `src/test/java/...` — Example unit tests
