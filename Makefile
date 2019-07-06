DEPLOYMENT_KEY := s3-cloudformation-deployer/$(shell echo s3-cloudformation-deployer-$$RANDOM.zip)
STACK_NAME ?= s3-cloudformation-deployer

clean: 
	rm -rf build

build/python: 
	mkdir -p build/python

build/python/deployer.py: src/deployer.py build/python
	cp $< $@

build/python/requests: build/python
	pip3 install requests -t build/python

build/layer.zip: build/python/deployer.py build/python/requests
	cd build/ && zip -r layer.zip python

deploy: cloudformation/template.yml build/layer.zip
	aws --profile ${AWS_PROFILE} s3 cp build/layer.zip s3://$(DEPLOYMENT_BUCKET_NAME)/$(DEPLOYMENT_KEY)
	aws --profile ${AWS_PROFILE} cloudformation deploy --template-file cloudformation/template.yml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM --parameter-overrides DeploymentBucketName=$(DEPLOYMENT_BUCKET_NAME) DeploymentKey=$(DEPLOYMENT_KEY) LayerName=$(STACK_NAME)
	aws --profile ${AWS_PROFILE} cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs[].OutputValue --output text
