export GOOGLE_IDP_ID=C01501d06#DNX IDP
export GOOGLE_SP_ID=192607830114#DNX ID
export PATH_DEPLOY=.buildkite
export APP_FOLDER_NAME=web
export IMAGE_BUILDER=builder:latest

env-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

.env:
	@echo "make .env"
	cp $(PATH_DEPLOY)/.env.salesforce $(PATH_DEPLOY)/.env
	echo >> $(PATH_DEPLOY)/.env
	touch $(PATH_DEPLOY)/.env.auth
	touch $(PATH_DEPLOY)/.env.assume

install: .env
	@echo "Installing sfdx cli"
	docker-compose -f $(PATH_DEPLOY)/docker-compose.yml run --rm build "npm install"
.PHONY: install

test: .env
	@echo "Running sfdx test"
	openssl enc -nosalt -aes-256-cbc -d -in assets/server.key.enc -out assets/server.key -base64 -K $(DECRYPTION_KEY) -iv $(DECRYPTION_IV)
	docker-compose -f $(PATH_DEPLOY)/docker-compose.yml run --rm build "npm run test"
	@echo "Running snyk test"
	docker-compose -f $(PATH_DEPLOY)/docker-compose.yml run --rm snyk "snyk auth $(SNYK_TOKEN) && npm run snyk"
	@echo "Running codecov"
	docker-compose -f .buildkite/docker-compose.yml run --rm snyk "curl -Os https://uploader.codecov.io/latest/linux/codecov && chmod +x codecov && ./codecov -t $(CODECOV_TOKEN) --flag Apex"
.PHONY: test

beta: .env
	@echo "Creating and installing beta package version on scratch org"
	openssl enc -nosalt -aes-256-cbc -d -in assets/server.key.enc -out assets/server.key -base64 -K $(DECRYPTION_KEY) -iv $(DECRYPTION_IV)
	docker-compose -f $(PATH_DEPLOY)/docker-compose.yml run --rm build "npm run package"
.PHONY: beta

promote: .env
	@echo "Promoting beta package to release version"
	openssl enc -nosalt -aes-256-cbc -d -in assets/server.key.enc -out assets/server.key -base64 -K $(DECRYPTION_KEY) -iv $(DECRYPTION_IV)
	docker-compose -f $(PATH_DEPLOY)/docker-compose.yml run --rm build "npm run promote"
.PHONY: promote

deploy: .env
	@echo "Installing package"
	openssl enc -nosalt -aes-256-cbc -d -in assets/server.key.enc -out assets/server.key -base64 -K $(DECRYPTION_KEY) -iv $(DECRYPTION_IV)
	docker-compose -f $(PATH_DEPLOY)/docker-compose.yml run --rm build "npm run deploy"
.PHONY: deploy