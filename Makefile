.PHONY: package deploy clean

all:
	@echo "Specify your target from: package, deploy or clean"
package:
		./scripts/package.sh ./templates/stacks.yaml $(s3-bucket)
deploy:	 package
		aws cloudformation deploy \
		--template ./templates/stacks-packaged.yaml \
		--stack-name $(stack-name) \
		--parameter-overrides $(parameters)
clean:
		aws cloudformation  delete-stack --stack-name $(stack-name)
