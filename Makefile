.PHONY: package deploy update clean

all:
	@echo "Specify your target from: package, deploy, update or clean"
package:
		./scripts/package.sh ./templates/stacks.yaml $(s3-bucket)
deploy:	 package
		aws cloudformation deploy \
		--template ./templates/stacks-packaged.yaml \
		--stack-name $(stack-name) \
		--parameter-overrides $(parameters)
update: 
		./scripts/update.sh $(stack-name) ./templates/stacks.yaml $(parameters) $(changes) UPDATE
clean:
		aws cloudformation  delete-stack --stack-name $(stack-name)
