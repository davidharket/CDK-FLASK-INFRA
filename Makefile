release: node_modules pipenv lint test bundle-python

lint:
	pipenv run black --line-length 120 serverless_flask
	pipenv run flake8 serverless_flask

clean:
	del /S *.pyc
	del /S __pycache__
	rd /S /Q cdk.out/
	rd /S /Q build-python/
	rd /S /Q .aws-sam/
	del requirements.txt
	del .deploy-dev-once
	rd /S /Q node_modules
	del sam-params.json
	del test/*.js
	del .pipenv
	pipenv --rm || true
	echo "Clean is finished"

.pipenv:
	pipenv sync -d
	touch "$@"

run-flask: .pipenv .deploy-dev-once
	# Reads the same environment variable that Lambda will use.
	set FLASK_APP=serverless_flask:create_app
	set JSON_CONFIG_OVERRIDE=`jq -r '."serverless-flask-dev".LambdaEnv' cdk.out/dev-stage-output.json`
	set AWS_PROFILE=serverless-flask-dev
	set FLASK_ENV=dev
	set FLASK_DEBUG=1
	pipenv run  flask run --cert adhoc -h localhost -p 5000 

update-deps: clean
	pipenv update

build-python: .pipenv
	mkdir build-python
	echo "Building in build-python/"
	pipenv requirements  > requirements.txt
	pip3 install -r requirements.txt -t build-python/
	# prune botocore and boto3 because they come with Lambda runtime
	rd /S /Q build-python/boto3
	rd /S /Q build-python/botocore
	# prune other trash
	for /d %i in (build-python\__pycache__\*) do rd /S /Q "%i"
	del /S /Q build-python\*.pyc
	del /S /Q build-python\_pytest

bundle-python: build-python
	echo "Copying local Python files"
	xcopy /E /exclude:exclude.txt serverless_flask build-python/
	echo "The Python bundle's size: %CD%\\build-python\\"

pytest:
	pipenv run pytest -x

npmtest: build-ts bundle-python
	npm run test

test: pytest npmtest

build-ts:
	npm run build

node_modules:
	npm install


deploy-dev: node_modules bundle-python
	cdk deploy -c stage=dev --outputs-file cdk.out\dev-stage-output.json
	
.deploy-dev-once: node_modules
	cdk deploy -c stage=dev --outputs-file cdk.out\dev-stage-output.json
	touch $@

deploy-staging: release
	cdk deploy -c stage=staging

deploy-prod: release
	cdk deploy -c stage=prod

synth-dev: node_modules
	cdk synth -c stage=dev

sam-params.json:
	jq -r '{Parameters: {JSON_CONFIG_OVERRIDE: ."serverless-flask-dev".LambdaEnv}}' cdk.out/dev-stage-output.json > "$@"

sam-local: .deploy-dev-once bundle-python synth-dev sam-params.json
	sam local start-api -p 5000 -t cdk.out\ServerlessFlask.template.json -n sam-params.json
	del sam-params.json

.PHONY: clean run-flask bundle-python build-ts test pytest npmtest sam-local deploy-dev deploy-staging deploy-prod release update-deps synth-dev npm-install lint